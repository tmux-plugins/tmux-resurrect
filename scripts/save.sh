#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/spinner_helpers.sh"

# delimiters
d=$'\t'
delimiter=$'\t'

# if "quiet" script produces no output
SCRIPT_OUTPUT="$1"

grouped_sessions_format() {
	local format
	format+="#{session_grouped}"
	format+="${delimiter}"
	format+="#{session_group}"
	format+="${delimiter}"
	format+="#{session_id}"
	format+="${delimiter}"
	format+="#{session_name}"
	echo "$format"
}

pane_format() {
	local format
	format+="pane"
	format+="${delimiter}"
	format+="#{session_name}"
	format+="${delimiter}"
	format+="#{window_index}"
	format+="${delimiter}"
	format+="#{window_active}"
	format+="${delimiter}"
	format+=":#{window_flags}"
	format+="${delimiter}"
	format+="#{pane_index}"
	format+="${delimiter}"
	format+="#{pane_title}"
	format+="${delimiter}"
	format+=":#{pane_current_path}"
	format+="${delimiter}"
	format+="#{pane_active}"
	format+="${delimiter}"
	format+="#{pane_current_command}"
	format+="${delimiter}"
	format+="#{pane_pid}"
	format+="${delimiter}"
	format+="#{history_size}"
	echo "$format"
}

window_format() {
	local format
	format+="window"
	format+="${delimiter}"
	format+="#{session_name}"
	format+="${delimiter}"
	format+="#{window_index}"
	format+="${delimiter}"
	format+=":#{window_name}"
	format+="${delimiter}"
	format+="#{window_active}"
	format+="${delimiter}"
	format+=":#{window_flags}"
	format+="${delimiter}"
	format+="#{window_layout}"
	echo "$format"
}

state_format() {
	local format
	format+="state"
	format+="${delimiter}"
	format+="#{client_session}"
	format+="${delimiter}"
	format+="#{client_last_session}"
	echo "$format"
}

dump_panes_raw() {
	tmux list-panes -a -F "$(pane_format)"
}

# window_id is appended, it's used to query window options
dump_windows_raw(){
	tmux list-windows -a -F "$(window_format)${delimiter}#{window_id}"
}

pane_contents_format() {
	local format
	format+="pane"
	format+="${delimiter}"
	format+="#{session_name}"
	format+="${delimiter}"
	format+="#{window_index}"
	format+="${delimiter}"
	format+="#{pane_index}"
	format+="${delimiter}"
	format+="#{history_size}"
	format+="${delimiter}"
	format+="#{cursor_y}"
	format+="${delimiter}"
	format+="#{pane_id}"
	echo "$format"
}

# drops pane or window lines of grouped sessions, the session name is
# expected in the 2nd field
skip_grouped_sessions() {
	awk -F "$delimiter" 'index(ENVIRON["GROUPED_SESSIONS"], FS $2 FS) == 0'
}

toggle_window_zoom() {
	local target="$1"
	tmux resize-pane -Z -t "$target"
}

_save_command_strategy_file() {
	local save_command_strategy="$(get_tmux_option "$save_command_strategy_option" "$default_save_command_strategy")"
	local strategy_file="$CURRENT_DIR/../save_command_strategies/${save_command_strategy}.sh"
	local default_strategy_file="$CURRENT_DIR/../save_command_strategies/${default_save_command_strategy}.sh"
	if [ -e "$strategy_file" ]; then # strategy file exists?
		echo "$strategy_file"
	else
		echo "$default_strategy_file"
	fi
}

# Reads pane pids from stdin and prints ":<full command>" for each of them, in
# the same order.
pane_full_commands() {
	local strategy_file="$(_save_command_strategy_file)"
	if [ "$strategy_file" == "$CURRENT_DIR/../save_command_strategies/ps.sh" ]; then
		# Same as the 'ps' strategy script, but the process list is read once
		# instead of once per pane.
		awk '
			FILENAME == ARGV[1] {
				sub(/^ */, "")
				i = index($0, " ")
				if (i > 0) {
					ppid = substr($0, 1, i - 1)
					if (!(ppid in command)) {
						command[ppid] = substr($0, i + 1)
					}
				}
				next
			}
			{ print ":" command[$0] }
		' <(ps -ao "ppid,args") -
	else
		local pane_pid full_command
		while read pane_pid; do
			full_command="$($strategy_file "$pane_pid")"
			# keep only the first line, more would break the save file
			echo ":${full_command%%$'\n'*}"
		done
	fi
}

