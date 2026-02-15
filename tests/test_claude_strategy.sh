#!/usr/bin/env bash

# Tests for Claude Code session restore support:
#   - claude_session.sh strategy script behavior
#   - claude in default_proc_list (variables.sh)
#   - claude strategy registration (resurrect.tmux)

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$CURRENT_DIR/.."
STRATEGY="$ROOT_DIR/strategies/claude_session.sh"
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

echo "Strategy: claude_session.sh"

assert_strategy_output \
	"plain 'claude' appends --continue" \
	"claude" "/some/dir" \
	"claude --continue"

assert_strategy_output \
	"'claude --continue' is returned as-is (no duplication)" \
	"claude --continue" "/some/dir" \
	"claude --continue"

assert_strategy_output \
	"'claude --resume <id>' is preserved" \
	"claude --resume abc123" "/some/dir" \
	"claude --resume abc123"

assert_strategy_output \
	"'claude --model opus' preserves flags and appends --continue" \
	"claude --model opus" "/some/dir" \
	"claude --model opus --continue"

assert_strategy_output \
	"multiple flags are preserved with --continue appended" \
	"claude --verbose --model sonnet" "/some/dir" \
	"claude --verbose --model sonnet --continue"

assert_strategy_output \
	"--continue with other flags is returned as-is" \
	"claude --model opus --continue" "/some/dir" \
	"claude --model opus --continue"

assert_strategy_output \
	"--resume with other flags is preserved" \
	"claude --resume abc123 --verbose --model opus" "/some/dir" \
	"claude --resume abc123 --verbose --model opus"

assert_strategy_output \
	"flags without resume/continue get --continue appended" \
	"claude --debug --allowedTools Bash Edit" "/some/dir" \
	"claude --debug --allowedTools Bash Edit --continue"

# ---------- Wiring tests ----------

echo ""
echo "Wiring: variables.sh"

if grep -q "'.*claude.*'" "$VARIABLES"; then
	pass "claude is in default_proc_list"
else
	fail "claude is in default_proc_list" "not found in $VARIABLES"
fi

echo ""
echo "Wiring: resurrect.tmux"

if grep -q 'claude.*"session"' "$RESURRECT_TMUX"; then
	pass "claude strategy registered as 'session'"
else
	fail "claude strategy registered as 'session'" "not found in $RESURRECT_TMUX"
fi

# ---------- Strategy file sanity ----------

echo ""
echo "Sanity: strategy file"

if [ -x "$STRATEGY" ]; then
	pass "claude_session.sh is executable"
else
	fail "claude_session.sh is executable" "file is not executable"
fi

# ---------- Summary ----------

echo ""
total=$((pass_count + fail_count))
echo "Results: $pass_count/$total passed, $fail_count failed"

if [ "$fail_count" -gt 0 ]; then
	exit 1
fi
