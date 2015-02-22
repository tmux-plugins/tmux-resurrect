#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $CURRENT_DIR/helpers/helpers.sh
source $CURRENT_DIR/helpers/resurrect_helpers.sh

create_tmux_test_environment_and_save() {
	set_tmux_conf_helper<<-HERE
	run-shell '~/.tmux/plugins/tmux-resurrect/resurrect.tmux'
	HERE
	set_screen_dimensions_helper
	$CURRENT_DIR/helpers/create_and_save_tmux_test_environment.exp
}

main() {
	install_tmux_resurrect_helper
	mkdir -p /tmp/bar # setup required dirs
	create_tmux_test_environment_and_save

	if last_save_file_differs_helper "tests/fixtures/save_file.txt"; then
		fail_helper "Saved file not correct (initial save)"
	fi
	exit_helper
}
main
