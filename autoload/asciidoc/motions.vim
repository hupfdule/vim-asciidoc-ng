" TODO: We could differentiate wheter to support markdown headings, 1 char
" heading (only asciidoctor) or plain asciidoc headings (at least 2 char
" headings), but is it worth the hassle? At the moment this regex matches
" everything that is valid for asciidoctor.
" FIXME: Extract such common regexes into a common autoloaded file?
let s:atx_title = '^\(=\{1,6}\|\#\{1,6}\)\s\+\(\S.\{-}\)\(\s\+\1\)\?$'
let s:setext_title_underline = '[-=~^+]\+\s*$'
let s:setext_title = '\_^\(\S.\+\)\s*\n' . s:setext_title_underline
let s:setext_levels = ['=','-', '~', '^', '+']


""
" Change the line specified by {line_number} into an atx section header
" of the given {level} with the given {title} either {symmetric} or not.
"
" FIXME: This function is not a motion, but depends on script-local
" functions in this script. This should be refactored again.
function! asciidoc#motions#set_atx_section_title(line_number, level, title, symmetric) abort
  let level_marks = repeat('=', a:level)
  call setline(a:line_number, level_marks . ' ' . a:title . (a:symmetric ? (' ' . level_marks) : ''))
endfunction

""
" Change the line specified by {line_number} into a setext section header
" of the given {level} with the given {title}.
"
" FIXME: This function is not a motion, but depends on script-local
" functions in this script. This should be refactored again.
function! asciidoc#motions#set_setext_section_title(line_number, level, title) abort
  let line_number = a:line_number + 1
  let level_marks = repeat(s:setext_levels[a:level - 1], len(a:title))
  if getline(line_number) =~ '^$'
    call append(line_number - 1, level_marks)
  else
    call setline(line_number, level_marks)
  endif
endfunction

""
" Change the current line into a section header of the given level.
" If the current line already is a valid section header its style
" (atx/setext and symmetric/asymmetric) is retained. Otherwise the default
" style specified by |g:asciidoc_title_style| and
" |g:asciidoc_title_style_atx| is used.
"
" FIXME: This function is not a motion, but depends on script-local
" functions in this script. This should be refactored again.
" FIXME: This function doesn't check the given {level} argument.
" It should only accept valid arguments
" FIXME: Which levels are valid? What is the topmost level? 0 or 1?
" Therefore do we need to add +1 to the {level}?
" Maybe change the expected level number?
" TODO: Provide function to increment/decrement current section.
function! asciidoc#motions#set_section_title_level(level) abort
  let line = line('.')
  let section_title = s:get_section_title(line)
  if !empty(section_title)
    if section_title.type == 'atx'
      call asciidoc#motions#set_atx_section_title(section_title.line, a:level, section_title.title, section_title.symmetric)
    else
      call asciidoc#motions#set_setext_section_title(section_title.line, a:level, section_title.title)
    endif
  else
    let title = getline('.')
    if g:asciidoc_title_style == 'atx'
      call asciidoc#motions#set_atx_section_title(line, a:level, title, g:asciidoc_title_style_atx != 'asymmetric')
    else
      call asciidoc#motions#set_setext_section_title(line, a:level, title)
    endif
  endif
endfunction

""
" Jumps to the title of the current section.
" If the cursor already is at the title of the current section,
" jump to the title of the previous section.
" If the cursor is at the title of the first section, do nothing.
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

""
" Jumps to the title of the next section.
" If the cursor already is at the title of the last section,
" do nothing.
function! asciidoc#motions#jump_to_next_section_title() abort
  let next_atx = search(s:atx_title, 'Wn')
  let next_setext = s:find_next_setext_section_title(line('.'), 'Wn')
  let next = min(filter([next_atx, next_setext], 'v:val != 0'))
  if next == 0
    return
  endif
  return next . 'G'
endfunction

""
" Jumps to the last non-empty line of the previous section.
" If the cursor already is at the end of the first section,
" do nothing.
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

""
" Jumps to the last non-empty line of the current section.
" If the cursor already is at the end of the current section,
" jump to the end of the next section.
" If the cursor is at the end of the last section, do nothing.
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
" Find the next section whose title matches the given regex {pattern}.
"
" Returns the line number of the found title (the upper line for setext titles)
" or 0 if no matching section title could be found in the whole document.
function! asciidoc#motions#find_next_section_matching(pattern) abort
  " Remember current cursor position
  let l:old_pos = getpos('.')

  " start search at the document start
  call setpos('.', [0, 0, 0, 0])

  " search for a section header matching the given {pattern}
  let l:next = 1 " initialize with 1 to loop at least one iteration
  while l:next !=# 0
    let l:next_atx = search(s:atx_title, 'Wn')
    let l:next_setext = s:find_next_setext_section_title(line('.'), 'Wn')
    let l:next = min(filter([l:next_atx, l:next_setext], 'v:val != 0'))

    if l:next !=# 0
      call setpos('.', [0, l:next, 0, 0])
      let l:section_title = trim(getline('.'), ' \t\f=')
      if l:section_title =~# a:pattern
        " if we found a matching section header, we can stop
        break
      endif
    endif
  endwhile

  " Restore original cursor position
  call setpos('.', l:old_pos)

  return l:next
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

