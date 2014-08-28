# key bindings
default_save_key="M-s"
save_option="@session-saver-save"

default_restore_key="M-r"
restore_option="@session-saver-restore"

# default processes that are restored
default_proc_list_option="@session-saver-default-processes"
default_proc_list='vi vim emacs man less more tail top htop irssi irb pry "~rails console"'

# User defined processes that are restored
#  'false' - nothing is restored
#  ':all:' - all processes are restored
#
# user defined list of programs that are restored:
#  'my_program foo another_program'
restore_processes_option="@session-saver-processes"
restore_processes=""

# Defines part of the user variable. Example usage:
#   set -g @session-saver-strategy-vim "session"
restore_process_strategy_option="@session-saver-strategy-"
