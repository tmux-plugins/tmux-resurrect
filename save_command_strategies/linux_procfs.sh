#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PANE_PID="$1"
COMMAND_PID=$(pgrep -P $PANE_PID)

exit_safely_if_empty_ppid() {
	if [ -z "$PANE_PID" ]; then
		exit 0
	fi
}

full_command() {
	[[ -z "$COMMAND_PID" ]] && exit 0
    # See: https://unix.stackexchange.com/a/567021
    # Avoid complications with system printf by using bash subshell interpolation.
    # This will properly escape sequences and null in cmdline.
    cat /proc/${COMMAND_PID}/cmdline | xargs -0 bash -c 'printf "%q " "$0" "$@"'
}

main() {
	exit_safely_if_empty_ppid
	full_command
}
main
