#!/usr/bin/env bash

# "irb default strategy"
#
# Example irb process with junk variables:
#   irb RBENV_VERSION=1.9.3-p429 GREP_COLOR=34;47 TERM_PROGRAM=Apple_Terminal
#
# When executed, the above will fail. This strategy handles that.

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

original_command_wo_junk_vars() {
	echo "$ORIGINAL_COMMAND" |
		sed 's/RBENV_VERSION[^ ]*//' |
		sed 's/GREP_COLOR[^ ]*//'    |
		sed 's/TERM_PROGRAM[^ ]*//'
}

main() {
	echo "$(original_command_wo_junk_vars)"
}
main
