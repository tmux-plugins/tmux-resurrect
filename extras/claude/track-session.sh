#!/usr/bin/env bash

# tmux-resurrect: Claude Code SessionStart hook.
#
# Records the running session's UUID, cwd, and parent PID to
# ~/.claude/runtime/<PPID>.json. The companion
# save_command_strategies/claude_aware.sh reads this file at save time
# so each pane resurrects to its own session via
# `claude --resume <uuid>` instead of falling back to "newest in cwd".
#
# Install in ~/.claude/settings.json:
#
#   {
#     "hooks": {
#       "SessionStart": [{
#         "matcher": "*",
#         "hooks": [{
#           "type": "command",
#           "command": "/absolute/path/to/extras/claude/track-session.sh"
#         }]
#       }]
#     }
#   }
#
# Then in .tmux.conf:
#
#   set -g @resurrect-save-command-strategy 'claude_aware'

set -u

runtime_dir="${HOME}/.claude/runtime"
mkdir -p "$runtime_dir"

# Garbage-collect sidecars older than 7 days. Cheap, runs once per session start.
find "$runtime_dir" -type f -name '*.json' -mtime +7 -delete 2>/dev/null || true

payload="$(cat)"

session_id="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("session_id", ""))
except Exception:
    pass
' 2>/dev/null || true)"

cwd="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("cwd", ""))
except Exception:
    pass
' 2>/dev/null || true)"

[ -n "$session_id" ] || exit 0

# $PPID is the claude process that spawned this hook.
cat > "${runtime_dir}/${PPID}.json" <<EOF
{"sessionId":"${session_id}","cwd":"${cwd}","ppid":${PPID}}
EOF
