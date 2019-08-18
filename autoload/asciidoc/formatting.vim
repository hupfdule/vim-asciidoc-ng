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


function! asciidoc#formatting#AsciidocFormatexpr()
  return s:asciidoc.formatexpr()
endfunction

" FIXME: This is broken at least for lists.
"        They disappear instead of being reformatted!
function s:asciidoc.formatexpr()
  " echom 'formatter called'
  if mode() =~# '[iR]' && &formatoptions =~# 'a'
    return 1
  elseif mode() !~# '[niR]' || (mode() =~# '[iR]' && v:count != 1) || v:char =~# '\s'
    echohl ErrorMsg
    echomsg "Assert(formatexpr): Unknown State: " mode() v:lnum v:count string(v:char)
    echohl None
    return 1
  endif
  if mode() == 'n'
    return self.format_normal_mode(v:lnum, v:count - 1)
  else
    return self.format_insert_mode(v:char)
  endif
endfunction

function s:asciidoc.format_normal_mode(lnum, count)
  " echom "normal formatexpr(lnum,count): " . a:lnum . ", " . a:count
  let lnum = a:lnum
  let last_line = lnum + a:count
  let lnum = self.skip_white_lines(lnum)
  let [lnum, line] = self.skip_fixed_lines(lnum)
  let last_line = max([last_line, lnum])
  let last_line = self.find_last_line(last_line)

  " echom "normal formatexpr(first,last): " . lnum . ", " . last_line
  " echom 'line = ' . line
  " echom 'lnum = ' . lnum
  " echom 'last_line = ' . last_line

  call self.reformat_text(lnum, last_line)
  return 0
endfunction

function s:asciidoc.reformat_chunk(chunk)
  " echom 'reformat_chunk: ' . a:chunk[0]
  return asif#Asif(a:chunk, 'asciidoc', ['setlocal textwidth=' . &tw, 'setlocal indentexpr=', 'setlocal formatexpr=', 'normal! gqap'])
endfunction

function s:asciidoc.replace_chunk(chunk, lnum, last_line)
  exe a:lnum . ',' . a:last_line . 'd'
  undojoin
  call append(a:lnum - 1, a:chunk)
endfunction

" FIXME: Correct this logic
function s:asciidoc.reformat_text(lnum, last_line)
  "echom "Skipping s:asciidoc.reformat_text, because it is broken"
  "return
  " echom 'reformat_text: ' . a:lnum . ', ' . a:last_line
  let lnum = a:lnum
  let last_line = a:last_line
  let lines = getline(lnum, a:last_line)

  let block = s:asciidoc.identify_block(lines[0])
  echom 'block=' . block

  if block == 'literal'
    " nothing to do
  elseif block == 'para'
    let formatted = s:asciidoc.reformat_chunk(lines)
    if formatted != lines
      call s:asciidoc.replace_chunk(formatted, lnum, last_line)
    endif
  elseif block == 'list'
    let formatted = []

    let elems = vimple#list#partition(
          \ vimple#string#scanner(lines).split(
          \   '\n\?\zs\(\(+\n\)\|\(' . s:asciidoc.list_pattern . '\)\)'
          \   , 1)[1:], 2)
    let elems = (type(elems[0]) == type([]) ? elems : [elems])
    for chunk in map(elems
          \ , 'v:val[0] . vimple#string#trim(substitute(v:val[1], "\\n\\s\\+", " ", "g"))')
      " FIXME: This seems to be the broken part. The above for-loop
      "        evaluates to nothing and doesn't get iterated over.
      if chunk =~ "^+\n"
        call extend(formatted, ['+'])
        call extend(formatted, s:asciidoc.reformat_chunk(matchstr(chunk, "^+\n\\zs.*")))
      else
        call extend(formatted, s:asciidoc.reformat_chunk(chunk))
      endif
    endfor
    if formatted != lines
      call s:asciidoc.replace_chunk(formatted, lnum, last_line)
    endif
  else
    echohl Comment
    echom 'vim-asciidoc: unknown block on ' . lnum . ": don't know how to format: " . strpart(lines[0], 0, 20) . '...'
    echohl None
  endif
endfunction

function s:asciidoc.identify_block(line)
  let line = a:line
  if line =~ self.list_pattern
    return 'list'
  elseif line =~ '^[*_`+]\{0,2}\S'
    return 'para'
  elseif line =~ '^\s\+'
    " FIXME: What is this pattern? This is not correct
    return 'literal'
  else
    return 'unknown'
  endif
endfunction


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
