# Tmux Resurrect

[![Build Status](https://travis-ci.org/tmux-plugins/tmux-resurrect.svg?branch=master)](https://travis-ci.org/tmux-plugins/tmux-resurrect)

Restore `tmux` environment after system restart.

Tmux is great, except when you have to restart the computer. You lose all the
running programs, working directories, pane layouts etc.
There are helpful management tools out there, but they require initial
configuration and continuous updates as your workflow evolves or you start new
projects.

`tmux-resurrect` saves all the little details from your tmux environment so it
can be completely restored after a system restart (or when you feel like it).
No configuration is required. You should feel like you never quit tmux.

It even (optionally)
[restores vim and neovim sessions](docs/restoring_vim_and_neovim_sessions.md)!

Automatic restoring and continuous saving of tmux env is also possible with
[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) plugin.

### Screencast

[![screencast screenshot](/video/screencast_img.png)](https://vimeo.com/104763018)

### Key bindings

- `prefix + Ctrl-s` - save the current session (prompts for a name if the
  session still has a default numeric name)
- `prefix + Ctrl-r` - restore the last save

**Custom key bindings example:**

If you prefer simpler key bindings (e.g., `prefix + s` instead of `prefix + Ctrl-s`),
add this to your `.tmux.conf`:

    # Save the current session with prefix + s
    bind-key s run-shell "~/.tmux/plugins/tmux-resurrect/scripts/save_session.sh '#{session_id}'"

    # Save all sessions at once (single file, like upstream tmux-resurrect)
    bind-key S run-shell '~/.tmux/plugins/tmux-resurrect/scripts/save.sh'

    # Restore session with prefix + R
    bind-key R run-shell '~/.tmux/plugins/tmux-resurrect/scripts/restore.sh'

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
  [restoring programs doc](docs/restoring_programs.md).

Optional:

- [restoring vim and neovim sessions](docs/restoring_vim_and_neovim_sessions.md)
- [restoring pane contents](docs/restoring_pane_contents.md)
- [restoring a previously saved environment](docs/restoring_previously_saved_environment.md)

Requirements / dependencies: `tmux 1.9` or higher, `bash`.

Tested and working on Linux, OSX and Cygwin.

`tmux-resurrect` is idempotent! It will not try to restore panes or windows that
already exist.<br/>
The single exception to this is when tmux is started with only 1 pane in order
to restore previous tmux env. Only in this case will this single pane be
overwritten.

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'tmux-plugins/tmux-resurrect'

Hit `prefix + I` to fetch the plugin and source it. You should now be able to
use the plugin.

### Manual Installation

Clone the repo:

    $ git clone https://github.com/tmux-plugins/tmux-resurrect ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/resurrect.tmux

Reload TMUX environment with: `$ tmux source-file ~/.tmux.conf`.
You should now be able to use the plugin.

### Session Manager (`attach` command)

Each session saved with `prefix + Ctrl-s` gets its own file in the
`sessions/` subdirectory of the resurrect dir, e.g.
`~/.tmux/resurrect/sessions/work.txt`. Saving a session again overwrites its
file. Pane contents (if enabled) are stored per session as well.

Automatic saves from [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)
still save all sessions into the usual timestamped files, so restoring on tmux
start keeps working as before.

On load, the plugin links an interactive session manager to `$HOME/bin/attach`.
Run `attach` in your terminal to:

- List all saved sessions
- Restore a session by selecting its number and attach to it (or just attach
  if it's already running)
- Delete saved sessions (press `d`)
- Rename saved sessions (press `r`)

To install it under a different path, or not at all:

    set -g @resurrect-session-manager-path '~/.local/bin/tmux-sessions'
    set -g @resurrect-session-manager-path 'off'

An existing file at that path is never overwritten.

**Note:** For the `attach` command to work, `$HOME/bin` must be in your PATH.
Most Linux distributions include this by default, but if not, add this to your
`.bashrc` or `.zshrc`:

    export PATH="$HOME/bin:$PATH"

### Docs

- [Guide for migrating from tmuxinator](docs/migrating_from_tmuxinator.md)

**Configuration**

- [Changing the default key bindings](docs/custom_key_bindings.md).
- [Setting up hooks on save & restore](docs/hooks.md).
- Only a conservative list of programs is restored by default:<br/>
  `vi vim nvim emacs man less more tail top htop irssi weechat mutt`.<br/>
  [Restoring programs doc](docs/restoring_programs.md) explains how to restore
  additional programs.
- [Change a directory](docs/save_dir.md) where `tmux-resurrect` saves tmux
  environment.

**Optional features**

- [Restoring vim and neovim sessions](docs/restoring_vim_and_neovim_sessions.md)
  is nice if you're a vim/neovim user.
- [Restoring pane contents](docs/restoring_pane_contents.md) feature.

### Other goodies

- [tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) - a plugin for
  regex searches in tmux and fast match selection
- [tmux-yank](https://github.com/tmux-plugins/tmux-yank) - enables copying
  highlighted text to system clipboard
- [tmux-open](https://github.com/tmux-plugins/tmux-open) - a plugin for quickly
  opening highlighted file or a url
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) - automatic
  restoring and continuous saving of tmux env

### Reporting bugs and contributing

Both contributing and bug reports are welcome. Please check out
[contributing guidelines](CONTRIBUTING.md).

### Credits

[Mislav Marohnić](https://github.com/mislav) - the idea for the plugin came from his
[tmux-session script](https://github.com/mislav/dotfiles/blob/2036b5e03fb430bbcbc340689d63328abaa28876/bin/tmux-session).

### License
[MIT](LICENSE.md)
