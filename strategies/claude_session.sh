#!/usr/bin/env bash

# "claude session strategy"
#
# Restores Claude Code CLI sessions using the --continue flag,
# which resumes the most recent conversation in the working directory.

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

original_command_contains_resume_flag() {
	[[ "$ORIGINAL_COMMAND" =~ (--continue|--resume) ]]
}

main() {
	if original_command_contains_resume_flag; then
		echo "$ORIGINAL_COMMAND"
	else
		echo "$ORIGINAL_COMMAND --continue"
	fi
}
main
