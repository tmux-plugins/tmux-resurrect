# Restoring programs
  - [General instructions](#general-instructions)
  - [Clarifications](#clarifications)
  - [Working with NodeJS](#nodejs)

### General instructions <a name="general-instructions"></a>
Only a conservative list of programs is restored by default:<br/>
`vi vim nvim emacs man less more tail top htop irssi weechat mutt`.

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

### Clarifications <a name="clarfications"></a>

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

To aid this, you can use arrow `->`: (**note**: there is no space before and after `->`)

    set -g @resurrect-processes '"~rails server->rails server"'  # OK

This option says: "when this process is restored use `rails server` as the
command name".

Full (long) process name is now ignored and you'll see just `rails server` in
the command line when the program is restored.

> Now I understand the tilde and the arrow, but things still don't work for me

Here's the general workflow for figuring this out:

- Set up your whole tmux environment manually.<br/>
  In our example case, we'd type `rails server` in a pane where we want it to
  run.
- Save tmux env (it will get saved to `~/.tmux/resurrect/last`).
- Open `~/.tmux/resurrect/last` file and try to find full process string for
  your program.<br/>
  Unfortunately this is a little vague but it should be easy. A smart
  thing to do for our example is to search for string `rails` in the `last`
  file.
- Now that you know the full and the desired process string use tilde `~` and
  arrow `->` in `.tmux.conf` to make things work.

### Working with NodeJS <a name="nodejs"></a> 
If you are working with NodeJS, you may get some troubles with configuring restoring programs.

Particularly, some programs like `gulp`, `grunt` or `npm` are not saved with parameters so tmux-resurrect cannot restore it. This is actually **not tmux-resurrect's issue** but more likely, those programs' issues. For example if you run `gulp watch` or `npm start` and then try to look at `ps` or `pgrep`, you will only see `gulp` or `npm`.

To deal with these issues, one solution is to use [yarn](https://yarnpkg.com/en/docs/install) which a package manager for NodeJS and an alternative for `npm`. It's nearly identical to `npm` and very easy to use. Therefore you don't have to do any migration, you can simply use it immediately. For example: 
- `npm test` is equivalent to `yarn test`, 
- `npm run watch:dev` is equivalent to `yarn watch:dev`
- more interestingly, `gulp watch:dev` is equivalent to `yarn gulp watch:dev`

Before continuing, please ensure that you understand the [clarifications](#clarifications) section about `~` and `->`

#### yarn
It's fairly straight forward if you have been using `yarn` already.

    set -g @resurrect-processes '"~yarn watch"'
    set -g @resurrect-processes '"~yarn watch->yarn watch"'


#### npm
Instead of 

    set -g @resurrect-processes '"~npm run watch"'  # will NOT work

we use 

    set -g @resurrect-processes '"~yarn watch"'     # OK


#### gulp
Instead of

    set -g @resurrect-processes '"~gulp test"'      # will NOT work

we use

    set -g @resurrect-processes '"~yarn gulp test"' # OK


#### nvm
If you use `nvm` in your project, here is how you could config tmux-resurrect:

    set -g @resurrect-processes '"~yarn gulp test->nvm use && gulp test"'

#### Another problem 
Let take a look at this example

    set -g @resurrect-processes '\
          "~yarn gulp test->gulp test" \ 
          "~yarn gulp test-it->gulp test-it" \
    '
**This will not work properly**, only `gulp test` is run, although you can see the command `node /path/to/yarn gulp test-it` is added correctly in `.tmux/resurrect/last` file. 

The reason is when restoring program, the **command part after the dash `-` is ignored** so instead  of command `gulp test-it`, the command `gulp test` which will be run.

A work around, for this problem until it's fixed, is:
- the config should be like this:

      set -g @resurrect-processes '\
          "~yarn gulp test->gulp test" \ 
          "~yarn gulp \"test-it\"->gulp test-it" \

- and in `.tmux/resurrect/last`, we should add quote to `test-it` word

      ... node:node /path/to/yarn gulp "test-it"

