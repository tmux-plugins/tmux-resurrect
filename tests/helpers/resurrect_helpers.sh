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

configure_tmux_test_environment_helper() {
	printf '%s\n' \
		'set-option -g automatic-rename off' \
		'set-option -g default-shell /bin/bash' \
		>> "${HOME}/.tmux.conf"
}
