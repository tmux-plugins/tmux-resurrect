# Restoring programs

Only a conservative list of programs is restored by default:<br/>
`vi vim nvim emacs man less more tail top htop irssi`.

This can be configured with `@resurrect-processes` option in `.tmux.conf`. It
contains space-separated list of additional programs to restore.

- Example restoring additional programs:

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

### Clarifications

> I don't understand tilde `~`, what is it and why is it used when restoring
  programs?

Let's say you use `rails server` command often. You want `tmux-resurrect` to
save and restore it automatically. You might try adding `rails server` to the
list of programs that will be restored:

    set -g @resurrect-processes '"rails server"'  # will NOT work

Upon save, `rails server` command will actually be saved as this command:
`/Users/user/.rbenv/versions/2.0.0-p481/bin/ruby script/rails server`
(if you wanna see how is any command saved, check it yourself in
`~/.tmux/resurrect/last` file).

When programs are restored, the `rails server` command will NOT be restored
because it does not **strictly** match the long
`/Users/user/.rbenv/versions/2.0.0-p481/bin/ruby script/rails server` string.

The tilde `~` at the start of the string relaxes process name matching.

    set -g @resurrect-processes '"~rails server"'  # OK

The above option says: "restore full process if `rails server` string is found
ANYWHERE in the process name".

If you check long process string, there is in fact a `rails server` string at
the end, so now the process will be successfully restored.

> What is arrow `->` and why is is used?

(Please read the above clarification about tilde `~`).

Continuing with our `rails server` example, when the process is finally restored
correctly it might not look pretty as you'll see the whole
`/Users/user/.rbenv/versions/2.0.0-p481/bin/ruby script/rails server` string in
the command line.

Naturally, you'd rather want to see just `rails server` (what you initially
typed), but that information is now unfortunately lost.

To aid this, you can use arrow `->`:

    set -g @resurrect-processes '"~rails server->rails server"'  # OK

This option says: "when this process is restored use `rails server` as the
command name".

Full (long) process name is now ignored and you'll see just `rails server` in
the command line when the program is restored.
