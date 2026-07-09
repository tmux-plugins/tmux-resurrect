#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$CURRENT_DIR/.." && pwd )"

fail_unit_test() {
	local message="$1"
	if command -v fail_helper >/dev/null 2>&1; then
		fail_helper "$message"
	else
		printf '%s\n' "$message" >&2
		exit 1
	fi
}

make_temp_dir() {
	mktemp -d "${TMPDIR:-/tmp}/tmux-resurrect-test.XXXXXX"
}

pane_creation_command_removes_restored_file_after_cat() {
	local tmp_dir actual expected pane_file
	tmp_dir="$(make_temp_dir)" || fail_unit_test "Could not create temp dir"
	actual="$(
		tmux() { return 1; }
		source "$PROJECT_DIR/scripts/restore.sh"
		_RESURRECT_DIR="$tmp_dir"
		TMUX_DEFAULT_COMMAND="/bin/sh"
		pane_creation_command "session" "1" "2"
	)"
	pane_file="$tmp_dir/restore/pane_contents//pane-session:1.2"
	expected="cat '$pane_file'; rm -f '$pane_file'; exec /bin/sh"
	rm -rf "$tmp_dir"
	if [ "$actual" != "$expected" ]; then
		fail_unit_test "Pane creation command does not remove its content file"
	fi
}

pane_content_files_restore_from_archive_clears_stale_files_before_extract() {
	local tmp_dir status
	tmp_dir="$(make_temp_dir)" || fail_unit_test "Could not create temp dir"
	(
		tmux() { return 1; }
		source "$PROJECT_DIR/scripts/helpers.sh"
		_RESURRECT_DIR="$tmp_dir"
		mkdir -p "$tmp_dir/save/pane_contents" "$tmp_dir/restore/pane_contents"
		printf 'saved\n' > "$tmp_dir/save/pane_contents/pane-current"
		printf 'stale\n' > "$tmp_dir/restore/pane_contents/pane-stale"
		pane_contents_create_archive
		pane_content_files_restore_from_archive
		[ -f "$tmp_dir/restore/pane_contents/pane-current" ] || exit 10
		[ ! -e "$tmp_dir/restore/pane_contents/pane-stale" ] || exit 11
	)
	status="$?"
	rm -rf "$tmp_dir"
	if [ "$status" -eq 10 ]; then
		fail_unit_test "Pane contents archive was not extracted"
	elif [ "$status" -eq 11 ]; then
		fail_unit_test "Stale pane contents were not cleared before extract"
	elif [ "$status" -ne 0 ]; then
		fail_unit_test "Pane contents archive restore test failed"
	fi
}

pane_content_files_restore_from_archive_skips_cleanup_without_archive() {
	local tmp_dir status
	tmp_dir="$(make_temp_dir)" || fail_unit_test "Could not create temp dir"
	(
		tmux() { return 1; }
		source "$PROJECT_DIR/scripts/helpers.sh"
		_RESURRECT_DIR="$tmp_dir"
		mkdir -p "$tmp_dir/restore/pane_contents"
		printf 'stale\n' > "$tmp_dir/restore/pane_contents/pane-stale"
		pane_content_files_restore_from_archive
		[ -f "$tmp_dir/restore/pane_contents/pane-stale" ] || exit 10
	)
	status="$?"
	rm -rf "$tmp_dir"
	if [ "$status" -eq 10 ]; then
		fail_unit_test "Pane contents dir was touched without an archive"
	elif [ "$status" -ne 0 ]; then
		fail_unit_test "Pane contents no-archive restore test failed"
	fi
}

run_pane_contents_unit_tests() {
	pane_creation_command_removes_restored_file_after_cat
	pane_content_files_restore_from_archive_clears_stale_files_before_extract
	pane_content_files_restore_from_archive_skips_cleanup_without_archive
}

if [ "$1" == "--pane-contents-unit-tests" ]; then
	run_pane_contents_unit_tests
	exit 0
fi

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
	run_pane_contents_unit_tests
	install_tmux_plugin_under_test_helper
	setup_before_restore
	restore_tmux_environment_and_save_again

	if last_save_file_differs_helper "tests/fixtures/restore_file.txt"; then
		fail_helper "Saved file not correct after restore"
	fi
	exit_helper
}
main
