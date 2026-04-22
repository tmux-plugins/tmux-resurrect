if [ -d "$HOME/.tmux/resurrect" ]; then
	default_resurrect_dir="$HOME/.tmux/resurrect"
else
	default_resurrect_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
fi
