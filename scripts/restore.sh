#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/process_restore_helpers.sh"
source "$CURRENT_DIR/spinner_helpers.sh"

# delimiter
d=$'\t'

# Global variable.
# Used during the restore: if a pane already exists from before, it is
# saved in the array in this variable. Later, process running in existing pane
# is also not restored. That makes the restoration process more idempotent.
EXISTING_PANES_VAR=""

RESTORING_FROM_SCRATCH="false"

RESTORE_PANE_CONTENTS="false"

is_line_type() {
	local line_type="$1"
	local line="$2"
	echo "$line" |
		\grep -q "^$line_type"
}

check_saved_session_exists() {
	local resurrect_file="$(last_resurrect_file)"
	if [ ! -f $resurrect_file ]; then
		display_message "Tmux resurrect file not found!"
		return 1
	fi
}

pane_exists() {
	local session_name="$1"
	local window_number="$2"
	local pane_index="$3"
	tmux list-panes -t "${session_name}:${window_number}" -F "#{pane_index}" 2>/dev/null |
		\grep -q "^$pane_index$"
}

register_existing_pane() {
	local session_name="$1"
	local window_number="$2"
	local pane_index="$3"
	local pane_custom_id="${session_name}:${window_number}:${pane_index}"
	local delimiter=$'\t'
	EXISTING_PANES_VAR="${EXISTING_PANES_VAR}${delimiter}${pane_custom_id}"
}

is_pane_registered_as_existing() {
	local session_name="$1"
	local window_number="$2"
	local pane_index="$3"
	local pane_custom_id="${session_name}:${window_number}:${pane_index}"
	[[ "$EXISTING_PANES_VAR" =~ "$pane_custom_id" ]]
}

restore_from_scratch_true() {
	RESTORING_FROM_SCRATCH="true"
}

is_restoring_from_scratch() {
	[ "$RESTORING_FROM_SCRATCH" == "true" ]
}

restore_pane_contents_true() {
	RESTORE_PANE_CONTENTS="true"
}

