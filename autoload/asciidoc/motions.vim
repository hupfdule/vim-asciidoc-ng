" TODO: We could differentiate wheter to support markdown headings, 1 char
" heading (only asciidoctor) or plain asciidoc headings (at least 2 char
" headings), but is it worth the hassle? At the moment this regex matches
" everything that is valid for asciidoctor.
" FIXME: Extract such common regexes into a common autoloaded file?
let s:atx_title = '^\(=\{1,6}\|\#\{1,6}\)\s\+\(\S.\{-}\)\(\s\+\1\)\?$'
let s:setext_title_underline = '[-=~^+]\+\s*$'
let s:setext_title = '\_^\(\S.\+\)\s*\n' . s:setext_title_underline
let s:setext_levels = ['=','-', '~', '^', '+']

function! asciidoc#motions#jump_to_prior_section_title() abort
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)
  let prior_atx = search(s:atx_title, 'Wbn')
  let prior_setext = s:find_next_setext_section_title(line('.'), 'Wbn')
  call setpos('.', old_pos)
  let prior = max([prior_atx, prior_setext])
  if prior == 0
    return
  endif
  return prior . 'G'
endfunction

function! asciidoc#motions#jump_to_next_section_title() abort
  let next_atx = search(s:atx_title, 'Wn')
  let next_setext = s:find_next_setext_section_title(line('.'), 'Wn')
  let next = min(filter([next_atx, next_setext], 'v:val != 0'))
  if next == 0
    return
  endif
  return next . 'G'
endfunction

function! asciidoc#motions#jump_to_prior_section_end() abort
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)
  let prior_atx = search(s:atx_title, 'Wbn')
  let prior_setext = s:find_next_setext_section_title(line('.'), 'Wbn')
  call setpos('.', old_pos)
  let prior = max([prior_atx, prior_setext])
  if prior <= 1
    " FIXME: We need to take leading comments and whitespace into account
    return
  endif
  return prior - 1 . 'G'
endfunction

function! asciidoc#motions#jump_to_next_section_end() abort
  let old_pos = getpos('.')
  let next_atx = search(s:atx_title, 'Wn')
  let next_setext = s:find_next_setext_section_title(line('.'), 'Wn')
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

""
" Find the next setext section title starting at {start_line}.
" The possible {search_flags} are the same as for the builtin |search()|
" function. Therefore it is possible to search backwords (adding 'b' to the
" {search_flags}) and not wrapping around (adding 'W' to the
" {search_flags}).
"
" Returns the line number of the the upper line of the next setext section
" title or 0 if no further setext section title could be found.
function! s:find_next_setext_section_title(start_line, search_flags) abort
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
      return s:find_next_setext_section_title(l:next_setext - 2, a:search_flags)
    else
      return s:find_next_setext_section_title(l:next_setext + 2, a:search_flags)
    endif
  endif
endfunction

function! s:get_atx_section_title(line_number) abort
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

function! s:get_setext_section_title(line_number) abort
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

function! s:get_section_title(line_number) abort
  let atx = s:get_atx_section_title(a:line_number)
  if !empty(atx)
    return atx
  else
    return s:get_setext_section_title(a:line_number)
  endif
endfunction

