#!/usr/bin/env bash

# Saves a session to its own file. Sessions with a default numeric name are
# named first, so the save file gets a meaningful name.
#
# Usage: save_session.sh <session_id>   (e.g. '#{session_id}' from a binding)

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Inside run-shell, tmux can't tell which session we came from, so the
# session is passed in. Its id ('$3') is used as it never needs quoting.
session_id="${1:-$(tmux display-message -p '#{session_id}')}"
session_name="$(tmux display-message -p -t "$session_id" '#{session_name}')"

if [[ "$session_name" =~ ^[0-9]+$ ]]; then
	# command-prompt returns immediately, so the save has to be chained after
	# the rename instead of running here. '$' is escaped from tmux's parser.
	tmux command-prompt -p "Save session as:" \
		"rename-session -t '$session_id' -- '%%' ; run-shell \"'$CURRENT_DIR/save.sh' --session '\\$session_id'\""
else
	"$CURRENT_DIR/save.sh" --session "$session_id"
fi
