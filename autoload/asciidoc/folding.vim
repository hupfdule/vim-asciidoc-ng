""
" Return the fold level of the given line.
"
" Currently only allows folding of section headings.
"
" TODO: Extend to support folding of
"         - document header
"         - blocks
"
" TODO: At the moment this function incorrectly identifies some code blocks
"       as section titles if they are preceded by any non-empty line.
"
"
" Based on https://github.com/jjaderberg/vim-ft-asciidoc which itself is
" derived from https://github.com/mjakl/vim-asciidoc
function! asciidoc#folding#foldexpr(lnum)
    let l0 = getline(a:lnum)
    if l0 =~ '^=\{1,6}\s\+\S.*$' && synIDattr(synID(a:lnum, 1, 1), "name") =~ "asciidoc.*Title"
        " ATX style titles
        return '>'.matchend(l0, '^=\+')
    elseif asciidoc#motions#is_setext_section_title(a:lnum)
        " Setext style titles
        " FIXME: Wir _müssen_ den Beginn der Sektion ">" angeben.
        let l:setext_level = asciidoc#motions#get_setext_section_title_level(a:lnum)
        " FIXME: this function never returns -1…
        if l:setext_level != -1
          let l:is_underline = asciidoc#motions#is_setext_underline(a:lnum)
          if l:is_underline
            return l:setext_level
          else
            return '>'.l:setext_level
          endif
        endif
    else
        return '='
    endif
endfunction