number_nonempty_lines_on_screen() {
	local pane_id="$1"
	tmux capture-pane -pJ -t "$pane_id" |
		sed '/^$/d' |
		wc -l |
		sed 's/ //g'
}

# Prints the number of non-empty lines on screen for each of the given panes,
# in the same order. Uses a single tmux command.
number_nonempty_lines_on_screens() {
	local marker="resurrect-pane-${RANDOM}${RANDOM}-$$"
	local pane_id count
	local n=0
	for pane_id in "$@"; do
		tmux_batch_add display-message -p "$marker"
		tmux_batch_add capture-pane -pJ -t "$pane_id"
	done
	while read count; do
		echo "$count"
		n=$((n + 1))
	done < <(
		tmux "${TMUX_BATCH_ARGS[@]}" 2>/dev/null |
			awk -v marker="$marker" '
				$0 == marker { if (n++) print count; count = 0; next }
				$0 != "" { count++ }
				END { if (n) print count }
			'
	)
	_tmux_batch_reset
	# a pane was closed midway (tmux stops a command sequence on error),
	# check the remaining panes one by one
	for pane_id in "${@:$((n + 1))}"; do
		number_nonempty_lines_on_screen "$pane_id"
	done
}

capture_pane_contents() {
	local pane_id="$1"
	local start_line="$2"
	local file="$3"
	# the printf hack below removes *trailing* empty lines
	printf '%s\n' "$(tmux capture-pane -epJ -S "$start_line" -t "$pane_id")" > "$file"
}

