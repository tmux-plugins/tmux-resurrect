# Restoring Claude Code sessions

[Claude Code](https://docs.claude.com/en/docs/claude-code) (the `claude`
CLI) cannot be resumed simply by re-launching the process — every
conversation is identified by a session UUID. To pick up where you left
off you have to invoke `claude --resume <session-id>`.

`tmux-resurrect` ships with a strategy that does this for you. On
restore it locates the most recent session saved for the pane's working
directory under `~/.claude/projects/` and emits the right
`claude --resume` command. If no prior session exists for that
directory, the original command is run instead so a fresh `claude`
still launches cleanly.

### Enabling

In `.tmux.conf`:

    set -g @resurrect-processes 'claude'
    set -g @resurrect-strategy-claude 'default'

The first line tells `tmux-resurrect` to restore `claude` panes (it is
not in the default process list). The second line tells it to use the
bundled `strategies/claude_default.sh` script when restoring those
panes.

### How it works

Claude Code stores per-project sessions on disk at:

    ~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl

where the encoded directory is your absolute working directory with
every `/` replaced by `-`. For example
`/Users/you/Code/my-app` becomes
`-Users-you-Code-my-app`.

On restore the strategy:

1. Reads the saved working directory of the pane.
2. Computes the encoded project directory under `~/.claude/projects/`.
3. Picks the most recently modified `*.jsonl` in that directory and
   strips the extension to get the session UUID.
4. Runs `claude --resume <session-uuid>` in the restored pane.

If no `*.jsonl` is found (no prior session for that cwd), the
originally captured command is run unmodified.

### Caveats

- If multiple panes were running `claude` in the **same** working
  directory, the strategy always resumes the most recently modified
  session — it has no way to map a specific pane back to a specific
  session.
- Headless sessions started with `claude -p` are not interactive and
  are generally not what you want to restore via tmux-resurrect; the
  strategy still resumes the most recent session regardless of how it
  was started.
- The encoding (`/` → `-`) matches Claude Code's current on-disk layout
  at the time of writing. If a future Claude Code release changes the
  encoding, the strategy will need to be updated.
