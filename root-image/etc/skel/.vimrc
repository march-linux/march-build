" basic
set nocompatible
set mouse=a
set encoding=utf-8
set fileencoding=utf-8
set nobackup
filetype on

" look
syntax on
colorscheme ron
set number
set wildmenu

" search
set hlsearch
set incsearch

" indent
set expandtab
set smartindent
set smarttab
set shiftwidth=2

" map
map ; :

map <F1> :tabprevious<CR>
imap <F1> :tabprevious<CR>

map <F2> :tabnext<CR>
imap <F2> :tabnext<CR>

map <F3> :tabnew<CR>
imap <F3> :tabnew<CR>

map <F4> :tabclose<CR>
imap <F4> :tabclose<CR>
