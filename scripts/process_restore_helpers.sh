# default processes that are restored
default_proc_list_option="@session-saver-default-processes"
default_proc_list="vim emacs man less more tail top htop irssi"

# User defined processes that are restored
#  'false' - nothing is restored
#  ':all:' - all processes are restored
#
# user defined list of programs that are restored:
#  'my_program foo another_program'
restore_processes_option="@session-saver-processes"
restore_processes=""

restore_pane_processes_enabled() {
	local restore_processes="$(get_tmux_option "$restore_processes_option" "$restore_processes")"
	if [ $restore_processes == "false" ]; then
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
	if _process_should_be_restored "$pane_full_command"; then
		tmux switch-client -t "${session_name}:${window_number}"
		tmux select-pane -t "$pane_index"
		tmux send-keys "$pane_full_command" "C-m"
	fi
}

_process_should_be_restored() {
	local pane_full_command="$1"
	if _restore_all_processes; then
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
	local restore_list="$(_restore_list)"
	local proc
	for proc in $restore_list; do
		if [[ "$pane_full_command" =~ (^$proc) ]]; then
			return 0
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
