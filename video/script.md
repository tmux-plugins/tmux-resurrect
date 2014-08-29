# Screencast script

1. Intro
========
Let's demo tmux resurrect plugin.

Tmux resurrect enables persisting tmux sessions, so it can survive the dreaded
system restarts.

The benefit is uninterrupted workflow with no configuration required.

2. Working session
==================
Script
------
Let me show you what I have in this tmux demo session.

First of all, I have vim open and it has a couple files loaded.

Then there's a tmux window with a couple splits in various directories across
the system.

Next window contains tmux man page,
  and then there's `htop` program.

And this is just one of many projects I'm currently running.

Actions
-------
- blank tmux window
- vim
  - `ls` to show open files
- multiple pane windows (3)
- man tmux
- htop
- psql
- show a list of session

3. Saving the environment
=========================
Script
------
With vanilla tmux, when I restart the computer this whole environment will be
lost and I'll have to invest time to restore it.

tmux resurrect gives you the ability to persist everything with
prefix plus alt-s.

Now tmux environment is saved and I can safely shut down tmux with a
kill server command.

Actions
-------
- prefix + M-s
- :kill-server

4. Restoring the environment
============================
Script
------
At this point restoring everything back is easy.

I'll fire up tmux again. Notice it's completely empty.

Now, I'll press prefix plus alt-r and everything will restore.

Let's see how things look now.
First of all, I'm back to the exact same window I was in when the environment
was saved. Second - you can see the `htop` program was restored.

Going back there's tmux man page
  a window with multiple panes with the exact same layout as before
  and vim.


tmux resurrect takes special care of vim. By leveraging vim's sessions, it
preserves vim's split windows, open files, even the list of files edited before.

Check out the project readme for more details about special treatment for vim.

That was just one of the restored tmux sessions. If I open tmux session list you
can see all the other projects are restored as well.


When you see all these programs running you might be concerned that this plugin
started a lot of potentially destructive processes.

For example, when you restore tmux you don't want to accidentally start backups,
resource intensive or sensitive programs.

There's no need to be worried though. By default, this plugin starts only a
conservative list of programs like vim, less, tail, htop and similar.
This list of programs restored by default is in the project readme. Also, you
can easily add more programs to it.

If you feel paranoid, there's an option that prevents restoring any program.

Actions
-------
- tmux
- prefix + M-r

- open previous windows
- in vim hit :ls

- prefix + s for a list of panes

5. Outro
========
That's it for this demo. I hope you'll find tmux resurrect useful.
