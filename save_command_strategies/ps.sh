#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PANE_PID="$1"

exit_safely_if_empty_ppid() {
	if [ -z "$PANE_PID" ]; then
		exit 0
	fi
}

default_command() {
	tmux_command=$(tmux show-option default-command)
	tmux_shell=$(tmux show-option default-shell)
	echo "${tmux_command:-${tmux_shell:-${SHELL:-/bin/sh}}}"
}

full_command() {
	# get the absolute path and args of the running process
	parent=$(ps -p "${PANE_PID}" -o args | tail -n +2)
	if echo "$parent" | grep --quiet -E -- "-?$(basename "$(default_command)")"; then
		# normally the PID is a shell. return the child that has an associated controlling terminal.
		child=$(ps -ao "ppid,args" |
			sed "s/^ *//" |
			grep "^${PANE_PID}" |
			cut -d' ' -f2-)
		if [ "$child" ]; then
			printf %s "$child"
			return
		fi
	fi
	# if this command was spawned with `tmux split-pane`, it has no parent shell.
	# just return the args for the PID itself.
	ps -p "${PANE_PID}" -o args | tail -n +2
}

main() {
	exit_safely_if_empty_ppid
	full_command
}
main
