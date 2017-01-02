#!/usr/bin/env bash

# "vim session strategy"
#
# Restores a vim session from 'Session.vim' file, if it exists.
# If 'Session.vim' does not exist, it falls back to invoking the original
# command (without the `-S` flag).

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"
EXECUTED_COMMAND=$ORIGINAL_COMMAND

original_command_is_alias() {
	local alias_regex=".*='(.*)'"
	[[ `alias $ORIGINAL_COMMAND` =~ $alias_regex ]]
}

executed_command_contains_obsession_command() {
	[[ "$EXECUTED_COMMAND" =~ "-c Obsession" ]]
}

vim_session_file_exists() {
	[ -e "${DIRECTORY}/Session.vim" ]
}

executed_command_contains_session_flag() {
	[[ "$EXECUTED_COMMAND" =~ "-S" ]]
}

main() {
	if original_command_is_alias; then
		$EXECUTED_COMMAND=${BASH_REMATCH[1]}
	fi

	local cmd="\$EXECUTD_COMMAND"
	if executed_command_contains_obsession_command; then
		cmd="\vim"
	fi

	if vim_session_file_exists; then
		echo "$cmd -S"
	elif original_command_contains_session_flag; then
		# Session file does not exist, yet the original vim command contains
		# session flag `-S`. This will cause an error, so we're falling back to
		# starting plain vim.
		echo "\vim"
	else
		echo "$cmd"
	fi
}
main
