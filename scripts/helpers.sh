if [ -d "$HOME/.tmux/resurrect" ]; then
        default_resurrect_dir="$HOME/.tmux/resurrect"
else
        default_resurrect_dir="${XDG_DATA_HOME:-$HOME/.local/share}"/tmux/resurrect
fi
resurrect_dir_option="@resurrect-dir"

SUPPORTED_VERSION="1.9"
RESURRECT_FILE_PREFIX="tmux_resurrect"
RESURRECT_FILE_EXTENSION="txt"
_RESURRECT_DIR=""
_RESURRECT_FILE_PATH=""

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
	echo "${1:1}"
}

capture_pane_contents_option_on() {
	local option="$(get_tmux_option "$pane_contents_option" "off")"
	[ "$option" == "on" ]
}

files_differ() {
	! cmp -s "$1" "$2"
}

get_grouped_sessions() {
	local grouped_sessions_dump="$1"
	export GROUPED_SESSIONS="${d}$(echo "$grouped_sessions_dump" | cut -f2 -d"$d" | tr "\\n" "$d")"
}

# batched tmux commands
#
# starting a tmux client per command makes big saves and restores slow
# tmux_batch_add queues commands to send to the server in chunks,
# as one command sequence: "cmd1 \; cmd2"

TMUX_BATCH_ARGS=()
TMUX_BATCH_COUNT=0
TMUX_BATCH_BYTES=0
TMUX_BATCH_OUTPUT=""
# tmux refuses commands longer than about 16 kB, stay well below that
TMUX_BATCH_MAX_COUNT=100
TMUX_BATCH_MAX_BYTES=8000

tmux_batch_add() {
	local arg
	if [ "$TMUX_BATCH_COUNT" -gt 0 ]; then
		TMUX_BATCH_ARGS+=(";")
	fi
	for arg in "$@"; do
		# tmux takes a trailing ';' as a command separator, escape it
		if [[ "$arg" == *";" ]]; then
			arg="${arg%;}\\;"
		fi
		TMUX_BATCH_ARGS+=("$arg")
		TMUX_BATCH_BYTES=$((TMUX_BATCH_BYTES + ${#arg} + 1))
	done
	TMUX_BATCH_COUNT=$((TMUX_BATCH_COUNT + 1))
}

_tmux_batch_reset() {
	TMUX_BATCH_ARGS=()
	TMUX_BATCH_COUNT=0
	TMUX_BATCH_BYTES=0
}

# Runs the queued commands once, output is stored in TMUX_BATCH_OUTPUT.
# tmux stops a command sequence at the first failing command.
tmux_batch_run() {
	TMUX_BATCH_OUTPUT=""
	if [ "$TMUX_BATCH_COUNT" -gt 0 ]; then
		TMUX_BATCH_OUTPUT="$(tmux "${TMUX_BATCH_ARGS[@]}" 2>/dev/null)"
	fi
	_tmux_batch_reset
}

# queue commands that are safe to run twice, flush when the queue gets big
# if a chunk fails, rerun its commands one by one so a single failure
# doesn't skip the rest
tmux_batch_queue() {
	tmux_batch_add "$@"
	if [ "$TMUX_BATCH_COUNT" -ge "$TMUX_BATCH_MAX_COUNT" ] ||
		[ "$TMUX_BATCH_BYTES" -ge "$TMUX_BATCH_MAX_BYTES" ]; then
		tmux_batch_flush
	fi
}

tmux_batch_flush() {
	if [ "$TMUX_BATCH_COUNT" -gt 0 ] &&
		! tmux "${TMUX_BATCH_ARGS[@]}" >/dev/null 2>&1; then
		local arg
		local -a command=()
		for arg in "${TMUX_BATCH_ARGS[@]}" ";"; do
			if [ "$arg" == ";" ]; then
				tmux "${command[@]}" >/dev/null 2>&1
				command=()
			else
				command+=("$arg")
			fi
		done
	fi
	_tmux_batch_reset
}

# pane content file helpers

pane_contents_create_archive() {
	tar cf - -C "$(resurrect_dir)/save/" ./pane_contents/ |
		gzip > "$(pane_contents_archive_file)"
}

pane_content_files_restore_from_archive() {
	local archive_file="$(pane_contents_archive_file)"
	if [ -f "$archive_file" ]; then
		mkdir -p "$(pane_contents_dir "restore")"
		gzip -d < "$archive_file" |
			tar xf - -C "$(resurrect_dir)/restore/"
	fi
}

# path helpers

resurrect_dir() {
	if [ -z "$_RESURRECT_DIR" ]; then
		local path="$(get_tmux_option "$resurrect_dir_option" "$default_resurrect_dir")"
		# expands tilde, $HOME and $HOSTNAME if used in @resurrect-dir
		echo "$path" | sed "s,\$HOME,$HOME,g; s,\$HOSTNAME,$(hostname),g; s,\~,$HOME,g"
	else
		echo "$_RESURRECT_DIR"
	fi
}
_RESURRECT_DIR="$(resurrect_dir)"

resurrect_file_path() {
	if [ -z "$_RESURRECT_FILE_PATH" ]; then
		local timestamp="$(date +"%Y%m%dT%H%M%S")"
		echo "$(resurrect_dir)/${RESURRECT_FILE_PREFIX}_${timestamp}.${RESURRECT_FILE_EXTENSION}"
	else
		echo "$_RESURRECT_FILE_PATH"
	fi
}
_RESURRECT_FILE_PATH="$(resurrect_file_path)"

last_resurrect_file() {
	echo "$(resurrect_dir)/last"
}

pane_contents_dir() {
	echo "${_RESURRECT_DIR:-$(resurrect_dir)}/$1/pane_contents/"
}

pane_contents_archive_file() {
	echo "$(resurrect_dir)/pane_contents.tar.gz"
}

execute_hook() {
	local kind="$1"
	shift
	local args="" hook=""

	hook=$(get_tmux_option "$hook_prefix$kind" "")

	# If there are any args, pass them to the hook (in a way that preserves/copes
	# with spaces and unusual characters.
	if [ "$#" -gt 0 ]; then
		printf -v args "%q " "$@"
	fi

	if [ -n "$hook" ]; then
		eval "$hook $args"
	fi
}
