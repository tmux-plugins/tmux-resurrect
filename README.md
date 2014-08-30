# Tmux Resurrect

Restore `tmux` environment after a system restart.

Tmux is great, except when you have to restart the computer. You lose all the
running programs, working directories, pane layouts etc.
There are helpful management tools out there, but they require initial
configuration and continuous updates as your workflow evolves or you start new
projects.

`tmux-resurrect` saves all the little details from your tmux environment so it
can be completely restored after a system restart (or when you feel like it).
No configuration is required. You should feel like you never quit tmux.

It even (optionally) [restores vim sessions](#restoring-vim-sessions)!

### Screencast

[![screencast screenshot](/video/screencast_img.png)](https://vimeo.com/104763018)

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
- windows with focus
- active pane for each window
- programs running within a pane! More details in the
  [configuration section](#configuration).
- restoring vim sessions (optional). More details in
  [restoring vim sessions](#restoring-vim-sessions).

Requirements / dependencies: `tmux 1.9` or higher, `pgrep`

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @tpm_plugins "           \
      tmux-plugins/tpm              \
      tmux-plugins/tmux-resurrect   \
    "

Hit `prefix + I` to fetch the plugin and source it. You should now be able to
use the plugin.

### Manual Installation

Clone the repo:

    $ git clone https://github.com/tmux-plugins/tmux-resurrect ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/resurrect.tmux

Reload TMUX environment:

    # type this in terminal
    $ tmux source-file ~/.tmux.conf

You should now be able to use the plugin.

### Configuration

Configuration is not required, but it enables extra features.

Only a conservative list of programs is restored by default:<br/>
`vi vim emacs man less more tail top htop irssi`.
Open a GitHub issue if you think some other program should be on the default list.

- Restore additional programs with the setting in `.tmux.conf`:

        set -g @resurrect-processes 'ssh psql mysql sqlite3'

- Programs with arguments should be double quoted:

        set -g @resurrect-processes 'some_program "git log"'

- Start with tilde to restore a program whose process contains target name:

        set -g @resurrect-processes 'irb pry "~rails server" "~rails console"'

- Don't restore any programs:

        set -g @resurrect-processes 'false'

- Restore **all** programs (be careful with this!):

        set -g @resurrect-processes ':all:'

#### Restoring vim sessions

- save vim sessions. I recommend [tpope/vim-obsession](https://github.com/tpope/vim-obsession).
- in `.tmux.conf`:

        set -g @resurrect-strategy-vim "session"

`tmux-resurrect` will now restore vim sessions if `Sessions.vim` file is
present.

### Other goodies

- [tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) - a plugin for
  regex searches in tmux and fast match selection
- [tmux-yank](https://github.com/tmux-plugins/tmux-yank) - enables copying
  highlighted text to system clipboard
- [tmux-open](https://github.com/tmux-plugins/tmux-open) - a plugin for quickly
  opening highlighted file or a url

### Reporting bugs and contributing

Both contributing and bug reports are welcome. Please check out
[contributing guidelines](CONTRIBUTING.md).

### Credits

[Mislav Marohnić](https://github.com/mislav) - the idea for the plugin came from his
[tmux-session script](https://github.com/mislav/dotfiles/blob/master/bin/tmux-session).

### Other

Here's another script that tries to solve the same problem:
[link](http://brainscraps.wikia.com/wiki/Resurrecting_tmux_Sessions_After_Reboot).
It even has the same name, even though I discovered it only after publishing
`v1.0` of this plugin.

### License
[MIT](LICENSE.md)
