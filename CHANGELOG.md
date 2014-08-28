# Changelog

### master
- refactor checking if saved tmux session exists

### v0.0.5, 2014-08-28
- restore pane processes
- user option for disabling pane process restoring
- enable whitelisting processes that will be restored
- expand readme with configuration options
- enable command strategies; enable restoring vim sessions
- update readme: explain restoring vim sessions

### v0.0.4, 2014-08-26
- restore pane layout for each window
- bugfix: correct pane ordering in a window

### v0.0.3, 2014-08-26
- save and restore current and alternate session
- fix a bug with non-existing window names
- restore active pane for each window that has multiple panes
- restore active and alternate window for each session

### v0.0.2, 2014-08-26
- saving a new session does not remove the previous one
- make the directory where sessions are stored configurable
- support only Tmux v1.9 or greater
- display a nice error message if saved session file does not exist
- added README

### v0.0.1, 2014-08-26
- started a project
- basic saving and restoring works
