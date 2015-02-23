#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $CURRENT_DIR/helpers/helpers.sh
source $CURRENT_DIR/helpers/resurrect_helpers.sh

setup_before_restore() {
	# setup restore file
	mkdir -p ~/.tmux/resurrect/
	cp tests/fixtures/restore_file.txt "${HOME}/.tmux/resurrect/restore_file.txt"
	ln -sf restore_file.txt "${HOME}/.tmux/resurrect/last"

	# directory used in restored tmux session
	mkdir -p /tmp/bar
}

restore_tmux_environment_and_save_again() {
	set_screen_dimensions_helper
	$CURRENT_DIR/helpers/restore_and_save_tmux_test_environment.exp
}

main() {
	install_tmux_plugin_under_test_helper
	setup_before_restore
	restore_tmux_environment_and_save_again

	if last_save_file_differs_helper "tests/fixtures/restore_file.txt"; then
		fail_helper "Saved file not correct after restore"
	fi
	exit_helper
}
main
