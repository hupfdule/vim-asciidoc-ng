" Pattern definitions {{{
" TODO: We could differentiate wheter to support markdown headings, 1 char
" heading (only asciidoctor) or plain asciidoc headings (at least 2 char
" headings), but is it worth the hassle? At the moment this regex matches
" everything that is valid for asciidoctor.
" FIXME: Extract such common regexes into a common autoloaded file?
let s:atx_title_complex  = ''
let s:atx_title_complex += '^\(=\{1,6}\|\#\{1,6}\)'                             " leading section markers (mandatory)
let s:atx_title_complex += '\s\+'                                               " whitespace (mandatory)
let s:atx_title_complex += '\(\(\[\[[A-Za-z:_][A-Za-z0-9\.\-]\{-\}\]\]\)*\)'    " secondary anchors (optional)
let s:atx_title_complex += '\s*'                                                " whitespace (optional)
let s:atx_title_complex += '\(\S.\{-\}\)'                                       " the actual title text
let s:atx_title_complex += '\s*'                                                " whitespace (optional)
let s:atx_title_complex += '\(\([[\[A-Za-z:_\]\[A-Za-z0-9\.\-\]\{-\}]]\)*\)'    " secondary anchors (optional)
let s:atx_title_complex += '\(\s\+\1\)\?$'                                      " trailing section markers (optional)
let s:atx_title = '^\(=\{1,6}\|\#\{1,6}\)\s\+\(\S.\{-}\)\(\s\+\1\)\?$'
let s:setext_title_text = '\(^\s*$\n\|\%^\|^\[.*\]\s*$\n\)\@<=[^.].*'
"let s:setext_title_text = '\(^\s*$\n\|\%^\|^\[.*\]\s*$\n\)\@<=\(\[.*\]\)\@!\&\([^\.].*\)$'
let s:setext_title_underline = '[=\-~^+]\{2,}\s*$'
let s:setext_title = s:setext_title_text . '\n' . s:setext_title_underline
let s:setext_levels = ['=','-', '~', '^', '+']

" }}}

