install_tmux_resurrect_helper() {
	rm -rf ~/.tmux/plugins/tmux-resurrect/
	cd "$CURRENT_DIR"
	git clone --recursive ../ ~/.tmux/plugins/tmux-resurrect/ >/dev/null 2>&1
	cd - >/dev/null
}

# we want "fixed" dimensions no matter the size of real display
set_screen_dimensions() {
	stty cols 200
	stty rows 50
}
