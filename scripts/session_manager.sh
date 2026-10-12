#!/usr/bin/env bash

# Interactive manager for per-session saves: restore/attach, delete, rename.
# Installed as a symlink (by default ~/bin/attach), so resolve the real path.

CURRENT_DIR="$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
# reads tmux options, which fails harmlessly when no server is running
source "$CURRENT_DIR/helpers.sh" 2>/dev/null

SESSIONS_DIR="$(sessions_dir)"

# session name as stored inside a save file
saved_session_name() {
	awk -F'\t' '/^pane/ { print $2; exit }' "$1"
}

choose_session() {
	local prompt="$1"
	local choice
	read -p "$prompt" choice
	if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -ge "${#SAVED_SESSIONS[@]}" ]]; then
		echo "Invalid selection. Exiting." >&2
		exit 1
	fi
	echo "${SAVED_SESSIONS[$choice]}"
}

delete_session() {
	local session_file="$1"
	local confirm
	read -p "Are you sure you want to delete '$(basename "$session_file" .txt)'? [y/N]: " confirm
	if [[ "$confirm" =~ ^[yY]$ ]]; then
		rm -f "$session_file" "$(session_pane_contents_archive_file "$session_file")"
		echo "Deleted: $(basename "$session_file" .txt)"
	else
		echo "Deletion cancelled."
	fi
}

# renames the session inside the save file and its pane contents archive too,
# so a restore recreates the session under the new name
rename_session() {
	local old_file="$1"
	local old_name="$(saved_session_name "$old_file")"
	local new_name
	read -p "Enter new name: " new_name
	if [[ -z "$new_name" ]] || [[ "$new_name" =~ [:.] ]]; then
		echo "Invalid name (must be non-empty, without ':' or '.'). Exiting."
		exit 1
	fi
	local new_file="$(session_file_path "$new_name")"
	if [[ -e "$new_file" ]]; then
		echo "Error: A session with that name already exists."
		exit 1
	fi

	awk -v new="$new_name" 'BEGIN { FS = OFS = "\t" }
		/^(pane|window)\t/ { $2 = new }
		/^state\t/ { $2 = new; $3 = new }
		{ print }' "$old_file" > "$new_file" && rm "$old_file"

	local old_archive="$(session_pane_contents_archive_file "$old_file")"
	if [[ -f "$old_archive" ]]; then
		local tmp_dir="$(mktemp -d)"
		gzip -d < "$old_archive" | tar xf - -C "$tmp_dir"
		local pane_file
		for pane_file in "$tmp_dir"/pane_contents/pane-"$old_name":*; do
			[[ -e "$pane_file" ]] || continue
			mv "$pane_file" "$tmp_dir/pane_contents/pane-${new_name}:${pane_file##*:}"
		done
		tar cf - -C "$tmp_dir" ./pane_contents/ |
			gzip > "$(session_pane_contents_archive_file "$new_file")"
		rm -rf "$tmp_dir" "$old_archive"
	fi

	# 'last' would otherwise dangle
	if [[ "$(readlink -f "$(last_resurrect_file)")" == "$(readlink -f "$old_file")" ]]; then
		ln -fs "$(basename "$SESSIONS_DIR")/$(basename "$new_file")" "$(last_resurrect_file)"
	fi
	echo "Renamed: $old_name -> $new_name"
}

attach_or_switch() {
	local session_name="$1"
	if [[ -n "$TMUX" ]]; then
		tmux switch-client -t "=$session_name"
	else
		tmux attach-session -t "=$session_name"
	fi
}

restore_session() {
	local session_file="$1"
	local session_name="$(saved_session_name "$session_file")"
	if [[ -z "$session_name" ]]; then
		echo "Error: '$session_file' contains no panes."
		exit 1
	fi

	# already running: restoring would merge the save into the live session
	if tmux has-session -t "=$session_name" 2>/dev/null; then
		echo "Session '$session_name' is already running."
		attach_or_switch "$session_name"
		return
	fi

	# restore.sh runs inside tmux, so make sure a server is running
	local temp_session="resurrect-temp-$$-$RANDOM"
	local created_temp_session=false
	if tmux new-session -d -s "$temp_session" 2>/dev/null; then
		created_temp_session=true
	fi

	# run-shell blocks until the restore is done; its client-related
	# messages are meaningless here since no client is attached
	tmux run-shell "$(printf '%q %q' "$CURRENT_DIR/restore.sh" "$session_file")" >/dev/null 2>&1

	if [[ "$created_temp_session" == true ]]; then
		tmux kill-session -t "=$temp_session" 2>/dev/null
	fi

	if ! tmux has-session -t "=$session_name" 2>/dev/null; then
		echo "Error: Restoring '$session_name' failed."
		exit 1
	fi
	echo "Attaching to session: $session_name"
	attach_or_switch "$session_name"
}

main() {
	shopt -s nullglob
	SAVED_SESSIONS=("$SESSIONS_DIR"/*.txt)
	if [[ ${#SAVED_SESSIONS[@]} -eq 0 ]]; then
		echo "No saved sessions found in $SESSIONS_DIR"
		exit 0
	fi

	echo "Available saved tmux sessions:"
	local i
	for i in "${!SAVED_SESSIONS[@]}"; do
		echo "$i) $(basename "${SAVED_SESSIONS[$i]}" .txt)"
	done

	echo ""
	echo "Options: [number] to restore, [d/D] to delete, [r/R] to rename"
	local choice session_file
	read -p "Enter your choice: " choice

	if [[ "$choice" =~ ^[dD]$ ]]; then
		session_file="$(choose_session "Enter the number of the session to delete: ")" || exit 1
		delete_session "$session_file"
	elif [[ "$choice" =~ ^[rR]$ ]]; then
		session_file="$(choose_session "Enter the number of the session to rename: ")" || exit 1
		rename_session "$session_file"
	elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -lt "${#SAVED_SESSIONS[@]}" ]]; then
		restore_session "${SAVED_SESSIONS[$choice]}"
	else
		echo "Invalid selection. Exiting."
		exit 1
	fi
}
main
