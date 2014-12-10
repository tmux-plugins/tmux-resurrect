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

_save_command_strategy_file() {
	local save_command_strategy="$(get_tmux_option "$save_command_strategy_option" "$default_save_command_strategy")"
	local strategy_file="$CURRENT_DIR/../save_command_strategies/${save_command_strategy}.sh"
	local default_strategy_file="$CURRENT_DIR/../save_command_strategies/${default_save_command_strategy}.sh"
	if [ -e "$strategy_file" ]; then # strategy file exists?
		echo "$strategy_file"
	else
		echo "$default_strategy_file"
	fi
}

pane_full_command() {
	local pane_pid="$1"
	local strategy_file="$(_save_command_strategy_file)"
	# execute strategy script to get pane full command
	$strategy_file "$pane_pid"
}

save_shell_history() {
	local pane_id="$1"
	local pane_command="$2"
	local full_command="$3"
	if [ "$pane_command" = "bash" ] && [ "$full_command" = ":" ]; then
		# leading space prevents the command from being saved to history
		# (assuming default HISTCONTROL settings)
		local write_command=" history -w '$(resurrect_history_file "$pane_id")'"
		# C-e C-u is a Bash shortcut sequence to clear whole line. It is necessary to
		# delete any pending input so it does not interfere with our history command.
		tmux send-keys -t "$pane_id" C-e C-u "$write_command" C-m
	fi
}

save_tmux_buffer() {
	local pane_id="$1"
	local pane_command="$2"
	local full_command="$3"
	local mode_keys=$(tmux show-window-options -g | awk '/^mode-keys/ {print $2}')
	local save_command=""
	local buffer_file="$(resurrect_buffer_file "${pane_id}")"
	if [ "$pane_command" = "bash" ] && [ "$full_command" = ":" ]; then
	  tmux capture-pane -S -32768 \; save-buffer -b 0 "${buffer_file}" \; delete-buffer -b 0
		if [ ! -s "${buffer_file}" ] ;then
	    rm "${buffer_file}"
	  fi
	fi
}

# translates pane pid to process command running inside a pane
dump_panes() {
	local full_command
	local d=$'\t' # delimiter
	dump_panes_raw |
		while IFS=$'\t' read line_type session_name window_number window_name window_active window_flags pane_index dir pane_active pane_command pane_pid; do
			# check if current pane is part of a maximized window and if the pane is active
			if [[ "${window_flags}" == *Z* ]] && [[ ${pane_active} == 1 ]]; then
				# unmaximize the pane
				tmux resize-pane -Z -t "${session_name}:${window_number}"
			fi
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

dump_bash_history() {
	dump_panes |
		while IFS=$'\t' read line_type session_name window_number window_name window_active window_flags pane_index dir pane_active pane_command full_command; do
			save_shell_history "$session_name:$window_number.$pane_index" "$pane_command" "$full_command"
		done
}

dump_tmux_buffers() {
	dump_panes |
		while IFS=$'\t' read line_type session_name window_number window_name window_active window_flags pane_index dir pane_active pane_command full_command; do
			save_tmux_buffer "$session_name:$window_number.$pane_index" "$pane_command" "$full_command"
		done
}

save_all() {
	local resurrect_file_path="$(resurrect_file_path)"
	mkdir -p "$(resurrect_dir)"
	dump_panes   >  "$resurrect_file_path"
	dump_windows >> "$resurrect_file_path"
	dump_state   >> "$resurrect_file_path"
	ln -fs "$(basename "$resurrect_file_path")" "$(last_resurrect_file)"
	if save_bash_history_option_on; then
		dump_bash_history
	fi
	if save_tmux_buffers_option_on; then
		dump_tmux_buffers
	fi
	restore_zoomed_windows
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
