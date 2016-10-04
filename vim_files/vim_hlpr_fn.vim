function! s:CleanEmptyBuffers()
    let buffers = filter(range(0, bufnr('$')), 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val)<0')
     if !empty(buffers)
         exe 'bw '.join(buffers, ' ')
     endif
endfunction
command!    CleanEmptyBuffers   :   call s:CleanEmptyBuffers()

function! CleanAllOtherBuffers()
    let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val) && bufwinnr(v:val)<0')
    if !empty(buffers)
        exe 'bw '.join(buffers, ' ')
    endif
endfunction

function! CleanAllBuffers()
    let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val) && bufwinnr(v:val)<0')
    if !empty(buffers)
        exe 'bw '.join(buffers, ' ')
    endif
    bw
endfunction
command!    CleanAllBuffers :   call CleanAllBuffers()

let g:QFxLineNum        = 1
let g:QFxColNum         = 1
let g:QFxBufNum         = 1
let g:QFxCWinNum        = 1
let g:QFxQWinNum        = 1
let g:QFxMWinNum        = 1
let g:QFxMaxLC          = 1
let g:QFxIsInQFXMode    = 0

function!   SetQuickFixParm (qfxlinenum)
    let     qflist  =   getqflist()
    let     counter =   1
    for ndx in qflist
        if (counter == a:qfxlinenum || counter == 1)
            let     g:QFxLineNum    = ndx.lnum
            let     g:QFxColNum     = ndx.col
            let     g:QFxBufNum     = ndx.bufnr
        endif
        if (counter == a:qfxlinenum)
            break
        endif
        let counter = counter + 1
    endfor
endfunction

function!   CountQFxLine ()
    let     qflist      =   getqflist()
    let     g:QFxMaxLC  = 0
    for ndx in qflist
        let g:QFxMaxLC  = g:QFxMaxLC + 1
    endfor
endfunction

function!   GoToBufLocation (winnum, bufnum, linenum, colnum)
    if g:QFxIsInQFXMode == 1
        execute a:winnum . "wincmd w"
        execute ":buffer ". a:bufnum
        call    cursor(a:linenum, a:colnum)
    endif
endfunction

function! LookUp()
    if g:QFxIsInQFXMode != 1
        let     g:QFxMWinNum    = winnr()
        copen   20
        set     nomodifiable
        set     cursorline
        let     g:QFxQWinNum    = winnr()
        let     g:QFxIsInQFXMode= 1
        wincmd v
        let     g:QFxCWinNum    = winnr()
        set     nomodifiable
        call    CountQFxLine ()
        call    SetQuickFixParm(1)
        call    GoToBufLocation (g:QFxCWinNum, g:QFxBufNum, g:QFxLineNum, g:QFxColNum)
    endif
endfunction
command!    LookUp      :   call LookUp()

function! NextLookUp()
    if g:QFxIsInQFXMode == 1
        execute g:QFxQWinNum . "wincmd w"
        let     nxtlinenum  = line('.') + 1
        if nxtlinenum <= g:QFxMaxLC
            call    cursor(nxtlinenum, 0)
            call    SetQuickFixParm (nxtlinenum)
            call    GoToBufLocation (g:QFxCWinNum, g:QFxBufNum, g:QFxLineNum, g:QFxColNum)
        else
            execute g:QFxCWinNum . "wincmd w"
            echom   'Reached end'
        endif
    endif
endfunction
command!    NextLookUp  :   call    NextLookUp()

function! PrevLookUp()
    if g:QFxIsInQFXMode == 1
        execute g:QFxQWinNum . "wincmd w"
        let     nxtlinenum  = line('.') - 1
        if nxtlinenum >= 1
            call    cursor(nxtlinenum, 0)
            call    SetQuickFixParm (nxtlinenum)
            call    GoToBufLocation (g:QFxCWinNum, g:QFxBufNum, g:QFxLineNum, g:QFxColNum)
        else
            execute g:QFxCWinNum . "wincmd w"
            echom   'Reached Top'
        endif
    endif
endfunction
command!    PrevLookUp  :   call    PrevLookUp()

function!   ShowOnMainWin()
    if g:QFxIsInQFXMode == 1
        call    GoToBufLocation (g:QFxMWinNum, g:QFxBufNum, g:QFxLineNum, g:QFxColNum)
    endif
endfunction

function!   CloseQFx()
    if g:QFxIsInQFXMode == 1
        cclose
        let     g:QFxIsInQFXMode    = 0
        execute g:QFxCWinNum . "wincmd w"
        quit
        set     modifiable
    endif
endfunction
command!    CloseQFx    :   call    CloseQFx()

function!   MoveNext()
    if g:QFxIsInQFXMode == 1
        call    NextLookUp()
    else
        tn
    endif
