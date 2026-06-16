#!/usr/bin/env bash
#
#
#
#
# This looks at the the respective apps' DB's and conversation state files and attempts to find exactly the conversation you were in before, and restores it via
# ```bash
# agy --conversation=%s
#,
# ```bash
# copilot --resume=%s
# ```
# and
#
# ```bash
# codex resume %s
# ```
#
# And it works really realiably in my experience.
#
#
#
#  Yes, it's pretty long vibe-coded, but tbh it doesnt take a lot more time during save nor restore.
#

set -euo pipefail

state_file="${1:-}"
[ -n "$state_file" ] && [ -f "$state_file" ] || exit 0

tab=$'\t'

declare -A PANE_TTY
declare -A PANE_ID
declare -A PANE_TITLE
declare -A PANE_CWD
declare -A RESTORE_CMD
declare -A PID_FOR_TTY
declare -A KIND_FOR_TTY

normalize_tty() {
	printf '%s\n' "${1#/dev/}"
}

trim() {
	sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

load_tmux_panes() {
	while IFS=$'\t' read -r session window pane pane_id tty current title cwd; do
		local key="${session}:${window}:${pane}"
		PANE_TTY["$key"]="$(normalize_tty "$tty")"
		PANE_ID["$key"]="$pane_id"
		PANE_TITLE["$key"]="$title"
		PANE_CWD["$key"]="$cwd"
	done < <(tmux list-panes -a -F '#{session_name}'"$tab"'#{window_index}'"$tab"'#{pane_index}'"$tab"'#{pane_id}'"$tab"'#{pane_tty}'"$tab"'#{pane_current_command}'"$tab"'#{pane_title}'"$tab"'#{pane_current_path}')
}

load_ai_processes() {
	local pid tty args kind
	while read -r pid tty args; do
		case "$args" in
			*resurrect-ai-cli-save.sh*|*pgrep*|*grep*)
				continue
				;;
		esac

		kind=""
		case "$args" in
			copilot*|*/copilot*)
				kind="copilot"
				;;
			agy*|*/agy*)
				kind="agy"
				;;
			*codex*)
				kind="codex"
				;;
		esac

		if [ -n "$kind" ] && [ -n "$tty" ] && [ "$tty" != "?" ]; then
			PID_FOR_TTY["$tty"]="$pid"
			KIND_FOR_TTY["$tty"]="$kind"
		fi
	done < <(ps -eo pid=,tty=,args=)
}

cmdline_for_pid() {
	tr '\0' ' ' <"/proc/$1/cmdline" 2>/dev/null || true
}

extract_uuid() {
	grep -Eo '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -n 1
}

copilot_session_from_db() {
	local title="$1"
	local cwd="$2"
	local db="$HOME/.copilot/session-store.db"
	[ -f "$db" ] || return 1

	local generic_title=""
	case "$title" in
		""|"NB525004"|"istan")
			generic_title="yes"
			;;
	esac

	if [ -z "$generic_title" ]; then
		local session_id
		session_id="$(sqlite3 -batch -noheader -list "$db" "select id from sessions where summary = '$(printf "%s" "$title" | sed "s/'/''/g")' order by updated_at desc limit 1;" 2>/dev/null | tail -n 1)"
		if [ -n "$session_id" ]; then
			printf '%s\n' "$session_id"
			return 0
		fi
	fi

	if [ -n "$cwd" ]; then
		sqlite3 -batch -noheader -list "$db" "select id from sessions where cwd = '$(printf "%s" "$cwd" | sed "s/'/''/g")' order by updated_at desc limit 1;" 2>/dev/null | tail -n 1
	fi
}

agy_log_for_pid() {
	local pid="$1"
	for fd in 1 2; do
		local target=""
		target="$(readlink -f "/proc/$pid/fd/$fd" 2>/dev/null || true)"
		case "$target" in
			*.log)
				printf '%s\n' "$target"
				return 0
				;;
		esac
	done
	return 1
}

agy_conversation_from_log() {
	local log_file="$1"
	[ -f "$log_file" ] || return 1
	grep 'Streaming conversation ' "$log_file" 2>/dev/null | tail -n 1 | sed -E 's/.*Streaming conversation ([0-9a-f-]+).*/\1/' | head -n 1
}

candidate_phrases_from_pane() {
	local pane_id="$1"
	tmux capture-pane -p -t "$pane_id" 2>/dev/null |
		sed 's/\r//g' |
		while IFS= read -r line; do
			line="$(printf '%s\n' "$line" | trim)"
			case "$line" in
				""|*'OpenAI Codex'*|*'model:'*|*'directory:'*|*'Context '*|*'Tip: '*|'> '*|*'gpt-'*|*'Conversation interrupted'*|*'This session was recorded with model '*)
					continue
					;;
			esac
			if [ "${#line}" -ge 24 ]; then
				printf '%s\n' "$line"
			fi
		done | awk '!seen[$0]++' | head -n 12
}

