# Tmux Session Saver

Enables saving and restoring of tmux sessions.

### Key bindings

- `prefix + M-s` - save
- `prefix + M-r` - restore

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @tpm_plugins "              \
      tmux-plugins/tpm                 \
      tmux-plugins/tmux-session-saver  \
    "

Hit `prefix + I` to fetch the plugin and source it. You should now be able to
use the plugin.

### Manual Installation

Clone the repo:

    $ git clone https://github.com/tmux-plugins/tmux-session-saver ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/session_saver.tmux

Reload TMUX environment:

    # type this in terminal
    $ tmux source-file ~/.tmux.conf

You should now be able to use the plugin.

### License
[MIT](LICENSE.md)
