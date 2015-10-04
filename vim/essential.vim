set nocompatible
filetype plugin indent on
set number
syntax on
nnoremap ; :
set smartindent
set autoindent " always set autoindenting on
set copyindent " copy the previous indentation on autoindenting
set hid
set mouse=a
set ignorecase
set backspace=eol,start,indent
set smartcase
set incsearch
set hlsearch
set autochdir
set t_Co=256
set expandtab
set showmatch
set smarttab
set showcmd
set wildmenu
set wildignore=*.o,*~,*.pyc
set laststatus=2
colorscheme PaperColor
"colorscheme Tomorrow-Night
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"
let &t_EI = "\<Esc>[2 q"
set statusline=
set statusline+=b%-1.3n\ >                    " buffer number
set statusline+=\ %F
set statusline+=\ %M
set statusline+=%R
set statusline+=%#warningmsg#
set statusline+=%*
set statusline+=%=
set statusline+=\ %Y
set statusline+=\ <\ %{&fenc}
set statusline+=\ <\ %{&ff}
set statusline+=\ <\ %p%%
set statusline+=\ %l:
set statusline+=%02.3c       " cursor line/total lines

nnoremap j gj
nnoremap k gk
set clipboard=unnamedplus
set helpheight=30         " Set window height when opening Vim help windows
