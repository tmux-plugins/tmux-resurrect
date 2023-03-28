#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PANE_PID="$1"

exit_safely_if_empty_ppid() {
	if [ -z "$PANE_PID" ]; then
		exit 0
	fi
}

full_command() {
	ps -ao "ppid,args" |
		sed "s/^ *//" |
		grep "^${PANE_PID}" |
		cut -d' ' -f2- |
		tail -1
}

main() {
	exit_safely_if_empty_ppid
	full_command
}
main
