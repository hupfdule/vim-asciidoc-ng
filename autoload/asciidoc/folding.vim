""
" Return the fold level of the given line.
"
" Currently only allows folding of section headings.
"
" TODO: Extend to support folding of
"         - document header
"         - blocks
"
" TODO: Optionally allow flat folding (ommiting the nesting and placing
"       everything on the same level.
function! asciidoc#folding#foldexpr(lnum)
    let l0 = getline(a:lnum)
    if asciidoc#motions#is_atx_section_title(a:lnum)
        " ATX style titles
        let l:atx_level = asciidoc#motions#get_atx_section_title_level(a:lnum)
        return '>' . l:atx_level
    elseif asciidoc#motions#is_setext_section_title(a:lnum)
        " Setext style titles
        let l:setext_level = asciidoc#motions#get_setext_section_title_level(a:lnum)
        let l:is_underline = asciidoc#motions#is_setext_underline(a:lnum)
        if l:is_underline
          return l:setext_level
        else
          return '>' . l:setext_level
        endif
    else
        return '='
    endif
endfunction

""
" Prints the fold levels for all lines in the current file.
" Also displays any errors on folding.
" Taken from https://vi.stackexchange.com/a/19916/21417
function! asciidoc#folding#debug() abort
  let fold_levels = map(range(1, line('$')), 'v:val . "\t" . asciidoc#folding#foldexpr(v:val) . "\t" . getline(v:val)')
  for fl in fold_levels
    echo fl
  endfor
endfunction

