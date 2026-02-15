#!/usr/bin/env bash

# "codex session strategy"
#
# Restores OpenAI Codex CLI sessions using the `resume --last` subcommand,
# which resumes the most recent conversation in the working directory.

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

original_command_contains_resume() {
	[[ "$ORIGINAL_COMMAND" =~ (^|[[:space:]])(resume|fork)([[:space:]]|$) ]]
}

main() {
	if original_command_contains_resume; then
		echo "$ORIGINAL_COMMAND"
	else
		echo "codex resume --last"
	fi
}
main
