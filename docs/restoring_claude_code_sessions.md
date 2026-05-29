# Restoring Claude Code sessions

[Claude Code](https://docs.claude.com/en/docs/claude-code) (the `claude`
CLI) cannot be resumed by re-launching the process. Every conversation
is identified by a session UUID and must be re-opened with
`claude --resume <session-id>`.

`tmux-resurrect` ships with a restore strategy that does this. On
restore it locates the most recent session saved for the pane's working
directory under `~/.claude/projects/` and emits the matching
`claude --resume` command. If no prior session exists for that
directory, the original command is run instead so a fresh `claude`
still launches cleanly.

### Enabling (basic mode)

In `.tmux.conf`:

    set -g @resurrect-processes 'claude'
    set -g @resurrect-strategy-claude 'default'

The first line tells `tmux-resurrect` to restore `claude` panes (it is
not in the default process list). The second line tells it to use the
bundled `strategies/claude_default.sh` script when restoring those
panes.

### How basic mode works

Claude Code stores per-project sessions on disk at:

    ~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl

The encoded directory is your absolute working directory with every
`/` replaced by `-`. For example `/Users/you/Code/my-app` becomes
`-Users-you-Code-my-app`.

On restore the strategy:

1. Reads the saved working directory of the pane.
2. Computes the encoded project directory under `~/.claude/projects/`.
3. Picks the most recently modified `*.jsonl` in that directory and
   strips the extension to get the session UUID.
4. Runs `claude --resume <session-uuid>` in the restored pane.

If no `*.jsonl` is found, the originally captured command is run
unmodified.

### Per-pane session mapping (recommended for multiple panes)

Basic mode collapses parallel sessions: if three panes were running
`claude` in the same directory, all three restore to the same
"newest" session. The other two conversations are lost.

The fix has two parts:

1. A `SessionStart` hook that records the running session UUID to a
   per-process sidecar file at `~/.claude/runtime/<pid>.json`. Shipped
   in this repo at `extras/claude/track-session.sh`. Requires
   `python3` on PATH.
2. A claude-aware save command strategy that reads those sidecars at
   save time and writes `claude --resume <uuid>` into the resurrect
   record per pane. Shipped at
   `save_command_strategies/claude_aware.sh`.

#### Install the hook

In `~/.claude/settings.json` (replace the path with the absolute path
to your tmux-resurrect checkout):

    {
      "hooks": {
        "SessionStart": [{
          "matcher": "*",
          "hooks": [{
            "type": "command",
            "command": "/absolute/path/to/tmux-resurrect/extras/claude/track-session.sh"
          }]
        }]
      }
    }

The hook writes a JSON sidecar at SessionStart and garbage-collects
sidecars older than 7 days. It exits silently if `python3` is missing
or the payload is malformed, so a broken hook never breaks claude
itself.

#### Switch the save strategy

In `.tmux.conf`:

    set -g @resurrect-save-command-strategy 'claude_aware'

This replaces the default `ps` save strategy. It behaves like `ps` for
every other command, only diverging when a pane is running `claude`.

#### Result

After both pieces are installed, each `claude` pane is saved as
`claude --resume <its-own-uuid>` instead of bare `claude`. On restore,
the strategy passes the explicit `--resume` flag through unchanged so
every pane resurrects to its own conversation.

### Caveats

- Per-pane mapping requires the hook to have fired (i.e. the `claude`
  session was started after the hook was installed). Sessions started
  before installation fall back to basic mode.
- The hook records the sidecar keyed by `$PPID`, which is the `claude`
  process that spawned it. If a wrapper script sits between, the
  recorded PID may not match the PID the save strategy looks up.
- The `/` to `-` encoding tracks Claude Code's current on-disk layout.
  A future Claude Code release that changes the scheme breaks basic
  mode (per-pane mode is unaffected).
- Headless sessions started with `claude -p` are not interactive.
  Restoring them with `--resume` reopens them as interactive sessions.

### Upstream

The right long-term fix is for Claude Code to expose the running
session ID externally (process env or runtime state file). Tracked at
[anthropics/claude-code#63758](https://github.com/anthropics/claude-code/issues/63758).
Once that lands the hook becomes unnecessary.
