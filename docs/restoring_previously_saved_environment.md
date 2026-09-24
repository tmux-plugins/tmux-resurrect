# Restoring previously saved environment

None of the previous saves are deleted (unless you explicitly do that). All save
files are kept in `~/.local/share/tmux/resurrect` by default (see
[save_dir.md](save_dir.md) for how to change this).<br/>
Here are the steps to restore to a previous point in time:

- make sure you start this with a "fresh" tmux instance
- `$ cd ~/.local/share/tmux/resurrect/`
- locate the save file you'd like to use for restore (file names have a timestamp)
- symlink the `last` file to the desired save file: `$ ln -sf <file_name> last`
- do a restore with `tmux-resurrect` key: `prefix + Ctrl-r`

You should now be restored to the time when `<file_name>` save happened.
