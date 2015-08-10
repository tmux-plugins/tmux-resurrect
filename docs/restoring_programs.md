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

