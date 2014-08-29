start_spinner() {
	$CURRENT_DIR/tmux_spinner.sh "Restoring tmux..." "Tmux restore complete!" &
	export SPINNER_PID=$!
}

stop_spinner() {
	kill $SPINNER_PID
}
