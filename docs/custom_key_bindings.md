# Custom key bindings

The default key bindings are:

- `prefix + Ctrl-s` - save
- `prefix + Ctrl-r` - restore

To change these, add to `.tmux.conf`:

    set -g @resurrect-save 'S'
    set -g @resurrect-restore 'R'

Popup UI is enabled automatically on tmux `3.2+`. To force the old status-line
behavior instead, add:

    set -g @resurrect-popup 'off'

To force popup mode or tune the popup size / close delay:

    set -g @resurrect-popup 'on'
    set -g @resurrect-popup-width '70%'
    set -g @resurrect-popup-height '70%'
    set -g @resurrect-popup-close-delay '2'
