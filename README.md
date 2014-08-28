# Tmux Session Saver

Persists `tmux` environment across system restarts.

Tmux is great, except when you have to restart your computer. You loose all the
running programs, working directories, pane layouts etc.
There are helpful management tools out there, but they require initial
configuration and continuous updates as your workflow evolves or you start new
projects.

Enter `tmux-session-saver`: tmux persistence without configuration so there are
no interruptions in your workflow.

It will even (optionally) [restore vim sessions](#restoring-vim-sessions)!

### Key bindings

- `prefix + Alt-s` - save
- `prefix + Alt-r` - restore

### About

This plugin goes to great lengths to save and restore all the details from your
`tmux` environment. Here's what's been taken care of:

- all sessions, windows, panes and their order
- current working directory for each pane
- **exact pane layouts** within windows
- active and alternative session
- active and alternative window for each session
- active pane for each window
- programs running within a pane! More details in the [configuration section](#configuration).
- restoring vim sessions (optional). More details in
  [restoring vim sessions](#restoring-vim-sessions).

Requirements / dependencies: `tmux 1.9` or higher, `pgrep`

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

Only a conservative list of programs is restored by default:
`vi vim emacs man less more tail top htop irssi irb pry`.
Open a github issue if you think some other program should be on the default list.

- Restore additional programs by putting the following in `.tmux.conf`:

        set -g @session-saver-processes 'ssh psql mysql sqlite3'

- Don't restore any programs:

        set -g @session-saver-processes 'false'

- Restore **all** programs (be careful with this!):

        set -g @session-saver-processes ':all:'

#### Restoring vim sessions

- save vim sessions - I recommend [tpope/vim-obsession](tpope/vim-obsession)
- in `.tmux.conf`:

        set -g @session-saver-strategy-vim "session"

`tmux-session-saver` will now restore vim sessions if `Sessions.vim` file is
present.

### Reporting bugs and contributing

Code contributions are welcome!

If you find a bug please report it in the issues. When reporting a bug please
attach:
- a file symlinked to `~/.tmux/sessions/last`.
- your `.tmux.conf`
- if you're getting an error paste it to a [gist](https://gist.github.com/) and
  link it in the issue

### Credits

[Mislav Marohnić](https://github.com/mislav) - the idea for the plugin came from his
[tmux-session script](https://github.com/mislav/dotfiles/blob/master/bin/tmux-session).

### License
[MIT](LICENSE.md)
