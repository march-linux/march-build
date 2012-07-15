" basic
set nocompatible
set mouse=a
set encoding=utf-8
set nobackup
set noswapfile
filetype plugin indent on

" look
syntax on
colorscheme ron
set number
set wildmenu
set wrap

" search
set hlsearch
set incsearch
set ignorecase

" indent
set smartindent
set smarttab
set shiftwidth=4
set tabstop=4
set softtabstop=4

" map
map <F1> :tabprevious<CR>
imap <F1> :tabprevious<CR>

map <F2> :tabnext<CR>
imap <F2> :tabnext<CR>

map <F3> :tabnew<CR>
imap <F3> :tabnew<CR>

map <F4> :tabclose<CR>
imap <F4> :tabclose<CR>
