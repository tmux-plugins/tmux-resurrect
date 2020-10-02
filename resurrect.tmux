#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/variables.sh"
source "$CURRENT_DIR/scripts/helpers.sh"

set_save_bindings() {
	local key_bindings=$(get_tmux_option "$save_option" "$default_save_key")
	local key
	for key in $key_bindings; do
		tmux bind-key "$key" run-shell "$CURRENT_DIR/scripts/save.sh"
	done
}

set_restore_bindings() {
	local key_bindings=$(get_tmux_option "$restore_option" "$default_restore_key")
	local key
	for key in $key_bindings; do
		tmux bind-key "$key" run-shell "$CURRENT_DIR/scripts/restore.sh"
	done
}

set_list_resurrect_sessions_bindings() {
  local key_binding=$(get_tmux_option "$list_resurrect_sessions_option" "$default_list_resurrect_sessions_key")
  local key
  for key in $key_binding; do
    tmux bind-key "$key" run-shell "$CURRENT_DIR/scripts/list_resurrect_sessions.sh"
  done
}

set_default_strategies() {
	tmux set-option -gq "${restore_process_strategy_option}irb" "default_strategy"
	tmux set-option -gq "${restore_process_strategy_option}mosh-client" "default_strategy"
}

set_script_path_options() {
	tmux set-option -gq "$save_path_option" "$CURRENT_DIR/scripts/save.sh"
	tmux set-option -gq "$restore_path_option" "$CURRENT_DIR/scripts/restore.sh"
  tmux set-option -gq "$list_resurrect_sessions_option" "$CURRENT_DIR/scripts/list_resurrect_sessions.sh"
}

main() {
	set_save_bindings
	set_restore_bindings
  set_list_resurrect_sessions_bindings
	set_default_strategies
	set_script_path_options
}
main
