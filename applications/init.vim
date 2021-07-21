set number
set relativenumber

nmap <F2> :NERDTreeToggle<CR>

call plug#begin()
    Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
call plug#end()
