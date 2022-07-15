tmux-ressurect no longer restores shell history for each pane, as of [this PR](https://github.com/tmux-plugins/tmux-resurrect/pull/308).

As a workaround, you can use the `HISTFILE` environment variable to preserve history for each pane separately, and modify
`PROMPT_COMMAND` to make sure history gets saved with each new command.

Unfortunately, we haven't found a perfect way of getting a unique identifier for each pane, as the `TMUX_PANE` variable
seems to occasionally change when resurrecting. As a workaround, the example below sets a unique ID in each pane's `title`.
The downside of this implementation is that pane titles must all be unique across sessions/windows, and also must use the `pane_id_prefix`.

Any improvements/suggestions for getting a unique, persistent ID for each pane are welcome!

```bash
pane_id_prefix="resurrect_"

# Create history directory if it doesn't exist
HISTS_DIR=$HOME/.bash_history.d
mkdir -p "${HISTS_DIR}"

if [ -n "${TMUX_PANE}" ]; then

  # Check if we've already set this pane title
  pane_id=$(tmux display -pt "${TMUX_PANE:?}" "#{pane_title}")
  if [[ $pane_id != "$pane_id_prefix"* ]]; then

    # if not, set it to a random ID
    random_id=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
    printf "\033]2;$pane_id_prefix$random_id\033\\"
    pane_id=$(tmux display -pt "${TMUX_PANE:?}" "#{pane_title}")
  fi

  # use the pane's random ID for the HISTFILE
  export HISTFILE="${HISTS_DIR}/bash_history_tmux_${pane_id}"
else
  export HISTFILE="${HISTS_DIR}/bash_history_no_tmux"
fi

# Stash the new history each time a command runs.
export PROMPT_COMMAND="$PROMPT_COMMAND;history -a"
```
