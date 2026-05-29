#!/usr/bin/env bash

# "claude code resume strategy"
#
# Claude Code (the `claude` CLI) cannot meaningfully resume by re-launching
# a fresh process — each conversation is identified by a session UUID and
# must be re-opened with `claude --resume <session-id>`.
#
# Claude Code stores per-directory sessions under
# `~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl`, where the
# encoded cwd is the absolute path with `/` replaced by `-`. This strategy
# locates the most recently modified session file for the pane's saved
# working directory and emits `claude --resume <session-id>`. When no
# prior session is found we fall back to the originally captured command
# so a fresh `claude` invocation still works.

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

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
	local session_id
	session_id="$(latest_session_id)"
	if [ -n "$session_id" ]; then
		echo "claude --resume $session_id"
	else
		echo "$ORIGINAL_COMMAND"
	fi
}
main
