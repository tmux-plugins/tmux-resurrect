restore_pane_processes_enabled() {
	local restore_processes="$(get_tmux_option "$restore_processes_option" "$restore_processes")"
	if [ "$restore_processes" == "false" ]; then
		return 1
	else
		return 0
	fi
}

restore_pane_process() {
	local pane_full_command="$1"
	local session_name="$2"
	local window_number="$3"
	local pane_index="$4"
	local dir="$5"
	if _process_should_be_restored "$pane_full_command" "$session_name" "$window_number" "$pane_index"; then
		tmux switch-client -t "${session_name}:${window_number}"
		tmux select-pane -t "$pane_index"

		if _strategy_exists "$pane_full_command"; then
			local strategy_file="$(_get_strategy_file "$pane_full_command")"
			local strategy_command="$($strategy_file "$pane_full_command" "$dir")"
			tmux send-keys "$strategy_command" "C-m"
		else
			# just invoke the command
			tmux send-keys "$pane_full_command" "C-m"
		fi
	fi
}

# private functions below

_process_should_be_restored() {
	local pane_full_command="$1"
	local session_name="$2"
	local window_number="$3"
	local pane_index="$4"
	if is_pane_registered_as_existing "$session_name" "$window_number" "$pane_index"; then
		# Scenario where pane existed before restoration, so we're not
		# restoring the proces either.
		return 1
	elif _restore_all_processes; then
		return 0
	elif _process_on_the_restore_list "$pane_full_command"; then
		return 0
	else
		return 1
	fi
}

_restore_all_processes() {
	local restore_processes="$(get_tmux_option "$restore_processes_option" "$restore_processes")"
	if [ $restore_processes == ":all:" ]; then
		return 0
	else
		return 1
	fi
}

_process_on_the_restore_list() {
	local pane_full_command="$1"
	# TODO: make this work without eval
	eval set $(_restore_list)
	local proc
	for proc in "$@"; do
		if _proc_starts_with_tildae "$proc"; then
			proc="$(remove_first_char "$proc")"
			# regex matching the command makes sure `$proc` string is somewhere the command string
			if [[ "$pane_full_command" =~ ($proc) ]]; then
				return 0
			fi
		else
			# regex matching the command makes sure process is a "word"
			if [[ "$pane_full_command" =~ (^${proc} ) ]] || [[ "$pane_full_command" =~ (^${proc}$) ]]; then
				return 0
			fi
		fi
	done
	return 1
}

_restore_list() {
	local user_processes="$(get_tmux_option "$restore_processes_option" "$restore_processes")"
	local default_processes="$(get_tmux_option "$default_proc_list_option" "$default_proc_list")"
	if [ -z $user_processes ]; then
		# user didn't define any processes
		echo "$default_processes"
	else
		echo "$default_processes $user_processes"
	fi
}

_proc_starts_with_tildae() {
	[[ "$1" =~ (^~) ]]
}

_strategy_exists() {
	local pane_full_command="$1"
	local strategy="$(_get_command_strategy "$pane_full_command")"
	if [ -n "$strategy" ]; then # strategy set?
		local strategy_file="$(_get_strategy_file "$pane_full_command")"
		[ -e "$strategy_file" ] # strategy file exists?
	else
		return 1
	fi
}

_get_command_strategy() {
	local pane_full_command="$1"
	local command="$(_just_command "$pane_full_command")"
	get_tmux_option "${restore_process_strategy_option}${command}" ""
}

_just_command() {
	echo "$1" | cut -d' ' -f1
}

_get_strategy_file() {
	local pane_full_command="$1"
	local strategy="$(_get_command_strategy "$pane_full_command")"
	local command="$(_just_command "$pane_full_command")"
	echo "$CURRENT_DIR/../strategies/${command}_${strategy}.sh"
}
