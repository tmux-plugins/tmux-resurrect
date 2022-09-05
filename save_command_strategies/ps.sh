#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PANE_PID="$1"

is_command_tmux_child() {
  if [ $(ps -o cmd= $(ps -o ppid= "${PANE_PID}")) == tmux ]; then
    ps -o cmd= "${PANE_PID}"
  fi
}

exit_safely_if_empty_ppid() {
	if [ -z "$PANE_PID" ]; then
		exit 0
	fi
}

full_command() {
	local FULL_COMMAND=$(ps -ao "ppid command" |
		sed "s/^ *//" |
		grep "^${PANE_PID}" |
    cut -d' ' -f2-)
  [ -z $FULL_COMMAND ] && is_command_tmux_child || echo "$FULL_COMMAND"
}

main() {
	exit_safely_if_empty_ppid
	full_command
}
main
