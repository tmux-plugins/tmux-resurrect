#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $CURRENT_DIR/helpers/helpers.sh
source $CURRENT_DIR/helpers/resurrect_helpers.sh

create_tmux_test_environment_and_save() {
	set_tmux_conf_helper<<-HERE
	run-shell '~/.tmux/plugins/tmux-resurrect/resurrect.tmux'
	HERE

	set_screen_dimensions
	$CURRENT_DIR/helpers/create_and_save_tmux_test_environment.exp
}

last_save_file_incorrect() {
	diff tests/fixtures/save_file.txt "${HOME}/.tmux/resurrect/last"
	[ $? -ne 0 ]
}

main() {
	install_tmux_resurrect_helper
	create_tmux_test_environment_and_save
	if last_save_file_incorrect; then
		fail_helper "Saved file not correct"
		exit_helper
	fi
	exit_helper
}
main
