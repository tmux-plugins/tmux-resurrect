#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/../scripts/helpers.sh"

PANE_PID="$1"

exit_safely_if_empty_ppid() {
	if [ -z "$PANE_PID" ]; then
		exit 0
	fi
}

full_command() {
	local tmp_dir="$(resurrect_dir)/tmp"
	local history_file="$tmp_dir/bash_history-${PANE_PID}.txt"
	mkdir -p "$tmp_dir"
	gdb -batch --eval "attach $PANE_PID" --eval "call write_history(\"$history_file\")" --eval 'detach' --eval 'q' >/dev/null 2>&1
	\tail -1 "$history_file"
}

main() {
	exit_safely_if_empty_ppid
	full_command
}
main
