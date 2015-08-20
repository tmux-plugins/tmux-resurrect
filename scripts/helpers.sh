default_resurrect_dir="$HOME/.tmux/resurrect"
resurrect_dir_option="@resurrect-dir"

SUPPORTED_VERSION="1.9"

d=$'\t'

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

capture_pane_contents_option_on() {
	local option="$(get_tmux_option "$pane_contents_option" "off")"
	[ "$option" == "on" ]
}

save_bash_history_option_on() {
	local option="$(get_tmux_option "$bash_history_option" "off")"
	[ "$option" == "on" ]
}

get_grouped_sessions() {
	local grouped_sessions_dump="$1"
	export GROUPED_SESSIONS="${d}$(echo "$grouped_sessions_dump" | cut -f2 -d"$d" | tr "\\n" "$d")"
}

is_session_grouped() {
	local session_name="$1"
	[[ "$GROUPED_SESSIONS" == *"${d}${session_name}${d}"* ]]
}

# pane content file helpers

pane_contents_create_archive() {
	tar cf - -C "$(resurrect_dir)" ./pane_contents/ |
		gzip > "$(pane_contents_archive_file)"
}

pane_content_files_restore_from_archive() {
	local archive_file="$(pane_contents_archive_file)"
	if [ -f "$archive_file" ]; then
		gzip -d < "$archive_file" |
			tar xf - -C "$(resurrect_dir)"
	fi
}

pane_content_files_cleanup() {
	rm "$(pane_contents_dir)"/*
}

# path helpers

resurrect_dir() {
	local path="$(get_tmux_option "$resurrect_dir_option" "$default_resurrect_dir")"
	echo "${path/#\~/$HOME}" # expands tilde if used with @resurrect-dir
}

resurrect_file_path() {
	local timestamp="$(date +"%Y-%m-%dT%H:%M:%S")"
	echo "$(resurrect_dir)/tmux_resurrect_${timestamp}.txt"
}

last_resurrect_file() {
	echo "$(resurrect_dir)/last"
}

pane_contents_dir() {
	echo "$(resurrect_dir)/pane_contents/"
}

pane_contents_file() {
	local pane_id="$1"
	echo "$(pane_contents_dir)/pane-${pane_id}"
}

pane_contents_file_exists() {
	local pane_id="$1"
	[ -f "$(pane_contents_file "$pane_id")" ]
}

pane_contents_archive_file() {
	echo "$(resurrect_dir)/pane_contents.tar.gz"
}

resurrect_history_file() {
	local pane_id="$1"
	echo "$(resurrect_dir)/bash_history-${pane_id}"
}
