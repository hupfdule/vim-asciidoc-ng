" TODO: We could differentiate wheter to support markdown headings, 1 char
" heading (only asciidoctor) or plain asciidoc headings (at least 2 char
" headings), but is it worth the hassle? At the moment this regex matches
" everything that is valid for asciidoctor.
" FIXME: Extract such common regexes into a common autoloaded file?
let s:atx_title_complex = '^\(=\{1,6}\|\#\{1,6}\)'                             " leading section markers (mandatory)
                \ '\s\+'                                               " whitespace (mandatory)
                \ '\(\(\[\[[A-Za-z:_][A-Za-z0-9\.\-]\{-\}\]\]\)*\)'    " secondary anchors (optional)
                \ '\s*'                                                " whitespace (optional)
                \ '\(\S.\{-\}\)'                                       " the actual title text
                \ '\s*'                                                " whitespace (optional)
                \ '\(\([[\[A-Za-z:_\]\[A-Za-z0-9\.\-\]\{-\}]]\)*\)'    " secondary anchors (optional)
                \ '\(\s\+\1\)\?$'                                      " trailing section markers (optional)
let s:atx_title = '^\(=\{1,6}\|\#\{1,6}\)\s\+\(\S.\{-}\)\(\s\+\1\)\?$'
let s:setext_title_text = '\(^\s*$\n\|\%^\|^\[.*\]\s*$\n\)\@<=[^.].*'
"let s:setext_title_text = '\(^\s*$\n\|\%^\|^\[.*\]\s*$\n\)\@<=\(\[.*\]\)\@!\&\([^\.].*\)$'
let s:setext_title_underline = '[=\-~^+]\{2,}\s*$'
let s:setext_title = s:setext_title_text . '\n' . s:setext_title_underline
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
" Yes. It makes problem in other places. 0 should be topmost, 5 the lowest
" possible
" FIXME: When level 6 is selected in Setext style (which doesn't support
" it), fallback to ATX style.
" TODO: Provide function to increment/decrement current section.
function! asciidoc#motions#set_section_title_level(level) abort
  let line = line('.')
  let section_title = asciidoc#motions#get_section_title(line)
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
" Find the next section after the given {startline}.
" The given {searchflags} are the same as for the builtint search()
" function.
"
" Returns the line number of the next title (the upper line for setext
" titles) or 0 if no section title can be found after the given line.
" This function does not wrap at the end of the file.
function! asciidoc#motions#find_next_section_heading(start_line, search_flags) abort
  let l:old_pos = getpos('.')
  call setpos('.', [0, a:start_line, 0, 0])
  let l:next_atx = search(s:atx_title, a:search_flags)
  let l:next_setext = s:find_next_setext_section_title(a:start_line, a:search_flags)
  let l:next = min(filter([l:next_atx, l:next_setext], 'v:val != 0'))
  call setpos('.', l:old_pos)
  return l:next
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
endfunction

function! asciidoc#motions#is_setext_section_title(line_number) abort
   return !empty(asciidoc#motions#get_setext_section_title(a:line_number))
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
endfunction

function! s:get_atx_section_title(line_number) abort
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
endfunction

function! asciidoc#motions#get_setext_section_title(line_number) abort
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
endfunction

function! asciidoc#motions#get_section_title(line_number) abort
  let atx = s:get_atx_section_title(a:line_number)
  if !empty(atx)
    return atx
  else
    return asciidoc#motions#get_setext_section_title(a:line_number)
  endif
endfunction

""
" Return the level of the section title on the given line.
"
" The topmost level start at 1.
" FIXME: It should actually start at 0
"
" Attention! The return value is undefined if the given line number doesn't
" contain a section title.
function! asciidoc#motions#get_setext_section_title_level(line_number) abort
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
endfunction

""
" Return whether the given line is the underline under a Setext section
" header.
"
" Attention! This function assumes that the given line_number actually
" contains a Setext section title. If it is a valid Setext underline, but
" not acutally part of a Setext section title, it will still return 1.
function! asciidoc#motions#is_setext_underline(line_number) abort
  let line = getline(a:line_number)
  return line =~# '^' . s:setext_title_underline
endfunction

