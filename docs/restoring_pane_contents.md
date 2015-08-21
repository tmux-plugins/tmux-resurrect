# Restoring pane contents

This plugin enables saving and restoring tmux pane contents.

This feature can be enabled by adding this line to `.tmux.conf`:

    set -g @resurrect-capture-pane-contents 'on'

##### Known issue

When using this feature, please check the value of `default-command`
tmux option. That can be done with `$ tmux show -g default-command`.

The value should NOT contain `&&` or `||` operators. If it does, simplify the
option so those operators are removed.

Example:

- this will cause issues (notice the `&&` and `||` operators):

        set -g default-command "which reattach-to-user-namespace > /dev/null && reattach-to-user-namespace -l $SHELL || $SHELL -l"

- this is ok:

        set -g default-command "reattach-to-user-namespace -l $SHELL"

Related [bug](https://github.com/tmux-plugins/tmux-resurrect/issues/98).

Alternatively, you can let
[tmux-sensible](https://github.com/tmux-plugins/tmux-sensible)
handle this option in a cross-platform way and you'll have no problems.
