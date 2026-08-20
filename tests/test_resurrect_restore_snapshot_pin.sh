#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $CURRENT_DIR/helpers/helpers.sh
setup_before_restore() {
	mkdir -p ~/.tmux/resurrect/
	cp tests/fixtures/restore_file.txt "${HOME}/.tmux/resurrect/restore_file.txt"
	touch "${HOME}/.tmux/resurrect/replacement.txt"
	ln -sf restore_file.txt "${HOME}/.tmux/resurrect/last"
	cat > "${HOME}/switch-last-resurrect-file.sh" <<-HERE
	#!/usr/bin/env bash
	touch "${HOME}/restore-hook-ran"
	ln -sf replacement.txt "${HOME}/.tmux/resurrect/last"
	HERE
	chmod +x "${HOME}/switch-last-resurrect-file.sh"

	mkdir -p /tmp/bar
}

main() {
	setup_before_restore
	TMUX="" tmux new-session -d -s initial
	export TMUX="$(tmux display-message -p '#{socket_path},#{pid},0')"
	tmux set-option -g @resurrect-dir "${HOME}/.tmux/resurrect"
	tmux set-option -g @resurrect-hook-pre-restore-all "${HOME}/switch-last-resurrect-file.sh"
	"${CURRENT_DIR}/../scripts/restore.sh"

	if [ ! -f "${HOME}/restore-hook-ran" ]; then
		fail_helper "Pre-restore hook did not run"
	fi
	if ! tmux has-session -t blue 2>/dev/null; then
		fail_helper "Restore followed a changed last symlink"
	fi
	exit_helper
}
main