codex_session_from_state() {
	local pane_id="$1"
	local cwd="$2"
	local db="$HOME/.codex/state_5.sqlite"
	[ -f "$db" ] || return 1

	mapfile -t phrases < <(candidate_phrases_from_pane "$pane_id")
	[ "${#phrases[@]}" -gt 0 ] || return 1

	local escaped_cwd
	escaped_cwd="$(printf "%s" "$cwd" | sed "s/'/''/g")"

	local best_id=""
	local best_score=0
	while IFS=$'\t' read -r thread_id title preview; do
		[ -n "$thread_id" ] || continue
		local haystack="${title}"$'\n'"${preview}"
		local score=0
		local phrase
		for phrase in "${phrases[@]}"; do
			if printf '%s\n' "$haystack" | grep -Fqi -- "$phrase"; then
				score=$((score + 1))
			fi
		done
		if [ "$score" -gt "$best_score" ]; then
			best_score="$score"
			best_id="$thread_id"
		fi
	done < <(
		sqlite3 -separator $'\t' "$db" \
			"select id, replace(replace(title, char(10), ' '), char(13), ' '), replace(replace(preview, char(10), ' '), char(13), ' ') from threads where source='cli' and cwd='${escaped_cwd}' order by updated_at desc limit 80;" \
			2>/dev/null
	)

	if [ "$best_score" -gt 0 ] && [ -n "$best_id" ]; then
		printf '%s\n' "$best_id"
		return 0
	fi
	return 1
}

infer_restore_command() {
	local key="$1"
	local tty="${PANE_TTY[$key]:-}"
	local pane_id="${PANE_ID[$key]:-}"
	local title="${PANE_TITLE[$key]:-}"
	local cwd="${PANE_CWD[$key]:-}"

	[ -n "$tty" ] || return 1

	local kind="${KIND_FOR_TTY[$tty]:-}"
	local pid="${PID_FOR_TTY[$tty]:-}"
	[ -n "$kind" ] || return 1

	if [ "$kind" = "copilot" ] && [ -n "$pid" ]; then
		local sid=""
		sid="$(copilot_session_from_db "$title" "$cwd" || true)"
		if [ -n "$sid" ]; then
			printf 'copilot --resume=%s\n' "$sid"
		else
			printf 'copilot\n'
		fi
		return 0
	fi

	if [ "$kind" = "agy" ] && [ -n "$pid" ]; then
		local log_file="" sid="" argv=""
		log_file="$(agy_log_for_pid "$pid" || true)"
		if [ -n "$log_file" ]; then
			sid="$(agy_conversation_from_log "$log_file" || true)"
		fi
		if [ -z "$sid" ]; then
			argv="$(cmdline_for_pid "$pid")"
			sid="$(printf '%s\n' "$argv" | extract_uuid || true)"
		fi
		if [ -n "$sid" ]; then
			printf 'agy --conversation=%s\n' "$sid"
		else
			printf 'agy\n'
		fi
		return 0
	fi

	if [ "$kind" = "codex" ] && [ -n "$pid" ]; then
		local sid="" argv=""
		sid="$(codex_session_from_state "$pane_id" "$cwd" || true)"
		if [ -z "$sid" ]; then
			argv="$(cmdline_for_pid "$pid")"
			case "$argv" in
				*" resume "*)
					sid="$(printf '%s\n' "$argv" | extract_uuid || true)"
					;;
			esac
		fi
		if [ -n "$sid" ]; then
			printf 'codex resume %s\n' "$sid"
		else
			printf 'codex\n'
		fi
		return 0
	fi

	return 1
}

rewrite_state_file() {
	local tmp
	tmp="$(mktemp)"
	trap 'rm -f "$tmp"' EXIT

	while IFS=$'\t' read -r line_type session_name window_number window_active window_flags pane_index pane_title dir pane_active pane_command pane_full_command; do
		if [ "$line_type" = "pane" ]; then
			local key="${session_name}:${window_number}:${pane_index}"
			if [ -n "${RESTORE_CMD[$key]:-}" ]; then
				local restore="${RESTORE_CMD[$key]}"
				local command_name="${restore%% *}"
				printf 'pane\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t:%s\n' \
					"$session_name" "$window_number" "$window_active" "$window_flags" "$pane_index" \
					"$pane_title" "$dir" "$pane_active" "$command_name" "$restore" >>"$tmp"
				continue
			fi
		fi
		printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
			"$line_type" "$session_name" "$window_number" "$window_active" "$window_flags" "$pane_index" \
			"$pane_title" "$dir" "$pane_active" "$pane_command" "$pane_full_command" >>"$tmp"
	done <"$state_file"

	mv "$tmp" "$state_file"
	trap - EXIT
}

load_tmux_panes
load_ai_processes

for key in "${!PANE_TTY[@]}"; do
	restore="$(infer_restore_command "$key" || true)"
	if [ -n "${restore:-}" ]; then
		RESTORE_CMD["$key"]="$restore"
	fi
done

rewrite_state_file
