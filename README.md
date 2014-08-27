# Tmux Session Saver

Persists `tmux` environment across system restarts.

Tmux is great, except when you have to restart your computer. You loose all the
running programs, working directories, pane layouts etc.
There are helpful management tools out there, but they require initial
configuration and continuous updates as your workflow evolves or you start new
projects.

Enter `tmux-session-saver`: tmux persistence without configuration so there are
no interruptions in your workflow.

### About

This plugin goes to great lengths to save and restore all the details from your
`tmux` environment. Here's what's been taken care of:

- all sessions, windows, panes and their order
- current working directory for each pane
- **exact panes layout** within a window
- active and alternative session
- active and alternative window for each session
- active pane for each window
- programs running within a pane! More details in the [configuration section](#configuration).

Requirements / dependencies: `tmux 1.9` or higher, `pgrep`

### Key bindings

- `prefix + Alt-s` - save
- `prefix + Alt-r` - restore

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

### Configuration

By default, only a conservative list of programs is restored:
`vim emacs man less more tail top htop irssi`.
Open a github issue if you think some other program should be on the default list.

- Restore additional programs by putting the following in `.tmux.conf`:

        set -g @session-saver-processes 'ssh telnet myprogram'

- Don't restore any programs:

        set -g @session-saver-processes 'false'

- Restore **all** programs (be careful with this!):

        set -g @session-saver-processes ':all:'

### Reporting bugs and contributing

Code contributions are welcome!

If you find a bug please report it in the issues. When reporting a bug please
attach a file that is symlinked to `~/.tmux/sessions/last`.

### Credits

[Mislav Marohnic](https://github.com/mislav) - the idea for the plugin came from his
[tmux-session script](https://github.com/mislav/dotfiles/blob/master/bin/tmux-session).

### License
[MIT](LICENSE.md)
