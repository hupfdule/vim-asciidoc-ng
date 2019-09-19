" ATX title line without leading and trailing level indicators
" Used to strip any secondary anchors
let s:secondary_anchors = '\(\[\[[A-Za-z_:][A-Za-z_:0-9\-\.]*\]\]\)*'
" FIXME: The matching group for the actual title is too greedy. It contains
" any trailing secondary anchors. However using \{-\} leads to even worse
" results. Then the actual title is missing and it matches the anchors
" instead.
let s:atx_title_line = s:secondary_anchors . '\s*\(.*\)\ze\s*' . s:secondary_anchors

function! asciidoc#completion#omnicomplete(findstart, base) abort
  if a:findstart
    " locate the position after the "<<"
    let l:line = getline('.')
    let l:start = col('.') - 1
    let b:completion_type = ''
    while l:start > 0
      " FIXME: Wir könnten auch noch nach andere Completions erlauben
      if l:line[l:start - 1] ==# '<' && l:line[l:start - 2] ==# '<'
        let b:completion_type = 'xref'
        break
      else
        let l:start -= 1
      endif
    endwhile
    " TODO: We should return some other value, if we cannot detect what to
    " omnicomplete. Or do some default?
    if empty(b:completion_type)
      echo "Don't know what to complete."
      return -3
    else
      return l:start
    endif
  else
    " TODO: Hier muss jetzt gesucht werden.
    if b:completion_type ==# 'xref'
      " TODO: It would be nice to provide some way of "fuzzy" matching. But
      " the problem is that it would insert the full entry after selection
      " and the "fuzzy term" would have vanished.
      let l:all_section_headers = s:getAllSectionHeaders()
      return filter(l:all_section_headers, {idx, val -> stridx(val['word'], a:base) == 0 })
    else
      " FIXME: Throw an exception instead?
      echoerr 'Invalid completion type: ' . b:completion_type
    endif
  endif
endfunction


function! s:getAllSectionHeaders() abort
  let l:all_section_headers = []

  let l:next_section_header_line = asciidoc#motions#find_next_section_heading(0, 'Wnc')
  while l:next_section_header_line !=# 0
    let l:next_section_header = asciidoc#motions#get_section_title(l:next_section_header_line)

    let l:submatches =  matchlist(l:next_section_header['title'], s:atx_title_line)

    let l:title = l:next_section_header['title']
    if !empty(l:submatches) && !empty(l:submatches[2])
      let l:title = l:submatches[2]
    endif

    let l:section_header_info= {}
    " FIXME: If there is an explicit anchor we need to use that one as the
    " default will not be available.
    " The actual section title is the completion word
    let l:section_header_info['word'] = l:title
    " alternative text to be displayed in the menu
    let l:section_header_info['abbr'] = repeat('=', l:next_section_header['level']) . ' ' . l:title
    " extra text display after 'word' in the menu (may be truncted)
    "let l:section_header_info['menu'] = 'lvl ' . l:next_section_header['level']
    " TODO: Put the first paragraph into the info field to be available in
    " the preview window
    let l:section_header_info['info'] = '...' " extra text for the preview window
    "l:section_header_info['kind'] = 'm'   " member of struct or class (v=variable, f=function, t=typedef, d=macro)
    let l:section_header_info['dup']  = '...' " Include, even if the same 'word' already exists
    "l:section_header_info['user_data']  = '...' " custom data, available in v:completed_item

    call add(l:all_section_headers, l:section_header_info)

    let l:next_section_header_line = asciidoc#motions#find_next_section_heading(l:next_section_header_line, 'Wn')
  endwhile

  return l:all_section_headers
endfunction
