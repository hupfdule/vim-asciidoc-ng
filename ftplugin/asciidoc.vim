" Asciidoc
" Barry Arthur
" 1.1, 2014-08-26

" 'atx' or 'setext'
if !exists('g:asciidoc_title_style')
  let g:asciidoc_title_style = 'atx'
endif

" 'asymmetric' or 'symmetric'
if !exists('g:asciidoc_title_style_atx')
  let g:asciidoc_title_style_atx = 'asymmetric'
endif

compiler asciidoc

setlocal foldmethod=marker
if &spelllang == ''
  setlocal spelllang=en
endif

setlocal spell
setlocal autoindent expandtab softtabstop=2 shiftwidth=2 wrap
if &textwidth == 0
  setlocal textwidth=70
endif
setlocal comments=://
setlocal commentstring=//\ %s

setlocal formatoptions+=tcroqln2
setlocal indentkeys=!^F,o,O
setlocal nosmartindent nocindent
setlocal isk-=_

" headings
nnoremap <buffer> <leader>0 :call asciidoc#set_section_title_level(1)<cr>
nnoremap <buffer> <leader>1 :call asciidoc#set_section_title_level(2)<cr>
nnoremap <buffer> <leader>2 :call asciidoc#set_section_title_level(3)<cr>
nnoremap <buffer> <leader>3 :call asciidoc#set_section_title_level(4)<cr>
nnoremap <buffer> <leader>4 :call asciidoc#set_section_title_level(5)<cr>

noremap <buffer> <expr><silent> [[ asciidoc#motions#jump_to_prior_section_title()
noremap <buffer> <expr><silent> [] asciidoc#motions#jump_to_prior_section_end()
noremap <buffer> <expr><silent> ]] asciidoc#motions#jump_to_next_section_title()
noremap <buffer> <expr><silent> ][ asciidoc#motions#jump_to_next_section_end()

" TODO: Rethink default mappings. These don't seem to be well chosen
" TODO: Provide <Plug> mappings for all commands
xnoremap <buffer> <silent> lu :call asciidoc#make_list('*')<cr>gv
xnoremap <buffer> <silent> lo :call asciidoc#make_list('.')<cr>gv
xnoremap <buffer> <silent> l< :call asciidoc#dent_list('in')<cr>gv
xnoremap <buffer> <silent> l> :call asciidoc#dent_list('out')<cr>gv

nmap     <buffer> <leader>lu viplu<c-\><c-n>``
nmap     <buffer> <leader>lo viplo<c-\><c-n>``

let s:asciidoc = {}
let s:asciidoc.delimited_block_pattern = '^[-.~_+^=*\/]\{4,}\s*$'
let s:asciidoc.heading_pattern = '^[-=~^+]\{4,}\s*$'

" TODO: Get rid of ERex. What is it really used for?
let s:asciidoc.list_pattern = ERex.parse('
      \ \%(\_^\|\n\)       # explicitly_numbered
      \   \s*
      \   \d\+
      \   \.
      \   \s\+
      \ \|
      \ \%(\_^\|\n\)       # explicitly_alpha
      \   \s*
      \   [a-zA-Z]
      \   \.
      \   \s\+
      \ \|
      \ \%(\_^\|\n\)       # explicitly_roman
      \   \s*
      \   [ivxIVX]\+       # (must_end_in_")"
      \   )
      \   \s\+
      \ \|
      \ \%(\_^\|\n\)       # definition_list
      \   \%(\_^\|\n\)
      \   \%(\S\+\s\+\)\+
      \   ::\+
      \   \s\+
      \   \%(\S\+\)\@=
      \ \|
      \ \%(\_^\|\n\)       # implicit
      \   \s*
      \   [-*+.]\+
      \   \s\+
      \   \%(\S\+\)\@=
      \')

" DEPRECATED after accurate list_pattern definition above
" let s:asciidoc.itemization_pattern = '^\s*[-*+.]\+\s'

" allow multi-depth list chars (--, ---, ----, .., ..., ...., etc)
exe 'syn match asciidocListBullet /' . s:asciidoc.list_pattern . '/'
let &l:formatlistpat=s:asciidoc.list_pattern

"Typing "" in insert mode inserts a pair of smart quotes and places the
"cursor between them. Depends on asciidoc/asciidoctor flavour. Off by default.

if ! exists('g:asciidoc_smartquotes')
  let g:asciidoc_smartquotes = 0
endif
if ! exists('g:asciidoctor_smartquotes')
  let g:asciidoctor_smartquotes = 0
endif

if g:asciidoc_smartquotes
  inoremap <buffer> "" ``''<ESC>hi
elseif g:asciidoctor_smartquotes
  inoremap <buffer> "" "``"<ESC>hi
endif

" indent
" ------
setlocal indentexpr=GetAsciidocIndent()

" stolen from the RST equivalent
function! GetAsciidocIndent() abort
  let lnum = prevnonblank(v:lnum - 1)
  if lnum == 0
    return 0
  endif

  let [lnum, line] = s:asciidoc.skip_back_until_white_line(lnum)
  let ind = indent(lnum)

  " echom 'lnum=' . lnum
  " echom 'ind=' . ind
  " echom 'line=' . line

  " Don't auto-indent within lists
  if line =~ s:asciidoc.itemization_pattern
    let ind = 0
  endif

  let line = getline(v:lnum - 1)

  return ind
endfunction

" format
" ------

" The following object and its functions is modified from Yukihiro Nakadaira's
" autofmt example.

" Easily reflow text
" the  Q form (badly) tries to keep cursor position
" the gQ form subsequently jumps over the reformatted block
nnoremap <silent> <buffer> Q  :call <SID>Q(0)<cr>
nnoremap <silent> <buffer> gQ :call <SID>Q(1)<cr>

function! s:Q(skip_block_after_format) abort
  if ! a:skip_block_after_format
    let save_clip = @*
    let save_reg  = @@
    let tos       = line('w0')
    let pos       = getpos('.')
    norm! v{y
    call setpos('.', pos)
    let word_count = len(split(@@, '\_s\+'))
  endif

  norm! gqap

  if a:skip_block_after_format
    normal! }
  else
    let scrolloff = &scrolloff
    set scrolloff=0
    call setpos('.', pos)
    exe 'norm! {' . word_count . 'W'
    let pos = getpos('.')
    call cursor(tos, 1)
    norm! zt
    call setpos('.', pos)
    let &scrolloff = scrolloff
    let @* = save_clip
    let @@ = save_reg
  endif
endfunction

setlocal formatexpr=asciidoc#formatting#AsciidocFormatexpr()

