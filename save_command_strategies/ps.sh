#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PANE_PID="$1"

exit_safely_if_empty_ppid() {
	if [ -z "$PANE_PID" ]; then
		exit 0
	fi
}

ps_command_flags() {
	case $(uname -s) in
		FreeBSD) echo "-ao" ;;
		OpenBSD) echo "-ao" ;;
		Linux) echo "-ao" ;;
		*) echo "-eo" ;;
	esac
}

full_command() {
	ps "$(ps_command_flags)" "ppid command" |
		sed "s/^ *//" |
		grep "^${PANE_PID}" |
		cut -d' ' -f2-
}

main() {
	exit_safely_if_empty_ppid
	full_command
}
main
