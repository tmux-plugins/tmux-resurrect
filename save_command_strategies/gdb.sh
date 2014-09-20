#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PANE_PID="$1"

exit_safely_if_empty_ppid() {
	if [ -z "$PANE_PID" ]; then
		exit 0
	fi
}

full_command() {
	gdb -batch --eval "attach $PANE_PID" --eval "call write_history(\"/tmp/bash_history-${PANE_PID}.txt\")" --eval 'detach' --eval 'q' >/dev/null 2>&1
	\tail -1 "/tmp/bash_history-${PANE_PID}.txt"
}

main() {
	exit_safely_if_empty_ppid
	full_command
}
main
