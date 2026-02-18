# Resurrect save dir

By default Tmux environment is saved to a file in `~/.tmux/resurrect` dir.
Change this with:

    set -g @resurrect-dir '/some/path'

A leading tilde (`~`) is expanded as your HOME path.

Tmux variables can be used when using the `-F` flag (formats); for example, to
make a subdirectory named after the hostname:

    set -gF @resurrect-dir '~/.tmux/resurrect/#{host}'

or after the short hostname:

    set -gF @resurrect-dir '~/.tmux/resurrect/#{host_short}'
