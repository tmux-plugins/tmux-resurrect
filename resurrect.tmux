#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/variables.sh"
source "$CURRENT_DIR/scripts/helpers.sh"

set_save_bindings() {
	local should_confirm_save=$(get_tmux_option "$confirm_save_option" "$default_confirm_save")
	local run_save_script="run-shell \"$CURRENT_DIR/scripts/save.sh\""
	local command
	if [ "$should_confirm_save" == "on" ]; then
		command="confirm-before -y -p \"$confirm_save_prompt\" \"$run_save_script\""
	else
		command="$run_save_script"
	fi

	local key_bindings=$(get_tmux_option "$save_option" "$default_save_key")
	local key
	for key in $key_bindings; do
		tmux unbind "$key"
		tmux bind-key "$key" "$command"
	done
}

set_restore_bindings() {
	local should_confirm_restore=$(get_tmux_option "$confirm_restore_option" "$default_confirm_restore")
	local run_restore_script="run-shell \"$CURRENT_DIR/scripts/restore.sh\""
	local command
	if [ "$should_confirm_restore" == "on" ]; then
		command="confirm-before -y -p \"$confirm_restore_prompt\" \"$run_restore_script\""
	else
		command="$run_restore_script"
	fi

	local key_bindings=$(get_tmux_option "$restore_option" "$default_restore_key")
	local key
	for key in $key_bindings; do
		tmux unbind "$key"
		tmux bind-key "$key" "$command"
	done
}

set_default_strategies() {
	tmux set-option -gq "${restore_process_strategy_option}irb" "default_strategy"
	tmux set-option -gq "${restore_process_strategy_option}mosh-client" "default_strategy"
}

set_script_path_options() {
	tmux set-option -gq "$save_path_option" "$CURRENT_DIR/scripts/save.sh"
	tmux set-option -gq "$restore_path_option" "$CURRENT_DIR/scripts/restore.sh"
}

main() {
	set_save_bindings
	set_restore_bindings
	set_default_strategies
	set_script_path_options
}
main