"" {{{2
" Change the line specified by {line_number} into an atx section header
" of the given {level} with the given {title} either {symmetric} or not.
"
" FIXME: This function is not a motion, but depends on script-local
" functions in this script. This should be refactored again.
function! asciidoc#motions#set_atx_section_title(line_number, level, title, symmetric) abort " {{{1
  if asciidoc#motions#is_setext_section_title(a:line_number)
    let save_pos = getpos('.')
    call cursor(a:line_number, 0)
    call asciidoc#editing#toggle_title_style()
    call setpos('.', save_pos)
  endif
  let level_marks = repeat('=', a:level)
  call setline(a:line_number, level_marks . ' ' . a:title . (a:symmetric ? (' ' . level_marks) : ''))
endfunction " }}}

"" {{{2
" Change the line specified by {line_number} into a setext section header
" of the given {level} with the given {title}.
"
" FIXME: This function is not a motion, but depends on script-local
" functions in this script. This should be refactored again.
function! asciidoc#motions#set_setext_section_title(line_number, level, title) abort " {{{1
  let line_number = a:line_number + 1
  let level_marks = repeat(s:setext_levels[a:level - 1], len(a:title))
  if getline(line_number) =~ '^$'
    call append(line_number - 1, level_marks)
  else
    call setline(line_number, level_marks)
  endif
endfunction " }}}

"" {{{2
" Change the current line into a section header of the given level.
" If the current line already is a valid section header its style
" (atx/setext and symmetric/asymmetric) is retained. Otherwise the default
" style specified by |g:asciidoc_title_style| and
" |g:asciidoc_title_style_atx| is used.
"
" @parameter {level} the level to set the section header to. May be a
"                    number from 1 to 6.
"
" FIXME: This function is not a motion, but depends on script-local
" functions in this script. This should be refactored again.
" FIXME: Which levels are valid? What is the topmost level? 0 or 1?
" Therefore do we need to add +1 to the {level}?
" Maybe change the expected level number?
" Yes. It makes problem in other places. 0 should be topmost, 5 the lowest
" possible
function! asciidoc#motions#set_section_title_level(level) abort " {{{1
  if a:level < 1 || a:level > 6
    echoerr "Invalid section title level: " . a:level
    return
  endif

  let line = line('.')
  let section_title = asciidoc#motions#get_section_title(line)
  if !empty(section_title)
    if section_title.type == 'atx' || a:level ==# 6
      call asciidoc#motions#set_atx_section_title(section_title.line, a:level, section_title.title, get(section_title, 'symmetric', g:asciidoc_title_style_atx != 'asymmetric'))
    else
      call asciidoc#motions#set_setext_section_title(section_title.line, a:level, section_title.title)
    endif
  else
    let title = getline('.')
    if g:asciidoc_title_style == 'atx' || a:level ==# 6
      call asciidoc#motions#set_atx_section_title(line, a:level, title, g:asciidoc_title_style_atx != 'asymmetric')
    else
      call asciidoc#motions#set_setext_section_title(line, a:level, title)
    endif
  endif
endfunction " }}}


"" {{{2
" Indent or outdent the section heading at the cursor position.
"
" If no section heading is found at the cursor position it does nothing.
"
" If the secion heading already has the highest / lowest possible level it
" does nothing.
"
" @param {dent} Either 'in' to indent the heading or 'out' to outdent it
function! asciidoc#motions#dent_section(dent) abort " {{{1
  " validate parameter
  if a:dent !=# 'in' && a:dent !=# 'out'
    echoerr "Invalid argument: " . a:dent
    return
  endif

  let l:line = line('.')
  let l:section_title = asciidoc#motions#get_section_title(line)
  if !empty(l:section_title)
    " do nothing if the lowest / highest level is already reached
    if l:section_title['level'] ==# 1 && a:dent ==# 'out'
      return
    elseif l:section_title['level'] ==# 6 && a:dent ==# 'in'
      return
    endif

    if a:dent ==# 'in'
      let l:level = l:section_title['level'] + 1
    else
      let l:level = l:section_title['level'] - 1
    endif
    call asciidoc#motions#set_section_title_level(l:level)
  endif
endfunction " }}}

"" {{{2
" Jumps to the title of the current section.
" If the cursor already is at the title of the current section,
" jump to the title of the previous section.
" If the cursor is at the title of the first section, do nothing.
"
" This function evaluates the 'v:count' parameter to jump more than one
" section.
function! asciidoc#motions#jump_to_prior_section_title() abort " {{{1
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)
  let prior = 0

  for i in range(1, v:count1)
    let prior_atx = search(s:atx_title, 'Wbn')
    let prior_setext = s:find_next_setext_section_title(line('.'), 'Wbn')
    let prior = max([prior_atx, prior_setext])
    let pos[1] = prior
    call setpos('.', pos)
  endfor

  call setpos('.', old_pos)
  if prior == 0
    return
  endif
  return prior . 'G'
endfunction " }}}

"" {{{2
" Jumps to the title of the next section.
" If the cursor already is at the title of the last section,
" do nothing.
"
" This function evaluates the 'v:count' parameter to jump more than one
" section.
"
" FIXME: Should the jump_to_next/prior... function be joined into a single
" function with parameters 'backwards' 'start/end'?
function! asciidoc#motions#jump_to_next_section_title() abort " {{{1
  let next_atx = search(s:atx_title, 'Wn')
  let next_setext = s:find_next_setext_section_title(line('.'), 'Wn')
  let next = min(filter([next_atx, next_setext], 'v:val != 0'))
  let next = 0

  for i in range(1, v:count1)
    let next_atx = search(s:atx_title, 'Wn')
    let next_setext = s:find_next_setext_section_title(line('.'), 'Wn')
    let next = max([next_atx, next_setext])
    call cursor(next, 0)
  endfor

  if next == 0
    return
  endif
  return next . 'G'
endfunction " }}}

"" {{{2
" Jumps to the last non-empty line of the previous section.
" If the cursor already is at the end of the first section,
" do nothing.
"
" This function evaluates the 'v:count' parameter to jump more than one
" section.
function! asciidoc#motions#jump_to_prior_section_end() abort " {{{1
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)
  let prior = 0

  for i in range(1, v:count1)
    let prior_atx = search(s:atx_title, 'Wbn')
    let prior_setext = s:find_next_setext_section_title(line('.'), 'Wbn')
    let prior = max([prior_atx, prior_setext])
    call cursor(prior, 0)
  endfor

  let prev_non_blank = prevnonblank(prior - 1)

  call setpos('.', old_pos)
  if prev_non_blank <= 1
    " FIXME: We need to take leading comments and whitespace into account
    return
  endif
  return prev_non_blank . 'G'
endfunction " }}}

"" {{{2
" Jumps to the last non-empty line of the current section.
" If the cursor already is at the end of the current section,
" jump to the end of the next section.
" If the cursor is at the end of the last section, do nothing.
"
" This function evaluates the 'v:count' parameter to jump more than one
" section.
function! asciidoc#motions#jump_to_next_section_end() abort " {{{1
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)

  " jump to next section header
  let next_atx = search(s:atx_title, 'Wn')
  let next_setext = s:find_next_setext_section_title(line('.'), 'Wn')
  let next = max([next_atx, next_setext])

  " search for the next section end
  for i in range(1, v:count1)
    let next_atx = search(s:atx_title, 'Wn')
    let next_setext = s:find_next_setext_section_title(line('.'), 'Wn')
    let next = max([next_atx, next_setext])
    let prev_non_blank = prevnonblank(next - 1)
    if prev_non_blank <= old_pos[1]
      call cursor(next, 0)
      " FIXME: Reduce this code duplication?
      let next_atx = search(s:atx_title, 'Wn')
      let next_setext = s:find_next_setext_section_title(line('.'), 'Wn')
      let next = max([next_atx, next_setext])
      let prev_non_blank = prevnonblank(next - 1)
    endif
    call cursor(next, 0)
  endfor

  call setpos('.', old_pos)
  if prev_non_blank == 0
    " if there is no next section header, jump to the last nonblank line
    return prevnonblank(line('$')) . 'G'
  else
    " otherwise return the last non-blank line before that section header
    return prev_non_blank . 'G'
  endif
endfunction " }}}

"" {{{2
" Jumps to the title of the previous section of the same level as the
" current one..
" If the cursor is at the title of the first section of that level, do
" nothing.
function! asciidoc#motions#jump_to_prior_sibling_section_title() abort " {{{1
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)

  " if not already on the currents section title, jump to it
  let current_section_title = asciidoc#motions#get_section_title(line('.'))
  if empty(current_section_title)
    let heading_line = asciidoc#motions#find_next_section_heading(line('.'), 'bWn')
    call cursor(heading_line, 0)
    let current_section_title = asciidoc#motions#get_section_title(line('.'))
  endif

  for i in range(1, v:count1)
    " search for previous section title with the same level as the current one
    let prev_sibling_line = 0
    let prev_section_title = ['undefined']
    while !empty(prev_section_title)
      let heading_line = asciidoc#motions#find_next_section_heading(line('.'), 'bWn')
      if heading_line ==# 0
        break
      endif
      call cursor(heading_line, 0)
      let prev_section_title = asciidoc#motions#get_section_title(line('.'))
      if current_section_title['level'] ==# prev_section_title['level']
        let prev_sibling_line = line('.')
        break
      endif
    endwhile
  endfor

  call setpos('.', old_pos)
  if prev_sibling_line ==# 0
    return
  endif
  return prev_sibling_line . 'G'
endfunction " }}}

"" {{{2
" Jumps to the title of the next section of the same level as the
" current one..
" If the cursor is at the title of the last section of that level, do
" nothing.
"
" FIXME: This is nearly identical to #jump_to_prev_... Only the
" search_flags include no 'b'. Therefore we can combine these into a single
" function.
" FIXME: If the cursor is before the first section title, this breaks with
" an error. It should jump to the first section instead.
function! asciidoc#motions#jump_to_next_sibling_section_title() abort " {{{1
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)

  " if not already on the currents section title, jump to it
  let current_section_title = asciidoc#motions#get_section_title(line('.'))
  if empty(current_section_title)
    let heading_line = asciidoc#motions#find_next_section_heading(line('.'), 'bWn')
    call cursor(heading_line, 0)
    let current_section_title = asciidoc#motions#get_section_title(line('.'))
  endif

  for i in range(1, v:count1)
    " search for next section title with the same level as the current one
    let next_sibling_line = 0
    let next_section_title = ['undefined']
    while !empty(next_section_title)
      let heading_line = asciidoc#motions#find_next_section_heading(line('.'), 'Wn')
      if heading_line ==# 0
        break
      endif
      call cursor(heading_line, 0)
      let next_section_title = asciidoc#motions#get_section_title(line('.'))
      if !empty(current_section_title) && current_section_title['level'] ==# next_section_title['level']
        let next_sibling_line = line('.')
        break
      endif
    endwhile
  endfor

  call setpos('.', old_pos)
  if next_sibling_line ==# 0
    return
  endif
  return next_sibling_line . 'G'
endfunction " }}}

"" {{{2
" Jumps to the title of the parent section of the current one.
" If the current section doesn't have a parent, do nothing.
"
" FIXME: Even these methods are nearly the same as #jump_to_???_sibling_*
function! asciidoc#motions#jump_to_parent_section_title() abort " {{{1
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)

  " if not already on the currents section title, jump to it
  let current_section_title = asciidoc#motions#get_section_title(line('.'))
  if empty(current_section_title)
    let heading_line = asciidoc#motions#find_next_section_heading(line('.'), 'bWn')
    call cursor(heading_line, 0)
    let current_section_title = asciidoc#motions#get_section_title(line('.'))
  endif

  " search for previous section title with the next smaller level as the current one
  let parent_section_line = 0
  let prev_section_title = ['undefined']
  while !empty(prev_section_title)
    let heading_line = asciidoc#motions#find_next_section_heading(line('.'), 'bWn')
    if heading_line ==# 0
      break
    endif
    call cursor(heading_line, 0)
    let prev_section_title = asciidoc#motions#get_section_title(line('.'))
    if current_section_title['level'] - v:count1 ==# prev_section_title['level']
      let parent_section_line = line('.')
      break
    endif
  endwhile

  call setpos('.', old_pos)
  if parent_section_line ==# 0
    return
  endif
  return parent_section_line . 'G'
endfunction " }}}

"" {{{2
" Jumps to the title of the first subsection of the current one.
" If the current section doesn't have any subsections, do nothing.
"
" FIXME: Even these methods are nearly the same as #jump_to_???_sibling_*
" FIXME: If the cursor is before the first section title, this breaks with
" an error. It should jump to the first section instead.
function! asciidoc#motions#jump_to_first_subsection_title() abort " {{{1
  let old_pos = getpos('.')
  let pos = old_pos
  let pos[2] = 0
  call setpos('.', pos)

  " if not already on the currents section title, jump to it
  let current_section_title = asciidoc#motions#get_section_title(line('.'))
  if empty(current_section_title)
    let heading_line = asciidoc#motions#find_next_section_heading(line('.'), 'bWn')
    call cursor(heading_line, 0)
    let current_section_title = asciidoc#motions#get_section_title(line('.'))
  endif

  " search for next section title with the next greater level as the current one
  let first_subsection_line = 0
  let next_section_title = ['undefined']
  while !empty(next_section_title)
    let heading_line = asciidoc#motions#find_next_section_heading(line('.'), 'Wn')
    if heading_line ==# 0
      break
    endif
    call cursor(heading_line, 0)
    let next_section_title = asciidoc#motions#get_section_title(line('.'))
    if current_section_title['level'] + v:count1 ==# next_section_title['level']
      let first_subsection_line = line('.')
      break
    endif
  endwhile

  call setpos('.', old_pos)
  if first_subsection_line ==# 0
    return
  endif
  return first_subsection_line . 'G'
endfunction " }}}

"" {{{2
" Find the next section after the given {startline}.
" The given {searchflags} are the same as for the builtint search()
" function.
"
" Returns the line number of the next title (the upper line for setext
" titles) or 0 if no section title can be found after the given line.
" This function does not wrap at the end of the file.
function! asciidoc#motions#find_next_section_heading(start_line, search_flags) abort " {{{1
  let l:old_pos = getpos('.')
  call setpos('.', [0, a:start_line, 0, 0])
  let l:next_atx = search(s:atx_title, a:search_flags)
  let l:next_setext = s:find_next_setext_section_title(a:start_line, a:search_flags)
  if a:search_flags =~# 'b'
    let l:next = max(filter([l:next_atx, l:next_setext], 'v:val != 0'))
  else
    let l:next = min(filter([l:next_atx, l:next_setext], 'v:val != 0'))
  endif
  call setpos('.', l:old_pos)
  return l:next
endfunction " }}}

"" {{{2
" Find the next section whose title matches the given regex {pattern}.
"
" Returns the line number of the found title (the upper line for setext titles)
" or 0 if no matching section title could be found in the whole document.
function! asciidoc#motions#find_next_section_matching(pattern) abort " {{{1
  " Remember current cursor position
  let l:old_pos = getpos('.')

  " start search at the document start
  call setpos('.', [0, 0, 0, 0])

  " search for a section header matching the given {pattern}
  let l:next = 1 " initialize with 1 to loop at least one iteration
  while l:next !=# 0
    let l:next_atx = search(s:atx_title, 'Wcn')
    let l:next_setext = s:find_next_setext_section_title(line('.'), 'Wcn')
    let l:next = min(filter([l:next_atx, l:next_setext], 'v:val != 0'))

    if l:next !=# 0
      let l:section_title = trim(getline(l:next), ' \t\f=')
      if l:section_title =~# a:pattern
        " if we found a matching section header, we can stop
        break
      endif
      " Proceed to the next line for the next search
      call setpos('.', [0, l:next + 1, 0, 0])
    endif
  endwhile

  " Restore original cursor position
  call setpos('.', l:old_pos)

  return l:next
endfunction " }}}

function! asciidoc#motions#is_atx_section_title(line_number) abort " {{{1
   return !empty(asciidoc#motions#get_atx_section_title(a:line_number))
endfunction " }}}

function! asciidoc#motions#is_setext_section_title(line_number) abort " {{{1
   return !empty(asciidoc#motions#get_setext_section_title(a:line_number))
endfunction " }}}

"" {{{2
" Find the next setext section title starting at {start_line}.
" The possible {search_flags} are the same as for the builtin |search()|
" function. Therefore it is possible to search backwords (adding 'b' to the
" {search_flags}) and not wrapping around (adding 'W' to the
" {search_flags}).
"
" Returns the line number of the the upper line of the next setext section
" title or 0 if no further setext section title could be found.
function! s:find_next_setext_section_title(start_line, search_flags) abort " {{{1
  let l:old_pos = getpos('.')
  call setpos('.', [0, a:start_line, 0, 0])
  let l:next_setext = search(s:setext_title, a:search_flags)
  if l:next_setext == 0
    return
  endif
  let l:title_text = getline(l:next_setext)
  let l:title_text = substitute(l:title_text, '\s\+$', '', '') " Remove all whitespace from the end
  let l:title_text_length = strlen(l:title_text)
  let l:title_underline = getline(l:next_setext + 1)
  let l:title_underline = substitute(l:title_underline, '\s\+$', '', '') " Remove all whitespace from the end
  let l:title_underline_length = strlen(l:title_underline)
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
endfunction " }}}

function! asciidoc#motions#get_atx_section_title(line_number) abort " {{{1
  let line = getline(a:line_number)
  let match = matchlist(line, s:atx_title)
  if !empty(match)
    let level = len(match[1])
    let title = match[2]
    let symmetric = len(match[3]) != 0
    "TODO: To not include secondary anchors in the title (like in
    "== [[secondary]] My title
    "TODO Include the anchor and any secondary anchors in the dict
    return {'line' : a:line_number, 'type' : 'atx', 'symmetric' : symmetric, 'level' : level, 'title' : title}
  else
    return {}
  endif
endfunction " }}}

function! asciidoc#motions#get_setext_section_title(line_number) abort " {{{1
  let line = getline(a:line_number)
  if line =~ '^' . s:setext_title_underline
    let underline = line
    let line = getline(a:line_number - 1)
    let precedingline = getline(a:line_number - 2)
  else
    let underline = getline(a:line_number + 1)
    let precedingline = getline(a:line_number - 1)
  endif

  " Check whether the title really matches a setext title
  if precedingline . "\n" . line !~ s:setext_title_text
    " FIXME: This check seems to be broken.
    " The following 3 lines match a a setext header which is incorrect:
    " Hello World!" // <3>
    " end
    " ----
    " Actually it matches any block that it directly adjacent to some other
    " line
    " Also this one is taken as section header:
    " [Sektion 2.5]
    " -------------
    " AHA: Problem ist das '\%^', das in der preceding line matchen soll.
    "      Da wir hier nur einen String haben, matcht '\%^' offenbar immer,
    "      da das immer der Anfang der "Datei" ist.
    return 0
  endif

  " remove all whitespace from the end
  let line = substitute(line, '\s\+$', '', '')
  let underline = substitute(underline, '\s\+$', '', '')

  " FIXME: In the code above we compare with <1. Which should be
  " incorrect...
  if abs(len(line) - len(underline)) < 2 && (line . "\n" . underline) =~ s:setext_title
    let level = 1 + index(s:setext_levels, underline[0])
    return {'line' : a:line_number, 'type' : 'setext', 'level' : level, 'title' : line}
  else
    return {}
  endif
endfunction " }}}

function! asciidoc#motions#get_section_title(line_number) abort " {{{1
  let atx = asciidoc#motions#get_atx_section_title(a:line_number)
  if !empty(atx)
    return atx
  else
    return asciidoc#motions#get_setext_section_title(a:line_number)
  endif
endfunction " }}}

"" {{{2
" Return the level of the section title on the given line.
"
" The topmost level start at 1.
" FIXME: It should actually start at 0
"
" Attention! The return value is undefined if the given line number doesn't
" contain a section title.
function! asciidoc#motions#get_setext_section_title_level(line_number) abort " {{{1
  let line = getline(a:line_number)
  if line =~ '^' . s:setext_title_underline
    let underline = line
    let line_number = a:line_number - 1
    let line = getline(line_number)
  else
    let line_number = a:line_number
    let underline = getline(line_number + 1)
  endif
  " FIXME: Actually level=0 would be the lowest
  let level = 1 + index(s:setext_levels, underline[0])
  return level
endfunction " }}}

"" {{{2
" Return whether the given line is the underline under a Setext section
" header.
"
" Attention! This function assumes that the given line_number actually
" contains a Setext section title. If it is a valid Setext underline, but
" not acutally part of a Setext section title, it will still return 1.
function! asciidoc#motions#is_setext_underline(line_number) abort " {{{1
  let line = getline(a:line_number)
  return line =~# '^' . s:setext_title_underline
endfunction " }}}

" vim: set foldmethod=marker :
