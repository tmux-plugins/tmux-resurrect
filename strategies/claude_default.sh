#!/usr/bin/env bash

# "claude code resume strategy"
#
# Claude Code's `claude` CLI cannot resume by re-launch. Each conversation
# is identified by a session UUID and must be re-opened with
# `claude --resume <session-id>`.
#
# Behavior:
#
# 1. If the captured command already carries an explicit --resume/--continue
#    (recorded at save time by save_command_strategies/claude_aware.sh),
#    pass it through unchanged. This is the per-pane mapping path.
# 2. Otherwise, fall back to the most recently modified session file under
#    ~/.claude/projects/<encoded-cwd>/, where the encoded cwd is the
#    absolute path with `/` replaced by `-`. Good enough when only one
#    session per cwd was active.
# 3. When no prior session exists, pass the original captured command
#    through so a fresh `claude` invocation still works.

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

already_resumes() {
	case "$ORIGINAL_COMMAND" in
		*' --resume '*|*' --resume='*|*' -r '*|*' -r='*) return 0 ;;
		*' --continue'*|*' -c'*) return 0 ;;
	esac
	return 1
}

claude_project_dir() {
	local encoded="${DIRECTORY//\//-}"
	echo "${HOME}/.claude/projects/${encoded}"
}

latest_session_id() {
	local project_dir
	project_dir="$(claude_project_dir)"
	[ -d "$project_dir" ] || return 1
	local newest
	newest="$(ls -1t "${project_dir}"/*.jsonl 2>/dev/null | head -1)"
	[ -n "$newest" ] || return 1
	basename "$newest" .jsonl
}

main() {
	if already_resumes; then
		echo "$ORIGINAL_COMMAND"
		return
	fi
	local session_id
	session_id="$(latest_session_id)"
	if [ -n "$session_id" ]; then
		echo "claude --resume $session_id"
	else
		echo "$ORIGINAL_COMMAND"
	fi
}
main
