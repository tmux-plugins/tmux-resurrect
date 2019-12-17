#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PANE_PID="$1"
CPID=$(pgrep -P $PANE_PID)

exit_safely_if_empty_ppid() {
	if [ -z "$PANE_PID" ]; then
		exit 0
	fi
}

full_command() {
	[[ -z "$CPID" ]] && exit 0
	cat /proc/${CPID}/cmdline | xargs -0 printf "%q "
}

main() {
	exit_safely_if_empty_ppid
	full_command
}
main
