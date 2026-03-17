#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"

action="$1"
script_path=""
title=""

case "$action" in
	save)
		script_path="$CURRENT_DIR/save.sh"
		title="tmux-resurrect save"
		;;
	restore)
		script_path="$CURRENT_DIR/restore.sh"
		title="tmux-resurrect restore"
		;;
	*)
		exit 1
		;;
esac

run_command() {
	"$script_path"
}

run_popup() {
	local popup_width="$(get_tmux_option "$popup_width_option" "$default_popup_width")"
	local popup_height="$(get_tmux_option "$popup_height_option" "$default_popup_height")"
	local popup_command="$(shell_quote "$script_path") popup"

	tmux display-popup -T "$title" -w "$popup_width" -h "$popup_height" -E "$popup_command"
}

main() {
	if should_use_popup; then
		run_popup
	else
		run_command
	fi
}
main
