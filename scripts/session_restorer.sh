#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"

window_exists() {
	local session_name="$1"
	local window_number="$2"
	tmux list-windows -t "$session_name" -F "#{window_index}" 2>/dev/null |
		\grep -q "^$window_number$"
}

session_exists() {
	local session_name="$1"
	tmux has-session -t "$session_name" 2>/dev/null
}

first_window_num() {
	tmux show -gv base-index
}

tmux_socket() {
	echo $TMUX | cut -d',' -f1
}

new_window() {
	local session_name="$1"
	local window_number="$2"
	local window_name="$3"
	local dir="$4"
	tmux new-window -d -t "${session_name}:${window_number}" -n "$window_name" -c "$dir"
}

new_session() {
	local session_name="$1"
	local window_number="$2"
	local window_name="$3"
	local dir="$4"
	TMUX="" tmux -S "$(tmux_socket)" new-session -d -s "$session_name" -n "$window_name" -c "$dir"
	# change first window number if necessary
	local created_window_num="$(first_window_num)"
	if [ $created_window_num -ne $window_number ]; then
		tmux move-window -s "${session_name}:${created_window_num}" -t "${session_name}:${window_number}"
	fi
}

new_pane() {
	local session_name="$1"
	local window_number="$2"
	local window_name="$3"
	local dir="$4"
	tmux split-window -d -t "${session_name}:${window_number}" -c "$dir"
}

restore_pane() {
	local pane="$1"
	echo "$pane" |
	while IFS=$'\t' read session_name window_number window_name dir; do
		if window_exists "$session_name" "$window_number"; then
			new_pane "$session_name" "$window_number" "$window_name" "$dir"
		elif session_exists "$session_name"; then
			new_window "$session_name" "$window_number" "$window_name" "$dir"
		else
			new_session "$session_name" "$window_number" "$window_name" "$dir"
		fi
	done
}

restore_all_sessions() {
	while read line; do
		restore_pane "$line"
	done < $(last_session_path)
	display_message "Restored all Tmux sessions!"
}

main() {
	restore_all_sessions
}
main
