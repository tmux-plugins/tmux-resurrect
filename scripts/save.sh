#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/spinner_helpers.sh"

# delimiters
d=$'\t'
delimiter=$'\t'

# if "quiet" script produces no output
SCRIPT_OUTPUT="$1"

grouped_sessions_format() {
	local format
	format+="#{session_grouped}"
	format+="${delimiter}"
	format+="#{session_group}"
	format+="${delimiter}"
	format+="#{session_id}"
	format+="${delimiter}"
	format+="#{session_name}"
	echo "$format"
}

pane_format() {
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
	format+="${delimiter}"
	format+="#{history_size}"
	echo "$format"
}

window_format() {
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

dump_windows_raw(){
	tmux list-windows -a -F "$(window_format)"
}

toggle_window_zoom() {
	local target="$1"
	tmux resize-pane -Z -t "$target"
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

number_nonempty_lines_on_screen() {
	local pane_id="$1"
	tmux capture-pane -pJ -t "$pane_id" |
		sed '/^$/d' |
		wc -l |
		sed 's/ //g'
}

# tests if there was any command output in the current pane
pane_has_any_content() {
	local pane_id="$1"
	local history_size="$(tmux display -p -t "$pane_id" -F "#{history_size}")"
	local cursor_y="$(tmux display -p -t "$pane_id" -F "#{cursor_y}")"
	# doing "cheap" tests first
	[ "$history_size" -gt 0 ] || # history has any content?
		[ "$cursor_y" -gt 0 ] || # cursor not in first line?
		[ "$(number_nonempty_lines_on_screen "$pane_id")" -gt 1 ]
}

capture_pane_contents() {
	local pane_id="$1"
	local start_line="-$2"
	local pane_contents_area="$3"
	if pane_has_any_content "$pane_id"; then
		if [ "$pane_contents_area" = "visible" ]; then
			start_line="0"
		fi
		# the printf hack below removes *trailing* empty lines
		printf '%s\n' "$(tmux capture-pane -epJ -S "$start_line" -t "$pane_id")" > "$(pane_contents_file "$pane_id")"
	fi
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

get_active_window_index() {
	local session_name="$1"
	tmux list-windows -t "$session_name" -F "#{window_flags} #{window_index}" |
		awk '$1 ~ /\*/ { print $2; }'
}

get_alternate_window_index() {
	local session_name="$1"
	tmux list-windows -t "$session_name" -F "#{window_flags} #{window_index}" |
		awk '$1 ~ /-/ { print $2; }'
}

dump_grouped_sessions() {
	local current_session_group=""
	local original_session
	tmux list-sessions -F "$(grouped_sessions_format)" |
		grep "^1" |
		cut -c 3- |
		sort |
		while IFS=$d read session_group session_id session_name; do
			if [ "$session_group" != "$current_session_group" ]; then
				# this session is the original/first session in the group
				original_session="$session_name"
				current_session_group="$session_group"
			else
				# this session "points" to the original session
				active_window_index="$(get_active_window_index "$session_name")"
				alternate_window_index="$(get_alternate_window_index "$session_name")"
				echo "grouped_session${d}${session_name}${d}${original_session}${d}:${alternate_window_index}${d}:${active_window_index}"
			fi
		done
}

fetch_and_dump_grouped_sessions(){
	local grouped_sessions_dump="$(dump_grouped_sessions)"
	get_grouped_sessions "$grouped_sessions_dump"
	if [ -n "$grouped_sessions_dump" ]; then
		echo "$grouped_sessions_dump"
	fi
}

# translates pane pid to process command running inside a pane
dump_panes() {
	local full_command
	dump_panes_raw |
		while IFS=$d read line_type session_name window_number window_name window_active window_flags pane_index dir pane_active pane_command pane_pid history_size; do
			# not saving panes from grouped sessions
			if is_session_grouped "$session_name"; then
				continue
			fi
			full_command="$(pane_full_command $pane_pid)"
			echo "${line_type}${d}${session_name}${d}${window_number}${d}${window_name}${d}${window_active}${d}${window_flags}${d}${pane_index}${d}${dir}${d}${pane_active}${d}${pane_command}${d}:${full_command}"
		done
}

dump_windows() {
	dump_windows_raw |
		while IFS=$d read line_type session_name window_index window_active window_flags window_layout; do
			# not saving windows from grouped sessions
			if is_session_grouped "$session_name"; then
				continue
			fi
			# window_layout is not correct for zoomed windows
			if [[ "$window_flags" == *Z* ]]; then
				# unmaximize the window
				toggle_window_zoom "${session_name}:${window_index}"
				# get correct window layout
				window_layout="$(tmux display-message -p -t "${session_name}:${window_index}" -F "#{window_layout}")"
				# maximize window again
				toggle_window_zoom "${session_name}:${window_index}"
			fi
			echo "${line_type}${d}${session_name}${d}${window_index}${d}${window_active}${d}${window_flags}${d}${window_layout}"
		done
}

dump_state() {
	tmux display-message -p "$(state_format)"
}

dump_pane_contents() {
	local pane_contents_area="$(get_tmux_option "$pane_contents_area_option" "$default_pane_contents_area")"
	dump_panes_raw |
		while IFS=$d read line_type session_name window_number window_name window_active window_flags pane_index dir pane_active pane_command pane_pid history_size; do
			capture_pane_contents "${session_name}:${window_number}.${pane_index}" "$history_size" "$pane_contents_area"
		done
}

dump_bash_history() {
	dump_panes |
		while IFS=$d read line_type session_name window_number window_name window_active window_flags pane_index dir pane_active pane_command full_command; do
			save_shell_history "$session_name:$window_number.$pane_index" "$pane_command" "$full_command"
		done
}

save_all() {
	local resurrect_file_path="$(resurrect_file_path)"
	mkdir -p "$(resurrect_dir)"
	fetch_and_dump_grouped_sessions > "$resurrect_file_path"
	dump_panes   >> "$resurrect_file_path"
	dump_windows >> "$resurrect_file_path"
	dump_state   >> "$resurrect_file_path"
	ln -fs "$(basename "$resurrect_file_path")" "$(last_resurrect_file)"
	if capture_pane_contents_option_on; then
		mkdir -p "$(pane_contents_dir)"
		dump_pane_contents
		pane_contents_create_archive
		pane_content_files_cleanup
	fi
	if save_bash_history_option_on; then
		dump_bash_history
	fi
}

show_output() {
	[ "$SCRIPT_OUTPUT" != "quiet" ]
}

main() {
	if supported_tmux_version_ok; then
		if show_output; then
			start_spinner "Saving..." "Tmux environment saved!"
		fi
		save_all
		if show_output; then
			stop_spinner
			display_message "Tmux environment saved!"
		fi
	fi
}
main
