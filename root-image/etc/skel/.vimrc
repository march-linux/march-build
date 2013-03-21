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

" bundle
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
" required! 
Bundle 'gmarik/vundle'
Bundle 'airblade/vim-gitgutter'
Bundle 'ervandew/supertab'
Bundle 'tpope/vim-fugitive'
Bundle 'kien/ctrlp.vim'
Bundle 'scrooloose/nerdcommenter'
