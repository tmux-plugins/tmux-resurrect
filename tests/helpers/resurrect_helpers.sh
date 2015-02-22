install_tmux_resurrect_helper() {
	local plugin_path="${HOME}/.tmux/plugins/tmux-resurrect/"
	rm -rf "$plugin_path"
	git clone --recursive "${CURRENT_DIR}/../" "$plugin_path" >/dev/null 2>&1
}

# we want "fixed" dimensions no matter the size of real display
set_screen_dimensions_helper() {
	stty cols 200
	stty rows 50
}

last_save_file_differs_helper() {
	local original_file="$1"
	diff "$original_file" "${HOME}/.tmux/resurrect/last"
	[ $? -ne 0 ]
}
