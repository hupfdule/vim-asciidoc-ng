""
" Text object for asciidoc delimited blocks.
"
" {scope}: 0 to include everything _between_ the block delimiters
"          1 to include everything _including_ the block delimiters
"          2 to include everything _including_ the block delimiters and the
"            prepended metadata and block title
" {visual}: whether this method was called from visual mode (this parameter
"           is actually not used).
function! asciidoc#textobjects#delimited_block(scope, visual) abort
  " FIXME: How to handle the case when this is called _between_ two blocks?
  "        How to detect this this abort early?
  "        We need to know some patterns then that are definitely invalid
  "        inside blocks.
  " FIXME: If the cursor is on or outside the delimiters, this doesn't find
  "        anything. We would not know if the current delimiter is the top
  "        or the bottom one.
  " If no top delimiter can be found, do nothing
  let top = search('^[\=\-\.\+\_\*\/\`]\{4,}\s*\|^--\s*$', 'Wbn')
  if top ==# 0
    return
  endif
  let top_delim = trim(getline(top))

  " search for the exact same closing delimiter
  let bot = search('\V' . escape(top_delim, '/'), 'Wn')
  " If no bottom delimiter can be found, do nothing
  if bot ==# 0
    return
  endif

  if a:scope ==# 0
    " Exclude block delimiters
    let top = top + 1
    let bot = bot - 1
  elseif a:scope ==# 2
    " Include metadata and title
    call cursor(top, 0)
    echo "top: " . top
    " FIXME: This should be refined to only find lines not matching
    " '^\..*$' and not matching '^\[.*\]\s*$'.
    let prev_non_header = search('^[^\.\[]\|^\s*$', 'Wbn', top - 3)
    echo "prev_non_header: " . prev_non_header
    if prev_non_header
      let top = prev_non_header + 1
    endif
  endif

  call cursor(top, 0)
  normal! V
  call cursor(bot, 0)
  normal! $
endfunction

