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
	local command
	if _process_should_be_restored "$pane_full_command" "$session_name" "$window_number" "$pane_index"; then
		tmux switch-client -t "${session_name}:${window_number}"
		tmux select-pane -t "$pane_index"

		local inline_strategy="$(_get_inline_strategy "$pane_full_command")" # might not be defined
		if [ -n "$inline_strategy" ]; then
			# inline strategy exists
			# check for additional "expansion" of inline strategy, e.g. `vim` to `vim -S`
			if _strategy_exists "$inline_strategy"; then
				local strategy_file="$(_get_strategy_file "$inline_strategy")"
				local inline_strategy="$($strategy_file "$pane_full_command" "$dir")"
			fi
			command="$inline_strategy"
		elif _strategy_exists "$pane_full_command"; then
			local strategy_file="$(_get_strategy_file "$pane_full_command")"
			local strategy_command="$($strategy_file "$pane_full_command" "$dir")"
			command="$strategy_command"
		else
			# just invoke the raw command
			command="$pane_full_command"
		fi
		tmux send-keys -t "${session_name}:${window_number}.${pane_index}" "$command" "C-m"
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
	elif ! pane_exists "$session_name" "$window_number" "$pane_index"; then
		# pane number limit exceeded, pane does not exist
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
	if [ "$restore_processes" == ":all:" ]; then
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
	local match
	for proc in "$@"; do
		match="$(_get_proc_match_element "$proc")"
		if _proc_matches_full_command "$pane_full_command" "$match"; then
			return 0
		fi
	done
	return 1
}

_proc_matches_full_command() {
	local pane_full_command="$1"
	local match="$2"
	if _proc_starts_with_tildae "$match"; then
		match="$(remove_first_char "$match")"
		# regex matching the command makes sure `$match` string is somewhere in the command string
		if [[ "$pane_full_command" =~ ($match) ]]; then
			return 0
		fi
	else
		# regex matching the command makes sure process is a "word"
		if [[ "$pane_full_command" =~ (^${match} ) ]] || [[ "$pane_full_command" =~ (^${match}$) ]]; then
			return 0
		fi
	fi
	return 1
}

_get_proc_match_element() {
	echo "$1" | sed "s/${inline_strategy_token}.*//"
}

_get_proc_restore_element() {
	echo "$1" | sed "s/.*${inline_strategy_token}//"
}

# given full command: 'ruby /Users/john/bin/my_program arg1 arg2'
# and inline strategy: '~bin/my_program->my_program *'
# returns: 'arg1 arg2'
_get_command_arguments() {
	local pane_full_command="$1"
	local match="$2"
	if _proc_starts_with_tildae "$match"; then
		match="$(remove_first_char "$match")"
	fi
	echo "$pane_full_command" | sed "s,^.*${match}[^ ]* ,,"
}

_get_proc_restore_command() {
	local pane_full_command="$1"
	local proc="$2"
	local match="$3"
	local restore_element="$(_get_proc_restore_element "$proc")"
	if [[ "$restore_element" =~ " ${inline_strategy_arguments_token}" ]]; then
		# replaces "%" with command arguments
		local command_arguments="$(_get_command_arguments "$pane_full_command" "$match")"
		echo "$restore_element" | sed "s/${inline_strategy_arguments_token}/${command_arguments}/"
	else
		echo "$restore_element"
	fi
}

_restore_list() {
	local user_processes="$(get_tmux_option "$restore_processes_option" "$restore_processes")"
	local default_processes="$(get_tmux_option "$default_proc_list_option" "$default_proc_list")"
	if [ -z "$user_processes" ]; then
		# user didn't define any processes
		echo "$default_processes"
	else
		echo "$default_processes $user_processes"
	fi
}

_proc_starts_with_tildae() {
	[[ "$1" =~ (^~) ]]
}

_get_inline_strategy() {
	local pane_full_command="$1"
	# TODO: make this work without eval
	eval set $(_restore_list)
	local proc
	local match
	for proc in "$@"; do
		if [[ "$proc" =~ "$inline_strategy_token" ]]; then
			match="$(_get_proc_match_element "$proc")"
			if _proc_matches_full_command "$pane_full_command" "$match"; then
				echo "$(_get_proc_restore_command "$pane_full_command" "$proc" "$match")"
			fi
		fi
	done
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
