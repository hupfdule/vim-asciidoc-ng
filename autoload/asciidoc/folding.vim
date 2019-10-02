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
" TODO: Optionally allow flat folding (ommiting the nesting and placing
"       everything on the same level.
"
" Based on https://github.com/jjaderberg/vim-ft-asciidoc which itself is
" derived from https://github.com/mjakl/vim-asciidoc
function! asciidoc#folding#foldexpr(lnum)
    let l0 = getline(a:lnum)
    " FIXME: This doesn't work with dagwieers syntax file, because it uses
    " different syntax names.
    " FIXME: Why checking for '^=' additionally to the synIDattr?
    if l0 =~ '^=\{1,6}\s\+\S.*$' && synIDattr(synID(a:lnum, 1, 1), "name") =~ "asciidoc.*Title"
        " ATX style titles
        return '>'.matchend(l0, '^=\+')
    " FIXME: Why not use synIDattr with setext too?
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

