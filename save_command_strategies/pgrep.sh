#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PANE_PID="$1"

exit_safely_if_empty_ppid() {
	if [ -z "$PANE_PID" ]; then
		exit 0
	fi
}

# `pgrep -lf` prints the raw argument list, so a command containing a newline
# (e.g. a multi-line shell snippet) spans several lines and breaks the
# tab-delimited save file. Ask pgrep only for the child PIDs, then let `ps`
# render the command line the same way the default "ps" strategy does.
full_command() {
	local child_pids
	child_pids="$(\pgrep -P "$PANE_PID" | tr '\n' ',' | sed 's/,$//')"
	if [ -n "$child_pids" ]; then
		ps -o args= -p "$child_pids"
	fi
}

main() {
	exit_safely_if_empty_ppid
	full_command
}
main
