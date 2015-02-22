install_tmux_resurrect_helper() {
	local plugin_path="${HOME}/.tmux/plugins/tmux-resurrect/"
	rm -rf "$plugin_path"
	if [ -n "$TRAVIS" ]; then
		git clone --recursive https://github.com/tmux-plugins/tmux-resurrect --branch "$TRAVIS_BRANCH" "$plugin_path" >/dev/null 2>&1
	else # used on vagrant
		git clone --recursive "${CURRENT_DIR}/../" "$plugin_path" >/dev/null 2>&1
	fi
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
