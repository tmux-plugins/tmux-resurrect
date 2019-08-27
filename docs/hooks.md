# Save & Restore Hooks

Hooks allow to set custom commands that will be executed during session save
and restore. Most hooks are called with zero arguments, unless explicitly
stated otherwise.

Currently the following hooks are supported:

- `@resurrect-hook-post-save-layout`

  Called after all sessions, panes and windows have been saved.

  Passed single argument of the state file.

- `@resurrect-hook-post-save-all`

  Called at end of save process right before the spinner is turned off.

- `@resurrect-hook-pre-restore-all`

  Called before any tmux state is altered.

- `@resurrect-hook-pre-restore-history` - deprecated

  Called after panes and layout have been restores, but before bash history is
  restored (if it is enabled) -- the hook is always called even if history
  saving is disabled.

- `@resurrect-hook-pre-restore-pane-processes`

  Called after history is restored, but before running processes are restored.

### Examples

Here is an example how to save and restore window geometry for most terminals in X11.
Add this to `.tmux.conf`:

    set -g @resurrect-hook-post-save-all 'eval $(xdotool getwindowgeometry --shell $WINDOWID); echo 0,$X,$Y,$WIDTH,$HEIGHT > $HOME/.tmux/resurrect/geometry'
    set -g @resurrect-hook-pre-restore-all 'wmctrl -i -r $WINDOWID -e $(cat $HOME/.tmux/resurrect/geometry)'
