#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PANE_TTY="${2/\/dev\//}"

exit_safely_if_empty_ptty() {
	if [ -z "$PANE_TTY" ]; then
		exit 0
	fi
}

ps_command_flags() {
	case $(uname -s) in
		FreeBSD) echo "-ao" ;;
		OpenBSD) echo "-ao" ;;
		*) echo "-eo" ;;
	esac
}

full_command() {
	ps "$(ps_command_flags)" "tty command" |
		sed "s/^ *//" |
		grep "^${PANE_TTY} " |
		cut -d' ' -f2- |
		sed "s/^ *//" |
		grep -v "reattach-to-user-namespace" |
		grep -v "\\-bash" |
		tail -1
}

main() {
	exit_safely_if_empty_ptty
	full_command
}
main
