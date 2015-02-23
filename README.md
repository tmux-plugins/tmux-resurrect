# Tmux Resurrect

[![Build Status](https://travis-ci.org/tmux-plugins/tmux-resurrect.png?branch=master)](https://travis-ci.org/tmux-plugins/tmux-resurrect)

Restore `tmux` environment after a system restart.

Tmux is great, except when you have to restart the computer. You lose all the
running programs, working directories, pane layouts etc.
There are helpful management tools out there, but they require initial
configuration and continuous updates as your workflow evolves or you start new
projects.

`tmux-resurrect` saves all the little details from your tmux environment so it
can be completely restored after a system restart (or when you feel like it).
No configuration is required. You should feel like you never quit tmux.

It even (optionally) [restores vim and neovim sessions](#restoring-vim-and-neovim-sessions)!

Automatic restoring and continuous saving of tmux env is also possible with
[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) plugin.

### Screencast

[![screencast screenshot](/video/screencast_img.png)](https://vimeo.com/104763018)

### Key bindings

- `prefix + Ctrl-s` - save
- `prefix + Ctrl-r` - restore

For custom key bindings, add to `.tmux.conf`:

    set -g @resurrect-save 'S'
    set -g @resurrect-restore 'R'

### About

This plugin goes to great lengths to save and restore all the details from your
`tmux` environment. Here's what's been taken care of:

- all sessions, windows, panes and their order
- current working directory for each pane
- **exact pane layouts** within windows (even when zoomed)
- active and alternative session
- active and alternative window for each session
- windows with focus
- active pane for each window
- "grouped sessions" (useful feature when using tmux with multiple monitors)
- programs running within a pane! More details in the
  [configuration section](#configuration).
- restoring vim/neovim sessions (optional). More details in
  [restoring vim and neovim sessions](#restoring-vim-and-neovim-sessions).
- restoring bash history (optional, \*experimental*). More details in
  [restoring bash history](#restoring-bash-history-experimental).

Requirements / dependencies: `tmux 1.9` or higher, `bash`.

`tmux-resurrect` is idempotent! It will not try to restore panes or windows that
already exist.<br/>
The single exception to this is when tmux is started with only 1 pane in order
to restore previous tmux env. In this case only will this single pane be
overwritten.

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @tpm_plugins '           \
      tmux-plugins/tpm              \
      tmux-plugins/tmux-resurrect   \
    '

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
`vi vim nvim emacs man less more tail top htop irssi`.

- Restore additional programs with the setting in `.tmux.conf`:

        set -g @resurrect-processes 'ssh psql mysql sqlite3'

- Programs with arguments should be double quoted:

        set -g @resurrect-processes 'some_program "git log"'

- Start with tilde to restore a program whose process contains target name:

        set -g @resurrect-processes 'irb pry "~rails server" "~rails console"'

- Use `->` to specify a command to be used when restoring a program (useful if
  the default restore command fails ):

        set -g @resurrect-processes 'some_program "grunt->grunt development"'

- Don't restore any programs:

        set -g @resurrect-processes 'false'

- Restore **all** programs (be careful with this!):

        set -g @resurrect-processes ':all:'

#### Restoring vim and neovim sessions

- save vim/neovim sessions. I recommend
  [tpope/vim-obsession](https://github.com/tpope/vim-obsession) (as almost every
  plugin, it works for both vim and neovim).
- in `.tmux.conf`:

        # for vim
        set -g @resurrect-strategy-vim 'session'
        # for neovim
        set -g @resurrect-strategy-nvim 'session'

`tmux-resurrect` will now restore vim and neovim sessions if `Sessions.vim` file
is present.

#### Resurrect save dir

By default Tmux environment is saved to a file in `~/.tmux/resurrect` dir.
Change this with:

    set -g @resurrect-dir '/some/path'

#### Restoring bash history (experimental)

In `.tmux.conf`:

    set -g @resurrect-save-bash-history 'on'

Bash `history` for individual panes will now be saved and restored. Due to
technical limitations, this only works for panes which have no program running in
foreground when saving. `tmux-resurrect` will send history write command
to each such pane. To prevent these commands from being added to history themselves,
add `HISTCONTROL=ignoreboth` to your `.bashrc` (this is set by default in Ubuntu).

### Other goodies

- [tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) - a plugin for
  regex searches in tmux and fast match selection
- [tmux-yank](https://github.com/tmux-plugins/tmux-yank) - enables copying
  highlighted text to system clipboard
- [tmux-open](https://github.com/tmux-plugins/tmux-open) - a plugin for quickly
  opening highlighted file or a url
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) - automatic
  restoring and continuous saving of tmux env

You might want to follow [@brunosutic](https://twitter.com/brunosutic) on
twitter if you want to hear about new tmux plugins or feature updates.

### Reporting bugs and contributing

Both contributing and bug reports are welcome. Please check out
[contributing guidelines](CONTRIBUTING.md).

### Credits

[Mislav Marohnić](https://github.com/mislav) - the idea for the plugin came from his
[tmux-session script](https://github.com/mislav/dotfiles/blob/2036b5e03fb430bbcbc340689d63328abaa28876/bin/tmux-session).

### Other

Here's another script that tries to solve the same problem:
[link](http://brainscraps.wikia.com/wiki/Resurrecting_tmux_Sessions_After_Reboot).
It even has the same name, even though I discovered it only after publishing
`v1.0` of this plugin.

### License
[MIT](LICENSE.md)
