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

original_command_contains_session_flag() {
	[[ "$ORIGINAL_COMMAND" =~ "-S" ]]
}

main() {
	if vim_session_file_exists; then
		echo "vim -S"
	elif original_command_contains_session_flag; then
		# Session file does not exist, yet the original vim command contains
		# session flag `-S`. This will cause an error, so we're falling back to
		# starting plain vim.
		echo "vim"
	else
		echo "$ORIGINAL_COMMAND"
	fi
}
main
