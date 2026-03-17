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

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/spinner_helpers.sh"
source "$CURRENT_DIR/variables.sh"

MESSAGE="$1"
END_MESSAGE="$2"
DEFAULT_SPIN_CHARS='-\|/'
SPIN_CHARS=$( get_tmux_option "$spinner_chars_option" "$DEFAULT_SPIN_CHARS" )
SPIN_CHARS_LENGTH=$( echo -n "$SPIN_CHARS" | wc -m )
WAVE_LABEL="$(spinner_wave_label "$MESSAGE")"
CONTROL_MODE_FIFO=""
CONTROL_MODE_DIR=""
CONTROL_MODE_PID=""
CONTROL_MODE_READY="false"
TARGET_CLIENT_TTY=""

tmux_quote() {
	printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

tmux_control_target_client() {
	tmux display-message -p -F "#{client_tty}" 2>/dev/null
}

tmux_control_start() {
	TARGET_CLIENT_TTY="$(tmux_control_target_client)"

	if [ -z "$TARGET_CLIENT_TTY" ]; then
		return 1
	fi

	CONTROL_MODE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tmux-resurrect-spinner.XXXXXX" 2>/dev/null)"
	if [ -z "$CONTROL_MODE_DIR" ]; then
		return 1
	fi

	CONTROL_MODE_FIFO="$CONTROL_MODE_DIR/control-mode"
	if ! mkfifo "$CONTROL_MODE_FIFO"; then
		rmdir "$CONTROL_MODE_DIR"
		CONTROL_MODE_DIR=""
		return 1
	fi

	tmux -C <"$CONTROL_MODE_FIFO" >/dev/null 2>&1 &
	CONTROL_MODE_PID="$!"

	if ! exec 3>"$CONTROL_MODE_FIFO"; then
		kill "$CONTROL_MODE_PID" 2>/dev/null
		wait "$CONTROL_MODE_PID" 2>/dev/null
		rm -f "$CONTROL_MODE_FIFO"
		rmdir "$CONTROL_MODE_DIR"
		CONTROL_MODE_FIFO=""
		CONTROL_MODE_DIR=""
		CONTROL_MODE_PID=""
		return 1
	fi

	CONTROL_MODE_READY="true"
}

tmux_control_send() {
	local command="$1"

	if [ "$CONTROL_MODE_READY" = "true" ] && [ -n "$CONTROL_MODE_PID" ]; then
		printf '%s\n' "$command" >&3 2>/dev/null || return 1
		return 0
	fi

	return 1
}

tmux_send_display_message() {
	local message="$1"
	local quoted_message="$(tmux_quote "$message")"

	if tmux_control_send "display-message -c $(tmux_quote "$TARGET_CLIENT_TTY") $quoted_message"; then
		return 0
	fi

	tmux display-message "$message"
}

cleanup() {
	local final_message="$1"

	if [ -n "$final_message" ]; then
		tmux_send_display_message "$final_message"
	fi

	if [ "$CONTROL_MODE_READY" = "true" ]; then
		exec 3>&-
		CONTROL_MODE_READY="false"
	fi

	if [ -n "$CONTROL_MODE_PID" ]; then
		wait "$CONTROL_MODE_PID" 2>/dev/null
	fi

	if [ -n "$CONTROL_MODE_FIFO" ]; then
		rm -f "$CONTROL_MODE_FIFO"
	fi

	if [ -n "$CONTROL_MODE_DIR" ]; then
		rmdir "$CONTROL_MODE_DIR" 2>/dev/null
	fi
}

handle_exit() {
	cleanup "$END_MESSAGE"
	exit
}

trap "handle_exit" SIGINT SIGTERM

main() {
	local i=0
	tmux_control_start
	while true; do
	  if [ -n "$WAVE_LABEL" ]; then
		tmux_send_display_message "$(spinner_wave_message "$WAVE_LABEL" "$i")"
		i=$((i + 1))
	  else
		i=$(( (i+1) % $SPIN_CHARS_LENGTH ))
		tmux_send_display_message " ${SPIN_CHARS:$i:1} $MESSAGE"
	  fi
	  sleep 0.1
	done
}
main
