# Restoring shell history (experimental)

**Supported shells**: `bash` and `zsh`.

Enable feature with this option in `.tmux.conf`:

    set -g @resurrect-save-shell-history 'on'

**Note**: the older `@resurrect-save-bash-history` is now an alias to
`@resurrect-save-shell-history`.

Shell `history` for individual panes will now be saved and restored. Due to
technical limitations, this only works for panes which have no program running
in foreground when saving. `tmux-resurrect` will send history write command to
each such pane.

To prevent these commands from being added to `bash` history
themselves, add `HISTCONTROL=ignoreboth` to your `.bashrc`
(this is set by default in Ubuntu).
