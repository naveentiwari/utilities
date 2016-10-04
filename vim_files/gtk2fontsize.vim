let s:pattern = '^\(.* \)\([1-9][0-9]*\)$'
let s:defaultfontname ="DejaVu Sans Mono"
let s:defaultfontsize = "12"
let s:defaultfontindex = "0"
let s:maxfontcount   = "1"
let s:fontlist = ['DejaVu Sans Mono', 'UbuntuMono']

function! SetFont(name, size)
    if a:name == "" || a:size == ""
        echoerr 'Empty values passed to SetFont'
        set guifont = 'DejaVuSansMono\ ' . a:size
        return
    endif

    let &guifont = a:name . "\ " . a:size
endfunction

function! SetDefaultFont()
    call SetFont (s:defaultfontname, s:defaultfontsize)
endfunction
command! SetDefaultFont call SetDefaultFont()

function! CheckIfEmptyGUIFont ()
    let fontname = substitute(&guifont, s:pattern, '\1', '')
    let cursize = substitute(&guifont, s:pattern, '\2', '')

    if fontname == ""
        call SetDefaultFont()
    endif
endfunction

function! ChangeFontSize (amount)
    call CheckIfEmptyGUIFont ()

    let fontname = substitute(&guifont, s:pattern, '\1', '')
    let cursize = substitute(&guifont, s:pattern, '\2', '')
    let newsize = cursize + a:amount

    call SetFont (fontname, newsize)
endfunction

command! LargerFont call ChangeFontSize(1)
command! SmallerFont call ChangeFontSize(-1)

function! ChangeFont(amount)
    let cursize = substitute(&guifont, s:pattern, '\2', '')
    let s:defaultfontindex = s:defaultfontindex + a:amount
    if s:defaultfontindex > s:maxfontcount || s:defaultfontindex < 0
        let s:defaultfontindex = 0
    endif
    call SetFont(s:fontlist[s:defaultfontindex], cursize)
endfunction

function! GUIFont ()
    let fontname = substitute(&guifont, s:pattern, '\1', '')
    let cursize = substitute(&guifont, s:pattern, '\2', '')
    echoerr guifont
    echoerr fontname
endfunction
command! GUIFont call GUIFont()

command! ChangeFontAhead call ChangeFont(1)
command! ChangeFontBack  call ChangeFont(-1)

nnoremap <F9>       :ChangeFontAhead<CR>
nnoremap <S-F9>     :ChangeFontBack<CR>
nnoremap <F10>      :LargerFont<CR>
nnoremap <S-F10>    :SmallerFont<CR>
