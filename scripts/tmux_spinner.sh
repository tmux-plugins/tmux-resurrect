#!/usr/bin/env bash

# This script shows tmux spinner with a message. It is intended to be running
# as a background process which should be `kill`ed at the end.
#
# Example usage:
#
#   ./tmux_spinner.sh "Working..." "End message!" &
#   SPINNER_PID=$!
#   ..
#   .. execute commands here
#   ..
#   kill $SPINNER_PID # Stops spinner and displays 'End message!'

MESSAGE="$1"
END_MESSAGE="$2"
SPIN='-\|/'

trap "tmux display-message '$END_MESSAGE'; exit" SIGINT SIGTERM

main() {
	local i=0
	while true; do
	  i=$(( (i+1) %4 ))
	  tmux display-message " ${SPIN:$i:1} $MESSAGE"
	  sleep 0.1
	done
}
main
