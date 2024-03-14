# Confirm save & restore actions

By default save & restore will have no confirmation step when the key bindings are pressed. To change this, add to `.tmux.conf`:

    set -g @resurrect-save-confirm 'on'
    set -g @resurrect-restore-confirm 'on'
