#!/usr/bin/env bash

# "vim session strategy"
#
# Restores a vim session from 'Session.vim' file, if it exists.
# If 'Session.vim' does not exist, it falls back to invoking the original
# command (without the `-S` flag).

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

vim_session_file_exists() {
	[ -e "${DIRECTORY}/Session.vim" ]
}

main() {
	if vim_session_file_exists; then
		echo "vim -S"
	else
		echo "$ORIGINAL_COMMAND"
	fi
}
main
