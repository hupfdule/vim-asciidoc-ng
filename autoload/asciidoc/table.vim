""
" Text object for asciidoc tables.
"
" {scope}: 0 to include everything _between_ the table delimiters
"          1 to include everything _including_ the table delimiters
"          2 to include everything _including_ the table delimiters and the
"            prepended attributes and caption
" {visual}: whether this method was called from visual mode (this parameter
"           is actually not used).
function! asciidoc#table#text_object_table(scope, visual) abort
  " FIXME: How to handle the case when this is called _between_ two tables?
  "        How to detect this this abort early?
  "        We need to know some patterns then that are definitely invalid
  "        inside tables.
  " If no top delimiter can be found, do nothing
  let top = search('^|===', 'Wbn')
  if top ==# 0
    return
  endif

  " If no bottom delimiter can be found, do nothing
  let bot = search('^|===', 'Wn')
  if bot ==# 0
    return
  endif

  if a:scope ==# 0
    " Exclude table delimiters
    let top = top + 1
    let bot = bot - 1
  elseif a:scope ==# 2
    " Include attributes and caption
    call cursor(top, 0)
    " FIXME: This should be refined to only find lines not matching
    " '^\..*$' and not matching '^\[.*\]\s*$'.
    let prev_non_header = search('^[^\.\[]\|^\s*$', 'Wbn', top - 3)
    if prev_non_header
      let top = prev_non_header + 1
    endif
  endif

  call cursor(top, 0)
  normal! V
  call cursor(bot, 0)
  normal! $
endfunction
