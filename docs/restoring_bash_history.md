# Restoring bash history (experimental)

Enable feature with this option in `.tmux.conf`:

    set -g @resurrect-save-bash-history 'on'

Bash `history` for individual panes will now be saved and restored. Due to
technical limitations, this only works for panes which have no program running
in foreground when saving. `tmux-resurrect` will send history write command to
each such pane. To prevent these commands from being added to history
themselves, add `HISTCONTROL=ignoreboth` to your `.bashrc`
(this is set by default in Ubuntu).
