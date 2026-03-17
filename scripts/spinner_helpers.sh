start_spinner() {
	if is_popup_output; then
		return
	fi
	$CURRENT_DIR/tmux_spinner.sh "$1" "$2" &
	export SPINNER_PID=$!
}

stop_spinner() {
	if is_popup_output; then
		return
	fi
	kill $SPINNER_PID
}

spinner_wave_label() {
	local message="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

	case "$message" in
		"saving..."|"restoring...")
			echo "$message"
			;;
		*)
			echo ""
			;;
	esac
}

spinner_wave_message() {
	local message="$1"
	local frame="$2"
	local rendered=""
	local message_length="${#message}"
	local index=0
	local char=""

	if [ -z "$message" ]; then
		return
	fi

	while [ "$index" -lt "${#message}" ]; do
		char="${message:$index:1}"
		if [ "$char" = " " ]; then
			rendered="${rendered}${char}"
		else
			local color="$(spinner_wave_color "$frame" "$index" "$message_length")"
			rendered="${rendered}#[fg=colour${color}]${char}"
		fi
		index=$((index + 1))
	done

	printf '%s#[default]' "$rendered"
}

spinner_wave_color() {
	local frame="$1"
	local index="$2"
	local message_length="$3"
	local min_color=240
	local max_color=253
	local gradient_width=5
	local pause_frames=10
	local half_width=$((gradient_width / 2))
	local pass_frames=$((message_length + gradient_width))
	local cycle_frames=$((pass_frames + pause_frames))
	local active_frame=0
	local center=0
	local distance=0

	if [ -z "$message_length" ] || [ "$message_length" -le 0 ]; then
		echo "$max_color"
		return
	fi

	active_frame=$((frame % cycle_frames))
	if [ "$active_frame" -ge "$pass_frames" ]; then
		echo "$max_color"
		return
	fi

	center=$((active_frame - half_width))
	distance=$((index - center))
	if [ "$distance" -lt 0 ]; then
		distance=$(( -distance ))
	fi

	if [ "$distance" -gt "$half_width" ]; then
		echo "$max_color"
		return
	fi

	echo $((min_color + (distance * (max_color - min_color) / half_width)))
}
