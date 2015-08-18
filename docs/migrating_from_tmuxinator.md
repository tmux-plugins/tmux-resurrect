# Migrating from `tmuxinator`

### Why migrate to `tmux-resurrect`?

Here are some reasons why you'd want to migrate from `tmuxinator` to
`tmux-resurrect`:

- **Less dependencies**<br/>
  `tmuxinator` depends on `ruby` which can be a hassle to set up if you're not a
  rubyist.<br/>
  `tmux-resurrect` depends just on `bash` which is virtually
  omnipresent.

- **Simplicity**<br/>
  `tmuxinator` has an executable, CLI interface with half dozen commands and
  command completion.<br/>
  `tmux-resurrect` defines just 2 tmux key bindings.

- **No configuration**<br/>
  `tmuxinator` is all about config files (and their constant updating).<br/>
  `tmux-resurrect` requires no configuration to work.

- **Better change handling**<br/>
  When you make a change to any aspect of tmux layout, you also have to
  update related `tmuxinator` project file (and test to make sure change is
  ok).<br/>
  With `tmux-resurrect` there's nothing to do: your change will be
  remembered on the next save.

### How to migrate?

1. Install `tmux-resurrect`.
2. Open \*all* existing `tmuxinator` projects.<br/>
   Verify all projects are open by pressing `prefix + s` and checking they are
   all on the list.
3. Perform a `tmux-resurrect` save.

That's it! You can continue using just `tmux-resurrect` should you choose so.

Note: it probably makes no sense to use both tools at the same time as they do
the same thing (creating tmux environment for you to work in).
Technically however, there should be no issues.

### Usage differences

`tmuxinator` focuses on managing individual tmux sessions (projects).
`tmux-resurrect` keeps track of the \*whole* tmux environment: all sessions are
saved and restored together.

A couple tips if you decide to switch to `tmux-resurrect`:

- Keep all tmux sessions (projects) running all the time.<br/>
  If you want to work on an existing project, you should be able to just
  \*switch* to an already open session using `prefix + s`.<br/>
  This is different from `tmuxinator` where you'd usually run `mux new [project]`
  in order to start working on something.

- No need to kill sessions with `tmux kill-session` (unless you really don't
  want to work on it ever).<br/>
  It's the recurring theme by now: just keep all the sessions running all the
  time. This is convenient and also cheap in terms of resources.

- The only 2 situations when you need `tmux-resurrect`:<br/>
  1) Save tmux environment just before restarting/shutting down your
  computer.<br/>
  2) Restore tmux env after you turn the computer on.

### Other questions?

Still have questions? Feel free to open an
[issue](ihttps://github.com/tmux-plugins/tmux-resurrect/issues). We'll try to
answer it and also update this doc.
