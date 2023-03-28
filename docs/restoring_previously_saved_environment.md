# Restoring previously saved environment

None of the previous saves are deleted (unless you explicitly do that). All save
files are kept in `~/.tmux/resurrect/` directory, or `~/.local/share/tmux/resurrect`
(unless `${XDG_DATA_HOME}` says otherwise).<br/>
Here are the steps to restore to a previous point in time:

- make sure you start this with a "fresh" tmux instance
- `$ cd ~/.tmux/resurrect/`
- locate the save file you'd like to use for restore (file names have a timestamp)
- symlink the `last` file to the desired save file: `$ ln -sf <file_name> last`
- do a restore with `tmux-resurrect` key: `prefix + Ctrl-r`

You should now be restored to the time when `<file_name>` save happened.

Note bash history is snapshotted with each save, so you will always get the latest
bash history (see [issue #303](https://github.com/tmux-plugins/tmux-resurrect/issues/303)).