# Captures the contents of many panes with a single tmux command.
# Arguments are "pane_id start_line file" triplets.
capture_panes_contents() {
	local marker="resurrect-pane-${RANDOM}${RANDOM}-$$"
	local -a files=()
	local i
	for ((i = 1; i <= $#; i += 3)); do
		tmux_batch_add display-message -p "$marker"
		tmux_batch_add capture-pane -epJ -S "${@:$((i + 1)):1}" -t "${@:$i:1}"
		files+=("${@:$((i + 2)):1}")
	done
	# Splits the output on markers and drops trailing empty lines, like
	# `capture_pane_contents` does. Prints the number of markers seen.
	local captured="$(
		tmux "${TMUX_BATCH_ARGS[@]}" 2>/dev/null |
			awk -v marker="$marker" '
				function finish() {
					if (n > 0) {
						if (!written) printf "\n" > file
						close(file)
					}
				}
				FILENAME == ARGV[1] { files[++nfiles] = $0; next }
				$0 == marker {
					finish()
					file = files[++n]; written = 0; empty = 0
					printf "" > file
					next
				}
				n == 0 { next }
				$0 == "" { empty++; next }
				{
					for (; empty > 0; empty--) print "" > file
					print > file
					written = 1
				}
				END { finish(); print n + 0 }
			' <(printf '%s\n' "${files[@]}") -
	)"
	_tmux_batch_reset
	# a pane was closed midway (tmux stops a command sequence on error),
	# capture the remaining panes one by one
	for ((i = captured; i < ${#files[@]}; i++)); do
		capture_pane_contents "${@:$((i * 3 + 1)):3}"
	done
}

get_active_window_index() {
	local session_name="$1"
	tmux list-windows -t "$session_name" -F "#{window_flags} #{window_index}" |
		awk '$1 ~ /\*/ { print $2; }'
}

get_alternate_window_index() {
	local session_name="$1"
	tmux list-windows -t "$session_name" -F "#{window_flags} #{window_index}" |
		awk '$1 ~ /-/ { print $2; }'
}

dump_grouped_sessions() {
	local current_session_group=""
	local original_session
	tmux list-sessions -F "$(grouped_sessions_format)" |
		grep "^1" |
		cut -c 3- |
		sort |
		while IFS=$d read session_group session_id session_name; do
			if [ "$session_group" != "$current_session_group" ]; then
				# this session is the original/first session in the group
				original_session="$session_name"
				current_session_group="$session_group"
			else
				# this session "points" to the original session
				active_window_index="$(get_active_window_index "$session_name")"
				alternate_window_index="$(get_alternate_window_index "$session_name")"
				echo "grouped_session${d}${session_name}${d}${original_session}${d}:${alternate_window_index}${d}:${active_window_index}"
			fi
		done
}

fetch_and_dump_grouped_sessions(){
	local grouped_sessions_dump="$(dump_grouped_sessions)"
	get_grouped_sessions "$grouped_sessions_dump"
	if [ -n "$grouped_sessions_dump" ]; then
		echo "$grouped_sessions_dump"
	fi
}

# translates pane pid to process command running inside a pane
dump_panes() {
	# not saving panes from grouped sessions
	local panes="$(dump_panes_raw | skip_grouped_sessions)"
	local escaped_space='\ '
	local full_command
	[ -z "$panes" ] && return
	while IFS=$d read line_type session_name window_number window_active window_flags pane_index pane_title dir pane_active pane_command pane_pid history_size &&
		IFS= read -r full_command <&3; do
		dir="${dir/ /$escaped_space}" # escape space in directory path
		echo "${line_type}${d}${session_name}${d}${window_number}${d}${window_active}${d}${window_flags}${d}${pane_index}${d}${pane_title}${d}${dir}${d}${pane_active}${d}${pane_command}${d}${full_command}"
	done <<< "$panes" 3< <(echo "$panes" | cut -f11 -d"$d" | pane_full_commands)
}

# Reads window ids from stdin and prints the 'automatic-rename' window option
# for each of them, in the same order (":" if the option is unset).
windows_automatic_rename() {
	local -a window_ids=()
	local window_id i
	while read window_id; do
		window_ids+=("$window_id")
	done
	for ((i = 0; i < ${#window_ids[@]}; i += TMUX_BATCH_MAX_COUNT / 2)); do
		_windows_automatic_rename "${window_ids[@]:$i:$((TMUX_BATCH_MAX_COUNT / 2))}"
	done
}

_windows_automatic_rename() {
	local marker="resurrect-window"
	local -a values=()
	local window_id value
	local n=-1
	for window_id in "$@"; do
		tmux_batch_add display-message -p "$marker"
		tmux_batch_add show-window-options -vt "$window_id" automatic-rename
	done
	tmux_batch_run
	while IFS= read -r value; do
		if [ "$value" == "$marker" ]; then
			n=$((n + 1))
		elif [ "$n" -ge 0 ]; then
			values[$n]="$value"
		fi
	done <<< "$TMUX_BATCH_OUTPUT"
	if [ "$((n + 1))" -ne "$#" ]; then
		# a window was closed midway (tmux stops a command sequence on error),
		# query the windows one by one
		values=()
		for window_id in "$@"; do
			values+=("$(tmux show-window-options -vt "$window_id" automatic-rename)")
		done
	fi
	for ((n = 0; n < $#; n++)); do
		value="${values[$n]}"
		# If the option was unset, use ":" as a placeholder.
		echo "${value:-:}"
	done
}

dump_windows() {
	# not saving windows from grouped sessions
	local windows="$(dump_windows_raw | skip_grouped_sessions)"
	local automatic_rename
	[ -z "$windows" ] && return
	while IFS=$d read line_type session_name window_index window_name window_active window_flags window_layout window_id &&
		IFS= read -r automatic_rename <&3; do
		echo "${line_type}${d}${session_name}${d}${window_index}${d}${window_name}${d}${window_active}${d}${window_flags}${d}${window_layout}${d}${automatic_rename}"
	done <<< "$windows" 3< <(echo "$windows" | cut -f8 -d"$d" | windows_automatic_rename)
}

dump_state() {
	tmux display-message -p "$(state_format)"
}

dump_pane_contents() {
	local pane_contents_area="$(get_tmux_option "$pane_contents_area_option" "$default_pane_contents_area")"
	local pane_contents_dir="$(pane_contents_dir "save")"
	local -a pane_ids=() start_lines=() files=() unsure=() panes=()
	local i count
	while IFS=$d read line_type session_name window_number pane_index history_size cursor_y pane_id; do
		if [ "$history_size" -gt 0 ] || # history has any content?
			[ "$cursor_y" -gt 0 ]; then # cursor not in first line?
			panes+=("${#pane_ids[@]}")
		else
			# the more expensive check (looking at the screen) is done later
			unsure+=("${#pane_ids[@]}")
		fi
		pane_ids+=("$pane_id")
		start_lines+=("-${history_size}")
		files+=("${pane_contents_dir}/pane-${session_name}:${window_number}.${pane_index}")
	done < <(tmux list-panes -a -F "$(pane_contents_format)" | skip_grouped_sessions)

	# save only panes with some command output
	for ((i = 0; i < ${#unsure[@]}; i += TMUX_BATCH_MAX_COUNT / 2)); do
		local -a chunk=("${unsure[@]:$i:$((TMUX_BATCH_MAX_COUNT / 2))}")
		local -a chunk_pane_ids=()
		for count in "${chunk[@]}"; do
			chunk_pane_ids+=("${pane_ids[$count]}")
		done
		local j=0
		while read count; do
			if [ "$count" -gt 1 ]; then
				panes+=("${chunk[$j]}")
			fi
			j=$((j + 1))
		done < <(number_nonempty_lines_on_screens "${chunk_pane_ids[@]}")
	done

	# capture in chunks, all of the contents go through a pipe
	local -a args=()
	for i in "${panes[@]}"; do
		if [ "$pane_contents_area" = "visible" ]; then
			args+=("${pane_ids[$i]}" "0" "${files[$i]}")
		else
			args+=("${pane_ids[$i]}" "${start_lines[$i]}" "${files[$i]}")
		fi
		if [ "${#args[@]}" -ge 60 ]; then
			capture_panes_contents "${args[@]}"
			args=()
		fi
	done
	if [ "${#args[@]}" -gt 0 ]; then
		capture_panes_contents "${args[@]}"
	fi
}

remove_old_backups() {
	# remove resurrect files older than 30 days (default), but keep at least 5 copies of backup.
	local delete_after="$(get_tmux_option "$delete_backup_after_option" "$default_delete_backup_after")"
	local -a files
	files=($(ls -t $(resurrect_dir)/${RESURRECT_FILE_PREFIX}_*.${RESURRECT_FILE_EXTENSION} | tail -n +6))
	[[ ${#files[@]} -eq 0 ]] ||
		find "${files[@]}" -type f -mtime "+${delete_after}" -exec rm -v "{}" \; > /dev/null
}

save_all() {
	local resurrect_file_path="$(resurrect_file_path)"
	local last_resurrect_file="$(last_resurrect_file)"
	mkdir -p "$(resurrect_dir)"
	fetch_and_dump_grouped_sessions > "$resurrect_file_path"
	dump_panes   >> "$resurrect_file_path"
	dump_windows >> "$resurrect_file_path"
	dump_state   >> "$resurrect_file_path"
	execute_hook "post-save-layout" "$resurrect_file_path"
	if files_differ "$resurrect_file_path" "$last_resurrect_file"; then
		ln -fs "$(basename "$resurrect_file_path")" "$last_resurrect_file"
	else
		rm "$resurrect_file_path"
	fi
	if capture_pane_contents_option_on; then
		mkdir -p "$(pane_contents_dir "save")"
		dump_pane_contents
		pane_contents_create_archive
		rm "$(pane_contents_dir "save")"/*
	fi
	remove_old_backups
	execute_hook "post-save-all"
}

show_output() {
	[ "$SCRIPT_OUTPUT" != "quiet" ]
}

main() {
	if supported_tmux_version_ok; then
		if show_output; then
			start_spinner "Saving..." "Tmux environment saved!"
		fi
		save_all
		if show_output; then
			stop_spinner
			display_message "Tmux environment saved!"
		fi
	fi
}
main
