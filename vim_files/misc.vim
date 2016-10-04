" set the leader for the vim
" leader is comma key
let mapleader=","

" force save the file
nnoremap <Leader>w :w !sudo tee % >/dev/null<CR><CR>

" open file in the same directory
nnoremap <Leader>tf :e %:p:h/

" transition between header and source
nnoremap <Leader>tc :e %<.c<CR>
nnoremap <Leader>tC :e %<.cpp<CR>
nnoremap <Leader>th :e %<.h<CR>