endfunction
command!    MoveNext    : call  MoveNext()

function!   MovePrev()
    if g:QFxIsInQFXMode == 1
        call    PrevLookUp()
    else
        tp
    endif
endfunction
command!    MovePrev    : call MovePrev()

function!   GetReferences(name)
    execute ":cs find s ". a:name
    call    LookUp()
endfunction
command! -nargs=1 GetRef call GetReferences(<f-args>)

function! GetSearchFmt(input_string)
    let     newstr = "/" . a:input_string . "/gj "
    return  newstr
endfunction

function!   MakeCSearchList(dir)
    let     dirstr      = " " . a:dir . "/**/*."
    let     searchlst   = dirstr . "cpp" . dirstr . "hpp" . dirstr . "cxx" . dirstr . "h" . dirstr . "hxx" . dirstr . "c" . dirstr . "cc"
    return  searchlst
endfunction

function!   FindInFiles(str, ...)
    let     numparms    = a:0
    let     searchdirs  = ""
    while   numparms > 0
        let     searchdirs  =  MakeCSearchList(a:000[numparms - 1]) . searchdirs
        let     numparms    =  numparms - 1
    endwhile
    execute ":vim /" . a:str . "/gj " . searchdirs
    call    CountQFxLine ()
    if g:QFxMaxLC > 0
        call    LookUp()
    endif
endfunction
command! -nargs=* FindInFiles call FindInFiles(<f-args>)

function! ReDoListing()
    cscope kill -1
    silent !rm -f tags cscope.out cscope.files
    silent !find -regextype posix-egrep -regex ".*\.(hpp|h|hxx|c|cpp|cxx|cc)" > cscope.files
    silent !sed -r -i'' -e'/ +/d' cscope.files
    silent !ctags -R --c++-kinds=+p --fields=+iaS --extra=+q --language-force=C++ -L cscope.files
    silent !cscope -b -k
    cscope add cscope.out
endfunction
command! ReDoListing    : call ReDoListing()

function! ReDoListingJava()
    cscope kill -1
    silent !rm -f tags cscope.out cscope.files
    silent !find -regextype posix-egrep -regex ".*\.(java)" > cscope.files
    silent !sed -r -i'' -e'/ +/d' cscope.files
    silent !ctags -R --python-kinds=-i --fields=+iaS --extra=+q --language-force=java -L cscope.files
    silent !cscope -b -k
    cscope add cscope.out
endfunction
command! ReDoListingJava    : call ReDoListingJava()

function! ReDoListingPy()
    cscope kill -1
    silent !rm -f tags cscope.out cscope.files
    silent !find -regextype posix-egrep -regex ".*\.(py)" > cscope.files
    silent !sed -r -i'' -e'/ +/d' cscope.files
    silent !ctags -R --python-kinds=-i --fields=+iaS --extra=+q --language-force=python -L cscope.files
    silent !cscope -b -k
    cscope add cscope.out
endfunction
command! ReDoListingPy    : call ReDoListingPy()

function! ReLoadCscope()
    ReCscope
    ReTag
endfunction
command! ReLoadCscope   : call ReLoadCscope()

function! IndentCFormat ()
    let cmd = "indent -bap -cdb -sc -br -ce -cdw -pcs -cs -bs -saf -sai -saw -di16 -brs -blf -ci4 -lp -nip -ps1 -ppi 4 -il 1 " . bufname("%") . " ; rm -f " . bufname("%") . "~"
    let retval = system (cmd)
    if (retval == 0)
        edit
        normal  gg=G
        execute "w"
    else
        echo "failed to indent"
    endif
endfunction
command! IndentCFormat : call IndentCFormat ()

" save, wipe out all the buffers and quit
nnoremap    <C-I>x     :wa<CR>:call CleanAllBuffers ()<CR>:quit<CR>
" save, wipe out all the buffers and restart vim
nnoremap    <C-I>r     :wa<CR>:call CleanAllBuffers ()<CR>:RestartVim<CR>
" save, wipe out all the buffers except this one and restart
nnoremap    <C-I>c     :wa<CR>:call CleanAllOtherBuffers ()<CR>:RestartVim<CR>
" delete all the empty buffers
nnoremap    <C-I>b     :CleanEmptyBuffers<CR>

nnoremap    <C-N>           :MoveNext<CR>
nnoremap    <C-P>           :MovePrev<CR>
nnoremap    <C-I>m          :call ShowOnMainWin()<CR>
nnoremap    <S-ESC>         :CloseQFx<CR>

nnoremap    <C-F>r          :GetRef <C-R>=expand("<cword>")<CR><CR>
nnoremap    <C-F>s          :FindInFiles 
nnoremap    <C-F>c          :FindInFiles <C-R>=expand("<cword>")<CR> 
