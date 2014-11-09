#!/usr/bin/env bash

# "nvim session strategy"
#
# Same as vim strategy, see file 'vim_session.sh'

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

nvim_session_file_exists() {
	[ -e "${DIRECTORY}/Session.vim" ]
}

original_command_contains_session_flag() {
	[[ "$ORIGINAL_COMMAND" =~ "-S" ]]
}

main() {
	if nvim_session_file_exists; then
		echo "nvim -S"
	elif original_command_contains_session_flag; then
		# Session file does not exist, yet the original nvim command contains
		# session flag `-S`. This will cause an error, so we're falling back to
		# starting plain nvim.
		echo "nvim"
	else
		echo "$ORIGINAL_COMMAND"
	fi
}
main
