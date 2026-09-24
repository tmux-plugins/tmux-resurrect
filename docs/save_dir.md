# Resurrect save dir

By default Tmux environment is saved to a file in
`${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect`, or `~/.tmux/resurrect`
if it exists for backwards compatibility.
Change this with:

    set -g @resurrect-dir '/some/path'

Using environment variables or shell interpolation in this option is not
allowed as the string is used literally. So the following won't do what is
expected:

    set -g @resurrect-dir '/path/$MY_VAR/$(some_executable)'

Only the following variables and special chars are allowed:
`$HOME`, `$HOSTNAME`, and `~`.
