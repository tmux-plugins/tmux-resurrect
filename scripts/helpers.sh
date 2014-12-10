default_resurrect_dir="$HOME/.tmux/resurrect"
resurrect_dir_option="@resurrect-dir"

SUPPORTED_VERSION="1.9"

# helper functions
get_tmux_option() {
	local option="$1"
	local default_value="$2"
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

# Ensures a message is displayed for 5 seconds in tmux prompt.
# Does not override the 'display-time' tmux option.
display_message() {
	local message="$1"

	# display_duration defaults to 5 seconds, if not passed as an argument
	if [ "$#" -eq 2 ]; then
		local display_duration="$2"
	else
		local display_duration="5000"
	fi

	# saves user-set 'display-time' option
	local saved_display_time=$(get_tmux_option "display-time" "750")

	# sets message display time to 5 seconds
	tmux set-option -gq display-time "$display_duration"

	# displays message
	tmux display-message "$message"

	# restores original 'display-time' value
	tmux set-option -gq display-time "$saved_display_time"
}


supported_tmux_version_ok() {
	$CURRENT_DIR/check_tmux_version.sh "$SUPPORTED_VERSION"
}

remove_first_char() {
	echo "$1" | cut -c2-
}

save_bash_history_option_on() {
	local option="$(get_tmux_option "$bash_history_option" "off")"
	[ "$option" == "on" ]
}

save_tmux_buffers_option_on() {
	local option="$(get_tmux_option "$save_tmux_buffers_option" "off")"
	[ "$option" == "on" ]
}

# path helpers

resurrect_dir() {
	echo $(get_tmux_option "$resurrect_dir_option" "$default_resurrect_dir")
}

resurrect_file_path() {
	local timestamp="$(date +"%Y-%m-%dT%H:%M:%S")"
	echo "$(resurrect_dir)/tmux_resurrect_${timestamp}.txt"
}

last_resurrect_file() {
	echo "$(resurrect_dir)/last"
}

resurrect_history_file() {
	local pane_id="$1"
	echo "$(resurrect_dir)/bash_history-${pane_id}"
}

resurrect_buffer_file() {
	local pane_id="$1"
	echo "$(resurrect_dir)/tmux_buffer-${pane_id}"
}

restore_zoomed_windows() {
	awk 'BEGIN { FS="\t"; OFS="\t" } /^pane/ && $6 ~ /Z/ && $9 == 1 { print $2, $3; }' $(last_resurrect_file) |
		while IFS=$'\t' read session_name window_number; do
			tmux resize-pane -t "${session_name}:${window_number}" -Z
		done
}
