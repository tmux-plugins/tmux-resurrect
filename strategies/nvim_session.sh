#!/usr/bin/env bash

# "nvim session strategy"
#
# Same as vim strategy, see file 'vim_session.sh'

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

nvim_session_file_exists() {
	[ -e "${DIRECTORY}/Session.vim" ]
}

original_command_contains_session_flag() {
	[[ "$ORIGINAL_COMMAND" =~ "-S" ]]
}

main() {
	if original_command_is_alias; then
		$EXECUTED_COMMAND=${BASH_REMATCH[1]}
	fi

	local cmd="\$EXECUTD_COMMAND"
	if executed_command_contains_obsession_command; then
		cmd="\nvim"
	fi

	if nvim_session_file_exists; then
		echo "$cmd -S"
	elif original_command_contains_session_flag; then
		# Session file does not exist, yet the original nvim command contains
		# session flag `-S`. This will cause an error, so we're falling back to
		# starting plain nvim.
		echo "\nvim"
	else
		echo "$cmd"
	fi
}
main
