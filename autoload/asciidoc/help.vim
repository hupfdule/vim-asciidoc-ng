let s:default_syntax_help_file= expand('<sfile>:p:h:h:h') . '/help/asciidoc_syntax_help.adoc'
"let s:user_syntax_help_file= get(g:, 'asciidoc_syntax_help_file', split(&rtp, ',')[0]. '/backup')
let s:user_syntax_help_file= split(&rtp, ',')[0]. '/vim-asciidoc-ng/asciidoc_syntax_help.adoc'

"" {{{2
"
function! asciidoc#help#syntax_OBSOLETE() abort " {{{1
  if !executable('asciidoc')
    echohl ErrorMsg | echo "asciidoc executable not found" | echohl None
    return
  endif

  let l:cmd= 'new | 0read !asciidoc --help syntax'
  if get(g:, 'asciidoc_help_vertical', 0)
    let l:cmd= 'v' . l:cmd
  endif
  execute l:cmd
  " Jump to start and delete the leading empty line that appears after `read`
  normal ggdd
  setlocal filetype=asciidoc buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap nomodifiable
endfunction " }}}1

"" {{{2
"
function! asciidoc#help#syntax() abort " {{{1
  " TODO: Additionally to split/vsplit support tabs and floating windows
  " TODO: DIfferentiate betwen "syntax help" and "vim plugin help".
  "       Provide both. Can "vim plugin help" be generated somehow?
  " TODO: Avoid opening it twice if it is already open.
  "       Instead jump to the existing window.
  if filereadable(s:user_syntax_help_file)
    let l:syntax_help_file= s:user_syntax_help_file
  else
    let l:syntax_help_file= s:default_syntax_help_file
  endif

  let l:cmd= 'split ' . l:syntax_help_file
  if get(g:, 'asciidoc_help_vertical', 0)
    let l:cmd= 'v' . l:cmd
  endif
  execute l:cmd
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap nomodifiable
  normal gg
endfunction " }}}1
