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

" TODO: Make simple 'j/k' offsets honour setext style sections
nnoremap <buffer> <expr><silent> [[ asciidoc#find_prior_section_title()
nnoremap <buffer> <expr><silent> [] asciidoc#find_prior_section_title() . 'j'
nnoremap <buffer> <expr><silent> ]] asciidoc#find_next_section_title()
nnoremap <buffer> <expr><silent> ][ asciidoc#find_next_section_title() . 'k'

xnoremap <buffer> <expr><silent> [[ asciidoc#find_prior_section_title()
xnoremap <buffer> <expr><silent> [] asciidoc#find_prior_section_title() . 'j'
xnoremap <buffer> <expr><silent> ]] asciidoc#find_next_section_title()
xnoremap <buffer> <expr><silent> ][ asciidoc#find_next_section_title() . 'k'

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
function! GetAsciidocIndent()
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

function! s:Q(skip_block_after_format)
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

function s:asciidoc.get_line(lnum)
  return [a:lnum, getline(a:lnum)]
endfunction

function s:asciidoc.get_next_line(lnum)
  return s:asciidoc.get_line(a:lnum + 1)
endfunction

function s:asciidoc.get_prev_line(lnum)
  return s:asciidoc.get_line(a:lnum - 1)
endfunction

function s:asciidoc.skip_fixed_lines(lnum)
  let [lnum, line] = s:asciidoc.get_line(a:lnum)
  let done = 0

  while done == 0
    let done = 1
    " skip optional block title
    if line =~ '^\.\a'
      let [lnum, line] = self.get_next_line(lnum)
      let done = 0
    endif
    " " skip list joiner
    " if line =~ '^+$'
    "   let [lnum, line] = self.get_next_line(lnum)
    "   let done = 0
    " endif
    " skip optional attribute or blockid
    if line =~ '^\['
      let [lnum, line] = self.get_next_line(lnum)
      let done = 0
    endif
    " skip possible one-line heading
    if line =~ '^=\+\s\+\a'
      let [lnum, line] = self.get_next_line(lnum)
      let done = 0
    endif
    " skip possible table
    if line =~ '^|'
      let [lnum, line] = self.get_next_line(lnum)
      let done = 0
    endif
    " skip possible start of delimited block
    if line =~ self.delimited_block_pattern
      let [lnum, line] = self.get_next_line(lnum)
      let done = 0
    endif
    " skip possible two-line heading
    let [next_lnum, next_line] = self.get_next_line(lnum)
    if (line =~ '^\a') && (next_line =~ self.heading_pattern)
      let [lnum, line] = self.get_next_line(next_lnum)
      let done = 0
    endif

  endwhile
  return [lnum, line]
endfunction

function s:asciidoc.find_last_line(lnum)
  let [lnum, line] = s:asciidoc.get_line(a:lnum)
  let done = 0

  while done == 0
    let done = 1
    " skip until blank line
    if line !~ '^\s*$'
      let [lnum, line] = self.get_next_line(lnum)
      let done = 0
    endif
  endwhile
  let done = 0

  while done == 0
    let done = 1
    " skip possible blank lines
    if line =~ '^\s*$'
      let [lnum, line] = self.get_prev_line(lnum)
      let done = 0
    endif
    " skip possible one-line heading
    if line =~ self.delimited_block_pattern
      let [lnum, line] = self.get_prev_line(lnum)
      let done = 0
    endif
  endwhile
  return lnum
endfunction

function s:asciidoc.format_insert_mode(char)
  " We don't actually do anything special in insert mode yet.
  " A non-zero return code here uses Vim's internal formatters based on the
  " options set.
  return 1
endfunction

function s:asciidoc.skip_white_lines(lnum)
  let [lnum, line] = s:asciidoc.get_line(a:lnum)
  while line =~ '^\s*$'
    let [lnum, line] = self.get_next_line(lnum)
  endwhile
  return lnum
endfunction

function s:asciidoc.skip_back_until_white_line(lnum)
  let [lnum, line] = s:asciidoc.get_line(a:lnum)
  while line !~ '^\s*$'
    let [pn, pl] = [lnum, line]
    let [lnum, line] = self.get_prev_line(lnum)
  endwhile
  return [pn, pl]
endfunction