is_restoring_pane_contents() {
	[ "$RESTORE_PANE_CONTENTS" == "true" ]
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

# Tmux option stored in a global variable so that we don't have to "ask"
# tmux server each time.
cache_tmux_default_command() {
	local default_shell="$(get_tmux_option "default-shell" "")"
	export TMUX_DEFAULT_COMMAND="$(get_tmux_option "default-command" "$default_shell")"
}

tmux_default_command() {
	echo "$TMUX_DEFAULT_COMMAND"
}

pane_creation_command() {
	echo "cat '$(pane_contents_file "restore" "${1}:${2}.${3}")'; exec $(tmux_default_command)"
}

new_window() {
	local session_name="$1"
	local window_number="$2"
	local window_name="$3"
	local dir="$4"
	local pane_index="$5"
	local pane_id="${session_name}:${window_number}.${pane_index}"
	if is_restoring_pane_contents && pane_contents_file_exists "$pane_id"; then
		local pane_creation_command="$(pane_creation_command "$session_name" "$window_number" "$pane_index")"
		tmux new-window -d -t "${session_name}:${window_number}" -n "$window_name" -c "$dir" "$pane_creation_command"
	else
		tmux new-window -d -t "${session_name}:${window_number}" -n "$window_name" -c "$dir"
	fi
}

new_session() {
	local session_name="$1"
	local window_number="$2"
	local window_name="$3"
	local dir="$4"
	local pane_index="$5"
	local pane_id="${session_name}:${window_number}.${pane_index}"
	if is_restoring_pane_contents && pane_contents_file_exists "$pane_id"; then
		local pane_creation_command="$(pane_creation_command "$session_name" "$window_number" "$pane_index")"
		TMUX="" tmux -S "$(tmux_socket)" new-session -d -s "$session_name" -n "$window_name" -c "$dir" "$pane_creation_command"
	else
		TMUX="" tmux -S "$(tmux_socket)" new-session -d -s "$session_name" -n "$window_name" -c "$dir"
	fi
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
	local pane_index="$5"
	local pane_id="${session_name}:${window_number}.${pane_index}"
	if is_restoring_pane_contents && pane_contents_file_exists "$pane_id"; then
		local pane_creation_command="$(pane_creation_command "$session_name" "$window_number" "$pane_index")"
		tmux split-window -t "${session_name}:${window_number}" -c "$dir" "$pane_creation_command"
	else
		tmux split-window -t "${session_name}:${window_number}" -c "$dir"
	fi
	# minimize window so more panes can fit
	tmux resize-pane  -t "${session_name}:${window_number}" -U "999"
}

restore_pane() {
	local pane="$1"
	while IFS=$d read line_type session_name window_number window_name window_active window_flags pane_index dir pane_active pane_command pane_full_command; do
		dir="$(remove_first_char "$dir")"
		window_name="$(remove_first_char "$window_name")"
		pane_full_command="$(remove_first_char "$pane_full_command")"
		if pane_exists "$session_name" "$window_number" "$pane_index"; then
			if is_restoring_from_scratch; then
				# overwrite the pane
				# happens only for the first pane if it's the only registered pane for the whole tmux server
				local pane_id="$(tmux display-message -p -F "#{pane_id}" -t "$session_name:$window_number")"
				new_pane "$session_name" "$window_number" "$window_name" "$dir" "$pane_index"
				tmux kill-pane -t "$pane_id"
			else
				# Pane exists, no need to create it!
				# Pane existence is registered. Later, its process also won't be restored.
				register_existing_pane "$session_name" "$window_number" "$pane_index"
			fi
		elif window_exists "$session_name" "$window_number"; then
			new_pane "$session_name" "$window_number" "$window_name" "$dir" "$pane_index"
		elif session_exists "$session_name"; then
			new_window "$session_name" "$window_number" "$window_name" "$dir" "$pane_index"
		else
			new_session "$session_name" "$window_number" "$window_name" "$dir" "$pane_index"
		fi
	done < <(echo "$pane")
}

restore_state() {
	local state="$1"
	echo "$state" |
	while IFS=$d read line_type client_session client_last_session; do
		tmux switch-client -t "$client_last_session"
		tmux switch-client -t "$client_session"
	done
}

restore_grouped_session() {
	local grouped_session="$1"
	echo "$grouped_session" |
	while IFS=$d read line_type grouped_session original_session alternate_window active_window; do
		TMUX="" tmux -S "$(tmux_socket)" new-session -d -s "$grouped_session" -t "$original_session"
	done
}

restore_active_and_alternate_windows_for_grouped_sessions() {
	local grouped_session="$1"
	echo "$grouped_session" |
	while IFS=$d read line_type grouped_session original_session alternate_window_index active_window_index; do
		alternate_window_index="$(remove_first_char "$alternate_window_index")"
		active_window_index="$(remove_first_char "$active_window_index")"
		if [ -n "$alternate_window_index" ]; then
			tmux switch-client -t "${grouped_session}:${alternate_window_index}"
		fi
		if [ -n "$active_window_index" ]; then
			tmux switch-client -t "${grouped_session}:${active_window_index}"
		fi
	done
}

never_ever_overwrite() {
	local overwrite_option_value="$(get_tmux_option "$overwrite_option" "")"
	[ -n "$overwrite_option_value" ]
}

detect_if_restoring_from_scratch() {
	if never_ever_overwrite; then
		return
	fi
	local total_number_of_panes="$(tmux list-panes -a | wc -l | sed 's/ //g')"
	if [ "$total_number_of_panes" -eq 1 ]; then
		restore_from_scratch_true
	fi
}

detect_if_restoring_pane_contents() {
	if capture_pane_contents_option_on; then
		cache_tmux_default_command
		restore_pane_contents_true
	fi
}

# functions called from main (ordered)

restore_all_panes() {
	detect_if_restoring_from_scratch   # sets a global variable
	detect_if_restoring_pane_contents  # sets a global variable
	if is_restoring_pane_contents; then
		pane_content_files_restore_from_archive
	fi
	while read line; do
		if is_line_type "pane" "$line"; then
			restore_pane "$line"
		fi
	done < $(last_resurrect_file)
	if is_restoring_pane_contents; then
		rm "$(pane_contents_dir "restore")"/*
	fi
}

restore_pane_layout_for_each_window() {
	\grep '^window' $(last_resurrect_file) |
		while IFS=$d read line_type session_name window_number window_active window_flags window_layout; do
			tmux select-layout -t "${session_name}:${window_number}" "$window_layout"
		done
}

restore_shell_history() {
	awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ { print $2, $3, $7, $10; }' $(last_resurrect_file) |
		while IFS=$d read session_name window_number pane_index pane_command; do
			if ! is_pane_registered_as_existing "$session_name" "$window_number" "$pane_index"; then
				local pane_id="$session_name:$window_number.$pane_index"
				local history_file="$(resurrect_history_file "$pane_id" "$pane_command")"

				if [ "$pane_command" = "bash" ]; then
					local read_command="history -r '$history_file'"
					tmux send-keys -t "$pane_id" "$read_command" C-m
				elif [ "$pane_command" = "zsh" ]; then
					local accept_line="$(expr "$(zsh -i -c bindkey | grep -m1 '\saccept-line$')" : '^"\(.*\)".*')"
					local read_command="fc -R '$history_file'; clear"
					tmux send-keys -t "$pane_id" "$read_command" "$accept_line"
				fi
			fi
		done
}

restore_all_pane_processes() {
	if restore_pane_processes_enabled; then
		local pane_full_command
		awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ && $11 !~ "^:$" { print $2, $3, $7, $8, $11; }' $(last_resurrect_file) |
			while IFS=$d read session_name window_number pane_index dir pane_full_command; do
				dir="$(remove_first_char "$dir")"
				pane_full_command="$(remove_first_char "$pane_full_command")"
				restore_pane_process "$pane_full_command" "$session_name" "$window_number" "$pane_index" "$dir"
			done
	fi
}

restore_active_pane_for_each_window() {
	awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ && $9 == 1 { print $2, $3, $7; }' $(last_resurrect_file) |
		while IFS=$d read session_name window_number active_pane; do
			tmux switch-client -t "${session_name}:${window_number}"
			tmux select-pane -t "$active_pane"
		done
}

restore_zoomed_windows() {
	awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ && $6 ~ /Z/ && $9 == 1 { print $2, $3; }' $(last_resurrect_file) |
		while IFS=$d read session_name window_number; do
			tmux resize-pane -t "${session_name}:${window_number}" -Z
		done
}

restore_grouped_sessions() {
	while read line; do
		if is_line_type "grouped_session" "$line"; then
			restore_grouped_session "$line"
			restore_active_and_alternate_windows_for_grouped_sessions "$line"
		fi
	done < $(last_resurrect_file)
}

restore_active_and_alternate_windows() {
	awk 'BEGIN { FS="\t"; OFS="\t" } /^window/ && $5 ~ /[*-]/ { print $2, $4, $3; }' $(last_resurrect_file) |
		sort -u |
		while IFS=$d read session_name active_window window_number; do
			tmux switch-client -t "${session_name}:${window_number}"
		done
}

restore_active_and_alternate_sessions() {
	while read line; do
		if is_line_type "state" "$line"; then
			restore_state "$line"
		fi
	done < $(last_resurrect_file)
}

main() {
	if supported_tmux_version_ok && check_saved_session_exists; then
		start_spinner "Restoring..." "Tmux restore complete!"
		restore_all_panes
		restore_pane_layout_for_each_window >/dev/null 2>&1
		if save_shell_history_option_on; then
			restore_shell_history
		fi
		restore_all_pane_processes
		# below functions restore exact cursor positions
		restore_active_pane_for_each_window
		restore_zoomed_windows
		restore_grouped_sessions  # also restores active and alt windows for grouped sessions
		restore_active_and_alternate_windows
		restore_active_and_alternate_sessions
		stop_spinner
		display_message "Tmux restore complete!"
	fi
}
main
