#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"  && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/helpers.sh"

sessions=`ls $(resurrect_dir)`

main() {
  echo "Available sessions for restore:"
  echo
  for session in $sessions; do
    if [[ "$session" =~ _last$ ]]; then
      echo "${session%%_last}"
    fi
  done
}

main