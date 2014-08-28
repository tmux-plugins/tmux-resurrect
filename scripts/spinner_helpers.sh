start_spinner() {
	$CURRENT_DIR/tmux_spinner.sh "Restoring sessions..." "Restored all Tmux sessions!" &
	export SPINNER_PID=$!
}

stop_spinner() {
	kill $SPINNER_PID
}
