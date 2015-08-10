# Custom key bindings

The default key bindings are:

- `prefix + Ctrl-s` - save
- `prefix + Ctrl-r` - restore

To change these, add to `.tmux.conf`:

    set -g @resurrect-save 'S'
    set -g @resurrect-restore 'R'
