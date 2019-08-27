# Restoring shell history (deprecated, do not use)

This feature is deprecated because it's very invasive. It will be removed in
the future with no replacement. To see problems it causes check
[this issue](https://github.com/tmux-plugins/tmux-resurrect/issues/288).

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
