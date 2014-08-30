#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/spinner_helpers.sh"

pane_format() {
	local delimiter=$'\t'
	local format
	format+="pane"
	format+="${delimiter}"
	format+="#{session_name}"
	format+="${delimiter}"
	format+="#{window_index}"
	format+="${delimiter}"
	format+=":#{window_name}"
	format+="${delimiter}"
	format+="#{window_active}"
	format+="${delimiter}"
	format+=":#{window_flags}"
	format+="${delimiter}"
	format+="#{pane_index}"
	format+="${delimiter}"
	format+=":#{pane_current_path}"
	format+="${delimiter}"
	format+="#{pane_active}"
	format+="${delimiter}"
	format+="#{pane_current_command}"
	format+="${delimiter}"
	format+="#{pane_pid}"
	echo "$format"
}

window_format() {
	local delimiter=$'\t'
	local format
	format+="window"
	format+="${delimiter}"
	format+="#{session_name}"
	format+="${delimiter}"
	format+="#{window_index}"
	format+="${delimiter}"
	format+="#{window_active}"
	format+="${delimiter}"
	format+=":#{window_flags}"
	format+="${delimiter}"
	format+="#{window_layout}"
	echo "$format"
}

state_format() {
	local delimiter=$'\t'
	local format
	format+="state"
	format+="${delimiter}"
	format+="#{client_session}"
	format+="${delimiter}"
	format+="#{client_last_session}"
	echo "$format"
}

dump_panes_raw() {
	tmux list-panes -a -F "$(pane_format)"
}

pane_full_command() {
	pane_pid="$1"
	\pgrep -lf -P "$pane_pid" |
		cut -d' ' -f2-
}

# translates pane pid to process command running inside a pane
dump_panes() {
	local full_command
	local d=$'\t' # delimiter
	dump_panes_raw |
		while IFS=$'\t' read line_type session_name window_number window_name window_active window_flags pane_index dir pane_active pane_command pane_pid; do
			full_command="$(pane_full_command $pane_pid)"
			echo "${line_type}${d}${session_name}${d}${window_number}${d}${window_name}${d}${window_active}${d}${window_flags}${d}${pane_index}${d}${dir}${d}${pane_active}${d}${pane_command}${d}:${full_command}"
		done
}

dump_windows() {
	tmux list-windows -a -F "$(window_format)"
}

dump_state() {
	tmux display-message -p "$(state_format)"
}

save_all() {
	local resurrect_file_path="$(resurrect_file_path)"
	mkdir -p "$(resurrect_dir)"
	dump_panes   >  $resurrect_file_path
	dump_windows >> $resurrect_file_path
	dump_state   >> $resurrect_file_path
	ln -fs "$resurrect_file_path" "$(last_resurrect_file)"
}

main() {
	if supported_tmux_version_ok; then
		start_spinner "Saving..." "Tmux environment saved!"
		save_all
		stop_spinner
		display_message "Tmux environment saved!"
	fi
}
main
