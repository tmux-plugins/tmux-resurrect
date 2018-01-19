# Save & Restore Hooks

Hooks allow to set custom commands that will be executed during session save and restore.

Currently the following hooks are supported:

- `@resurrect-save-hook` - executed after session save
- `@resurrect-restore-hook` - executed before session restore

Here is an example how to save and restore window geometry for most terminals in X11.
Add this to `.tmux.conf`:

    set -g @resurrect-save-hook 'eval $(xdotool getwindowgeometry --shell $WINDOWID); echo 0,$X,$Y,$WIDTH,$HEIGHT > $HOME/.tmux/resurrect/geometry'
    set -g @resurrect-restore-hook 'wmctrl -i -r $WINDOWID -e $(cat $HOME/.tmux/resurrect/geometry)'
