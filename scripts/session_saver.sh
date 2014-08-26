#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"

dump_format() {
	local delimiter=$'\t'
	local format
	format+="#{session_name}"
	format+="${delimiter}"
	format+="#{window_index}"
	format+="${delimiter}"
	format+="#{window_name}"
	format+="${delimiter}"
	format+="#{pane_current_path}"
	echo "$format"
}

dump() {
	tmux list-panes -a -F "$(dump_format)"
}

save_all_sessions() {
	mkdir -p $HOME/.tmux
	dump > $HOME/.tmux/session
	display_message "Saved all Tmux sessions!"
}

main() {
	save_all_sessions
}
main
