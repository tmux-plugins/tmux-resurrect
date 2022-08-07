# Custom key bindings

The default key bindings are:

- `prefix + Ctrl-s` - save all sessions
- `prefix + Ctrl-t` - save current session
- `prefix + Ctrl-r` - restore

To change these, add to `.tmux.conf`:

    set -g @resurrect-save 'S'
    set -g @resurrect-save-current 'T'
    set -g @resurrect-restore 'R'
