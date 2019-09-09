" Vim autoload file
" vim-ft-asciidoc/autoload/asciidoc.vim

" Foldexpr function {{{
" From https://github.com/mjakl/vim-asciidoc/
" Removed conditional fold options.
" Fixed to avoid matching every line starting with `=`, and to skip title lines
" within literal et. al. blocks.
function! asciidoc#folding#foldexpr(lnum)
    let l0 = getline(a:lnum)
    if l0 =~ '^=\{1,5}\s\+\S.*$' && synIDattr(synID(a:lnum, 1, 1), "name") =~ "asciidoc.*Title"
        return '>'.matchend(l0, '^=\+')
    else
        return '='
    endif
endfunc " }}}

function! asciidoc#folding#foldexpr2(lnum)
    let l0 = getline(a:lnum)
    if l0 =~ '^=\{1,5}\s\+\S.*$' && synIDattr(synID(a:lnum, 1, 1), "name") =~ "asciidoc.*Title"
        " ATX style titles
        return '>'.matchend(l0, '^=\+')
    elseif asciidoc#motions#is_setext_section_title(a:lnum)
        " Setext style titles
        " FIXME: Wir _müssen_ den Beginn der Sektion ">" angeben.
        let l:setext_level = asciidoc#motions#get_setext_section_title_level(a:lnum)
        " FIXME: this function never returns -1…
        echom "setext level: " . l:setext_level
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
