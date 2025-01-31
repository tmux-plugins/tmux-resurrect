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

persistence_nvim_plugin_exists() {
	nvim --headless -c 'lua if not pcall(require, "persistence") then os.exit(1) end' -c 'qa'
	# shellcheck disable=2181
	[ $? -eq 0 ]
}

main() {
	if nvim_session_file_exists; then
		echo "nvim -S"
	elif original_command_contains_session_flag; then
		# Session file does not exist, yet the original nvim command contains
		# session flag `-S`. This will cause an error, so we're falling back to
		# starting plain nvim.
		echo "nvim"
	elif persistence_nvim_plugin_exists; then
		# Load folke's persistence.nvim sessions. And Shoutout to ThePrimeagen and TjDevries.
		# Also Shoutout to my favorite youtuber Mr. Hussein Nasser because I'm learning a lot from you.
		echo "nvim -c 'lua require(\"persistence\").load()'"
	else
		echo "$ORIGINAL_COMMAND"
	fi
}
main
