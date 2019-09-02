" TODO: create   T   title text-object

" TODO: We could differentiate wheter to support markdown headings, 1 char
" heading (only asciidoctor) or plain asciidoc headings (at least 2 char
" headings), but is it worth the hassle? At the moment this regex matches
" everything that is valid for asciidoctor.
let s:atx_title = '^\(=\{1,6}\|\#\{1,6}\)\s\+\(\S.\{-}\)\(\s\+\1\)\?$'
let s:setext_title_underline = '[-=~^+]\+\s*$'
let s:setext_title = '\_^\(\S.\+\)\s*\n' . s:setext_title_underline
let s:setext_levels = ['=','-', '~', '^', '+']

function! asciidoc#find_prior_section_title()
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)
  let prior_atx = search(s:atx_title, 'Wbn')
  let prior_setext = asciidoc#find_next_setext_section_title(line('.'), 'Wbn')
  call setpos('.', old_pos)
  let prior = max([prior_atx, prior_setext])
  if prior == 0
    return
  endif
  return prior . 'G'
endfunction

function! asciidoc#find_next_section_title()
  let next_atx = search(s:atx_title, 'Wn')
  let next_setext = asciidoc#find_next_setext_section_title(line('.'), 'Wn')
  let next = min(filter([next_atx, next_setext], 'v:val != 0'))
  if next == 0
    return
  endif
  return next . 'G'
endfunction

""
" Find the next setext section title starting at {start_line}.
" The possible {search_flags} are the same as for the builtin |search()|
" function. Therefore it is possible to search backwords (adding 'b' to the
" {search_flags}) and not wrapping around (adding 'W' to the
" {search_flags}).
"
" Returns the line number of the the upper line of the next setext section
" title or 0 if no further setext section title could be found.
function! asciidoc#find_next_setext_section_title(start_line, search_flags) abort
  let l:old_pos = getpos('.')
  call setpos('.', [0, a:start_line, 0, 0])
  let l:next_setext = search(s:setext_title, a:search_flags)
  if l:next_setext == 0
    return
  endif
  let l:title_text_length = strlen(getline(l:next_setext))
  let l:title_underline_length = strlen(getline(l:next_setext + 1))
  if abs(l:title_text_length - l:title_underline_length) <= 1
    call setpos('.', old_pos)
    return l:next_setext
  else
    if a:search_flags =~# 'b'
      return asciidoc#find_next_setext_section_title(l:next_setext - 2, a:search_flags)
    else
      return asciidoc#find_next_setext_section_title(l:next_setext + 2, a:search_flags)
    endif
  endif
endfunction

function! asciidoc#find_prior_section_end()
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)
  let prior_atx = search(s:atx_title, 'Wbn')
  let prior_setext = asciidoc#find_next_setext_section_title(line('.'), 'Wbn')
  call setpos('.', old_pos)
  let prior = max([prior_atx, prior_setext])
  if prior <= 1
    " FIXME: We need to take leading comments and whitespace into account
    return
  endif
  return prior - 1 . 'G'
endfunction

function! asciidoc#find_next_section_end()
  let old_pos = getpos('.')
  let next_atx = search(s:atx_title, 'Wn')
  let next_setext = asciidoc#find_next_setext_section_title(line('.'), 'Wn')
  let next = min(filter([next_atx, next_setext], 'v:val != 0'))
  if next == 0
    " FIXME: This is a bit too much code duplication
    return prevnonblank(line('$')) . 'G'
  endif
  let prev_non_blank = prevnonblank(next - 1)
  if prev_non_blank <= old_pos[1]
    " FIXME: This should be refactored to be a recursive call
    let old_pos[1] = next
    call setpos('.', old_pos)
    let next_atx = search(s:atx_title, 'Wn')
    let next_setext = search(s:setext_title, 'Wn')
    let next = min(filter([next_atx, next_setext], 'v:val != 0'))
    if next == 0
      return prevnonblank(line('$')) . 'G'
    else
      return next -1 . 'G'
    endif
  else
    return next - 1 . 'G'
  endif
endfunction

function! asciidoc#get_atx_section_title(line_number)
  let line = getline(a:line_number)
  let match = matchlist(line, s:atx_title)
  echo match
  if !empty(match)
    let level = len(match[1])
    let title = match[2]
    let symmetric = len(match[3]) != 0
    return {'line' : a:line_number, 'type' : 'atx', 'symmetric' : symmetric, 'level' : level, 'title' : title}
  else
    return {}
  endif
endfunction

function! asciidoc#get_setext_section_title(line_number)
  let line = getline(a:line_number)
  if line =~ '^' . s:setext_title_underline
    let underline = line
    let line_number = a:line_number - 1
    let line = getline(line_number)
  else
    let line_number = a:line_number
    let underline = getline(line_number + 1)
  endif
  let level = 1 + index(s:setext_levels, underline[0])
  if (line . "\n" . underline) =~ s:setext_title
    return {'line' : line_number, 'type' : 'setext', 'level' : level, 'title' : line}
  else
    return {}
  endif
endfunction

function! asciidoc#get_section_title(line_number)
  let atx = asciidoc#get_atx_section_title(a:line_number)
  if !empty(atx)
    return atx
  else
    return asciidoc#get_setext_section_title(a:line_number)
  endif
endfunction

function! asciidoc#set_atx_section_title(line_number, level, title, symmetric)
  let level_marks = repeat('=', a:level)
  call setline(a:line_number, level_marks . ' ' . a:title . (a:symmetric ? (' ' . level_marks) : ''))
endfunction

function! asciidoc#set_setext_section_title(line_number, level, title)
  let line_number = a:line_number + 1
  let level_marks = repeat(s:setext_levels[a:level - 1], len(a:title))
  if getline(line_number) =~ '^$'
    call append(line_number - 1, level_marks)
  else
    call setline(line_number, level_marks)
  endif
endfunction

function! asciidoc#set_section_title_level(level)
  let line = line('.')
  let section_title = asciidoc#get_section_title(line)
  if !empty(section_title)
    if section_title.type == 'atx'
      call asciidoc#set_atx_section_title(section_title.line, a:level, section_title.title, section_title.symmetric)
    else
      call asciidoc#set_setext_section_title(section_title.line, a:level, section_title.title)
    endif
  else
    let title = getline('.')
    if g:asciidoc_title_style == 'atx'
      call asciidoc#set_atx_section_title(line, a:level, title, g:asciidoc_title_style_atx != 'asymmetric')
    else
      call asciidoc#set_setext_section_title(line, a:level, title)
    endif
  endif
endfunction

function! asciidoc#make_list(type) range
  let old_search = @/
  exe a:firstline . ',' . a:lastline . 's/^\s*\([*.]*\)\s*/\=repeat("' . a:type . '", max([1, len(submatch(1))]))." "/'
  let @/ = old_search
endfunction

function! asciidoc#dent_list(in_out) range
  let old_search = @/
  if a:in_out == 'in'
    silent! exe a:firstline . ',' . a:lastline . 's/^[*.]//'
  else
    silent! exe a:firstline . ',' . a:lastline . 's/^\([*.]\)/&&/'
  endif
  let @/ = old_search
endfunction
