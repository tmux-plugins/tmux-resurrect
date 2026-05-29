#!/usr/bin/env bash

# tmux-resurrect: claude-aware save command strategy.
#
# Behaves like save_command_strategies/ps.sh for non-claude commands.
# For panes running `claude`, looks up the per-process sidecar written
# by extras/claude/track-session.sh at SessionStart and rewrites the
# captured command to `claude --resume <uuid>`. This is what makes
# per-pane session mapping work when multiple panes run `claude` in the
# same working directory.
#
# Enable: set -g @resurrect-save-command-strategy 'claude_aware'

PANE_PID="$1"

# Foreground process running in this pane: the child of PANE_PID. Use awk
# with exact match on the first column to avoid the prefix-match bug that
# would fire on PIDs sharing leading digits.
result="$(ps -ao "ppid,pid,command" | awk -v p="$PANE_PID" '
NR > 1 && $1 == p {
    pid = $2
    cmd = ""
    for (i = 3; i <= NF; i++) cmd = cmd (i == 3 ? "" : " ") $i
    print pid "\t" cmd
    exit
}')"

[ -z "$result" ] && exit 0

pid="${result%%$'\t'*}"
full_command="${result#*$'\t'}"

case "$full_command" in
    claude|claude\ *|*/claude|*/claude\ *)
        sidecar="${HOME}/.claude/runtime/${pid}.json"
        if [ -f "$sidecar" ]; then
            session_id="$(python3 -c "
import json
try:
    print(json.load(open('${sidecar}')).get('sessionId', ''))
except Exception:
    pass
" 2>/dev/null || true)"
            if [ -n "$session_id" ]; then
                echo "claude --resume $session_id"
                exit 0
            fi
        fi
        ;;
esac

echo "$full_command"
