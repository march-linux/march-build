" basic
set nocompatible
set mouse=a
set encoding=utf-8
set nobackup
set noswapfile
filetype plugin indent on

" look
syntax on
set number
set wildmenu

" search
set hlsearch
set incsearch
set ignorecase
set smartcase

" indent
set smartindent
set shiftwidth=4
set tabstop=4
set softtabstop=4
set expandtab

" map
map <F1> :tabprevious<CR>
imap <F1> :tabprevious<CR>

map <F2> :tabnext<CR>
imap <F2> :tabnext<CR>

map <F3> :tabnew<CR>
imap <F3> :tabnew<CR>

map <F4> :tabclose<CR>
imap <F4> :tabclose<CR>
