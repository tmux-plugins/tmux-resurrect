#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"

pane_format() {
	local delimiter=$'\t'
	local format
	format+="pane"
	format+="${delimiter}"
	format+="#{session_name}"
	format+="${delimiter}"
	format+="#{window_index}"
	format+="${delimiter}"
	format+="#{window_name}"
	format+="${delimiter}"
	format+="#{pane_current_path}"
	echo "$format"
}

state_format() {
	local delimiter=$'\t'
	local format
	format+="state"
	format+="${delimiter}"
	format+="#{client_session}"
	format+="${delimiter}"
	format+="#{client_last_session}"
	echo "$format"
}

dump_panes() {
	tmux list-panes -a -F "$(pane_format)"
}

dump_state() {
	tmux display-message -p "$(state_format)"
}

save_all_sessions() {
	local session_path="$(session_path)"
	mkdir -p "$(sessions_dir)"
	dump_panes >  $session_path
	dump_state >> $session_path
	ln -fs "$session_path" "$(last_session_path)"
	display_message "Saved all Tmux sessions!"
}

main() {
	if supported_tmux_version_ok; then
		save_all_sessions
	fi
}
main
