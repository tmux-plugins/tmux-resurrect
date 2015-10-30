# Restoring vim and neovim sessions

- save vim/neovim sessions. I recommend
  [tpope/vim-obsession](https://github.com/tpope/vim-obsession) (as almost every
  plugin, it works for both vim and neovim).
- in `.tmux.conf`:

        # for vim
        set -g @resurrect-strategy-vim 'session'
        # for neovim
        set -g @resurrect-strategy-nvim 'session'

`tmux-resurrect` will now restore vim and neovim sessions if `Sessions.vim` file
is present.
  - if you have a custom vimscript which is not `Session.vim` initialize vim with the path to that script e.g. `vim -S /path/to/file`

- if you have macvim which overrides the system's vim see [#75](https://github.com/tmux-plugins/tmux-resurrect/issues/75)
