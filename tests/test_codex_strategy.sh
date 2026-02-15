#!/usr/bin/env bash

# Tests for Codex CLI session restore support:
#   - codex_session.sh strategy script behavior
#   - codex in default_proc_list (variables.sh)
#   - codex strategy registration (resurrect.tmux)

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$CURRENT_DIR/.."
STRATEGY="$ROOT_DIR/strategies/codex_session.sh"
VARIABLES="$ROOT_DIR/scripts/variables.sh"
RESURRECT_TMUX="$ROOT_DIR/resurrect.tmux"

pass_count=0
fail_count=0

pass() {
	local desc="$1"
	echo "  PASS: $desc"
	((pass_count++))
}

fail() {
	local desc="$1"
	local detail="$2"
	echo "  FAIL: $desc"
	echo "        $detail"
	((fail_count++))
}

assert_strategy_output() {
	local desc="$1"
	local input_command="$2"
	local input_dir="$3"
	local expected="$4"
	local actual
	actual="$($STRATEGY "$input_command" "$input_dir")"
	if [ "$actual" = "$expected" ]; then
		pass "$desc"
	else
		fail "$desc" "expected '$expected', got '$actual'"
	fi
}

# ---------- Strategy script tests ----------

echo "Strategy: codex_session.sh"

assert_strategy_output \
	"plain 'codex' restores with resume --last" \
	"codex" "/some/dir" \
	"codex resume --last"

assert_strategy_output \
	"'codex' with a prompt restores with resume --last" \
	"codex fix the bug" "/some/dir" \
	"codex resume --last"

assert_strategy_output \
	"'codex resume' is returned as-is" \
	"codex resume" "/some/dir" \
	"codex resume"

assert_strategy_output \
	"'codex resume --last' is returned as-is" \
	"codex resume --last" "/some/dir" \
	"codex resume --last"

assert_strategy_output \
	"'codex resume <id>' is preserved" \
	"codex resume abc123" "/some/dir" \
	"codex resume abc123"

assert_strategy_output \
	"'codex fork <id>' is preserved" \
	"codex fork abc123" "/some/dir" \
	"codex fork abc123"

assert_strategy_output \
	"'codex --model gpt-5' restores with resume --last" \
	"codex --model gpt-5" "/some/dir" \
	"codex resume --last"

assert_strategy_output \
	"'codex --full-auto' restores with resume --last" \
	"codex --full-auto fix everything" "/some/dir" \
	"codex resume --last"

assert_strategy_output \
	"'codex resume' with flags is preserved" \
	"codex resume --last --all" "/some/dir" \
	"codex resume --last --all"

# ---------- Wiring tests ----------

echo ""
echo "Wiring: variables.sh"

if grep -q "'.*codex.*'" "$VARIABLES"; then
	pass "codex is in default_proc_list"
else
	fail "codex is in default_proc_list" "not found in $VARIABLES"
fi

echo ""
echo "Wiring: resurrect.tmux"

if grep -q 'codex.*"session"' "$RESURRECT_TMUX"; then
	pass "codex strategy registered as 'session'"
else
	fail "codex strategy registered as 'session'" "not found in $RESURRECT_TMUX"
fi

# ---------- Strategy file sanity ----------

echo ""
echo "Sanity: strategy file"

if [ -x "$STRATEGY" ]; then
	pass "codex_session.sh is executable"
else
	fail "codex_session.sh is executable" "file is not executable"
fi

# ---------- Summary ----------

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed, $fail_count failed"

if [ "$fail_count" -gt 0 ]; then
	exit 1
fi
