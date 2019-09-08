function! MyFun()
  return '5G'
endfunction

function! MyRanger() range abort
  echo a:firstline . " bis " . a:lastline
endfunction

command! -buffer MyCommand execute 'normal!' . MyFun()

nnoremap <buffer> <Plug>(MyPlug) :MyCommand<cr>

nnoremap <buffer> <expr> <localleader>a MyFun()
nnoremap <buffer>        <localleader>b :MyCommand<cr>
nmap     <buffer>        <localleader>c <Plug>(MyPlug)

nnoremap <buffer>        <localleader>d :call MyRanger()<cr>
