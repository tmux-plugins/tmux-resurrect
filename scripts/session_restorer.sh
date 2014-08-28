#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/process_restore_helpers.sh"
source "$CURRENT_DIR/spinner_helpers.sh"

is_line_type() {
	local line_type="$1"
	local line="$2"
	echo "$line" |
		\grep -q "^$line_type"
}

check_saved_session_exists() {
	local saved_session="$(last_session_path)"
	if [ ! -f $saved_session ]; then
		display_message "Saved tmux session not found!"
		return 1
	fi
}

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
	tmux split-window -t "${session_name}:${window_number}" -c "$dir"
}

restore_pane() {
	local pane="$1"
	echo "$pane" |
	while IFS=$'\t' read line_type session_name window_number window_name window_active window_flags pane_index dir pane_active pane_command pane_full_command; do
		dir="$(remove_first_char "$dir")"
		window_name="$(remove_first_char "$window_name")"
		pane_full_command="$(remove_first_char "$pane_full_command")"
		if window_exists "$session_name" "$window_number"; then
			new_pane "$session_name" "$window_number" "$window_name" "$dir"
		elif session_exists "$session_name"; then
			new_window "$session_name" "$window_number" "$window_name" "$dir"
		else
			new_session "$session_name" "$window_number" "$window_name" "$dir"
		fi
	done
}

restore_state() {
	local state="$1"
	echo "$state" |
	while IFS=$'\t' read line_type client_session client_last_session; do
		tmux switch-client -t "$client_last_session"
		tmux switch-client -t "$client_session"
	done
}

restore_all_sessions() {
	while read line; do
		if is_line_type "pane" "$line"; then
			restore_pane "$line"
		fi
	done < $(last_session_path)
}

restore_all_pane_processes() {
	if restore_pane_processes_enabled; then
		local pane_full_command
		awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ && $11 !~ "^:$" { print $2, $3, $7, $8, $11; }' $(last_session_path) |
			while IFS=$'\t' read session_name window_number pane_index dir pane_full_command; do
				dir="$(remove_first_char "$dir")"
				pane_full_command="$(remove_first_char "$pane_full_command")"
				restore_pane_process "$pane_full_command" "$session_name" "$window_number" "$pane_index" "$dir"
			done
	fi
}

restore_pane_layout_for_each_window() {
	\grep '^window' $(last_session_path) |
		while IFS=$'\t' read line_type session_name window_number window_active window_flags window_layout; do
			tmux select-layout -t "${session_name}:${window_number}" "$window_layout"
		done
}

restore_active_pane_for_each_window() {
	awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ && $7 != 0 && $9 == 1 { print $2, $3, $7; }' $(last_session_path) |
		while IFS=$'\t' read session_name window_number active_pane; do
			tmux switch-client -t "${session_name}:${window_number}"
			tmux select-pane -t "$active_pane"
		done
}

restore_active_and_alternate_windows() {
	awk 'BEGIN { FS="\t"; OFS="\t" } /^window/ && $5 ~ /[*-]/ { print $2, $4, $3; }' $(last_session_path) |
		sort -u |
		while IFS=$'\t' read session_name active_window window_number; do
			tmux switch-client -t "${session_name}:${window_number}"
		done
}

restore_active_and_alternate_sessions() {
	while read line; do
		if is_line_type "state" "$line"; then
			restore_state "$line"
		fi
	done < $(last_session_path)
}

main() {
	if supported_tmux_version_ok && check_saved_session_exists; then
		start_spinner
		restore_all_sessions
		restore_all_pane_processes
		restore_pane_layout_for_each_window >/dev/null 2>&1
		# below functions restore exact cursor positions
		restore_active_pane_for_each_window
		restore_active_and_alternate_windows
		restore_active_and_alternate_sessions
		stop_spinner
		display_message "Restored all Tmux sessions!"
	fi
}
main
