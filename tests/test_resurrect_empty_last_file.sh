#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$CURRENT_DIR/.." && pwd )"

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tmux-resurrect-empty.XXXXXX")"
TEMP_HOME="$TEMP_DIR/home"
FAKE_BIN="$TEMP_DIR/bin"
TMUX_LOG="$TEMP_DIR/tmux.log"
SCRIPT_OUTPUT="$TEMP_DIR/restore.out"

cleanup() {
	rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

fail() {
	echo "$1"
	echo "tmux log:"
	cat "$TMUX_LOG" 2>/dev/null || true
	echo "script output:"
	cat "$SCRIPT_OUTPUT" 2>/dev/null || true
	exit 1
}

setup_empty_last_file() {
	mkdir -p "$TEMP_HOME/.tmux/resurrect"
	: > "$TEMP_HOME/.tmux/resurrect/empty.txt"
	ln -sf empty.txt "$TEMP_HOME/.tmux/resurrect/last"
}

setup_fake_tmux() {
	mkdir -p "$FAKE_BIN"
	cat > "$FAKE_BIN/tmux" <<'EOF'
#!/usr/bin/env bash

printf '%s\n' "$*" >> "$TMUX_LOG"

if [ "$1" = "-V" ]; then
	echo "tmux 3.7"
	exit 0
fi

exit 0
EOF
	chmod +x "$FAKE_BIN/tmux"
}

run_restore() {
	HOME="$TEMP_HOME" \
		PATH="$FAKE_BIN:$PATH" \
		TMUX_LOG="$TMUX_LOG" \
		bash "$ROOT_DIR/scripts/restore.sh" > "$SCRIPT_OUTPUT" 2>&1
}

main() {
	setup_empty_last_file
	setup_fake_tmux

	if ! run_restore; then
		fail "Restore failed for empty resurrect file"
	fi

	local resurrect_file="$TEMP_HOME/.tmux/resurrect/last"
	local expected_message="display-message Tmux resurrect file is empty: $resurrect_file"
	if ! grep -Fq "$expected_message" "$TMUX_LOG"; then
		fail "Expected empty resurrect file message was not displayed"
	fi

	if grep -Eq '(^| )list-panes|(^| )kill-(pane|session|server)' "$TMUX_LOG"; then
		fail "Restore continued after detecting an empty resurrect file"
	fi
}
main
