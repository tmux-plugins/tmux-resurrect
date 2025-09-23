tmux-resurrect no longer restores shell history for each pane, as of [this PR](https://github.com/tmux-plugins/tmux-resurrect/pull/308).

As a workaround, you can use the `HISTFILE` environment variable to preserve history for each pane separately (and modifing
`PROMPT_COMMAND` to make sure history gets saved with each new command), then use tmux-resurrect hooks to save/restore the histfile

Add this to your .bashrc
```bash
# If in a TMUX pane, setup special history handling
if [ -n "$TMUX_PANE" ]; then
    # Pick a history directory and make sure it exists
    HISTDIR=$HOME/.bash_history.d
    mkdir -p "$HISTDIR"

    # Set history file to a file using the TMUX pane id
    export HISTFILE="${HISTDIR}/tmux_pane_${TMUX_PANE}"

    # Setup so that after each command we:
    # 1. Append current history to histfile
    # 2. Clear current cached history info from memory
    # 3. Read history from the histfile
    export PROMPT_COMMAND="history -a;history -c;history -r;${PROMPT_COMMAND}"
fi
```

Then make some scripts (or merge into one, dealer's choice) to handle saving/restoring the histories.
For this example, I'll assume you have these scripts placed in the root directory. Don't do that.

post-save-all.sh
```bash
#!/usr/bin/env bash

RESURRECT_DIR="$HOME/.local/share/tmux/resurrect"

save_files() {
    SAVE_DIR=$RESURRECT_DIR/$1
    FILE_PREFIX=$2

    rm -r "$SAVE_DIR" 2>/dev/null

    for PANE_INFO in $(tmux list-panes -aF "#{pane_id}=#{session_id}:#{window_index}.#{pane_index}"); do
        PANE_ID=$(echo $PANE_INFO | cut -f 1 -d'=' | cut -d% -f 2)
        IN=${FILE_PREFIX}${PANE_ID}
        if ! [[ -e "$IN" ]]; then continue; fi

        PANE_INDEX=$(echo $PANE_INFO | cut -f 2 -d'=')
        OUT=$SAVE_DIR/$PANE_INDEX
        if [[ -e "$OUT" ]]; then rm -r "$OUT"; fi

        mkdir -p $(dirname "$OUT")
        cp -p -r "$IN" "$OUT"
    done
}

save_files "history" "$HOME/.bash_history.d/tmux_pane_"
```

pre-restore-pane-processes.sh
```bash
#!/usr/bin/env bash

RESURRECT_DIR="$HOME/.local/share/tmux/resurrect"

restore_files() {
    SAVE_DIR=$RESURRECT_DIR/$1
    FILE_PREFIX=$2

    for PANE_INFO in $(tmux list-panes -aF "#{pane_id}=#{session_id}:#{window_index}.#{pane_index}"); do
        PANE_ID=$(echo $PANE_INFO | cut -f 1 -d'=' | cut -d% -f 2)
        OUT=${FILE_PREFIX}${PANE_ID}
        if [[ -e "$OUT" ]]; then rm -r "$OUT"; fi

        PANE_INDEX=$(echo $PANE_INFO | cut -f 2 -d'=')
        IN=$SAVE_DIR/$PANE_INDEX
        if ! [[ -e "$IN" ]]; then continue; fi

        mkdir -p $(dirname "$OUT")
        cp --preserve -r "$IN" "$OUT"
    done
}

restore_files "history" "$HOME/.bash_history.d/tmux_pane_"
```

Finally, add the following to your .tmux.conf
```bash
# Don't actually put these in the root folder!
set -g @resurrect-hook-post-save-all "/post-save-all.sh"
set -g @resurrect-hook-pre-restore-pane-processes "/pre-restore-pane-processes.sh"
```
