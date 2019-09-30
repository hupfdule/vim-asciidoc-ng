"" {{{2
"
"
function! asciidoc#toc#toc() abort " {{{1
  let l:save_pos = getpos('.')

  " Find all section headings
  let l:section_titles = []
  let l:section_title_line = asciidoc#motions#find_next_section_heading(1, 'Wcn')

  while l:section_title_line !=# 0
    let l:section_title = asciidoc#motions#get_section_title(l:section_title_line)
    call add(l:section_titles, l:section_title)
    let l:section_title_line = asciidoc#motions#find_next_section_heading(l:section_title_line, 'Wn')
  endwhile

  call setpos('.', l:save_pos)

  " calculate the section numbers
  call s:calc_sectnum(l:section_titles)

  " Put the entries in the loclist
  call map(l:section_titles, function('s:map_to_loclist_entry'))
  call setloclist(0, l:section_titles)

  " Adjust the height / width to have all text visible, but at max the half
  " of the available space
  if g:asciidoc_toc_position == "top" || g:asciidoc_toc_position == "bottom"
    let size = min([winheight('.') / 2, len(l:section_titles)])
  else
    let longestentry = 10
    for entry in l:section_titles
      let longestentry = max([longestentry, len(entry['text'])])
    endfor
    let size = min([winwidth('.') / 2, longestentry]) + 1
  endif

  " Open the location list with the TOC
  if g:asciidoc_toc_position == "right"
      let toc_pos = "vertical"
  elseif g:asciidoc_toc_position == "left"
      let toc_pos = "topleft vertical"
  elseif g:asciidoc_toc_position == "top"
      let toc_pos = "topleft"
  elseif g:asciidoc_toc_position == "bottom"
      let toc_pos = "botright"
  else
      let toc_pos == "vertical"
  endif
  try
      exe toc_pos " " . size . " lopen"
  catch /E776/ " no location list
      echohl ErrorMsg
      echo "No entries for TOC found"
      echohl None
      return
  endtry

  " Now reformat the loclist
  setlocal modifiable
  silent %s/\v^([^|]*\|){2,2}//e
  setlocal nomodified
  setlocal nomodifiable
  setlocal linebreak
  setlocal nowrap
  setlocal norelativenumber
  setlocal nonumber

  " Rehighlight the loclist buffer
  " FIXME: This doesn't work. Why?
  syntax match asciidocTocLine       /^.*\n/
  syntax match asciidocTocSectNum    /^\s*\zs\[\d\.]\+\ze\s*/ containedin=asciidocTocLine

  highlight link asciidocTocLine Normal
  highlight link asciidocTocSectNum Keyword

  noremap <buffer> q :lclose<cr>

  normal! gg
endfunction " }}}1

"" {{{2
" Calculate the section numbering for the given {section_titles}.
"
" The calculated section numbering is added to the entries of the given
" section_titles with the key 'sectnum'.
"
" @parem {section_titles} A list of section titles. Each entry must be a
"                         dictionary containing the 'level' and 'title' of
"                         the section title.
"
" FIXME: Use A,B, etc. for section headings marked with [appendix]
" FIXME: Leave sectnum out for Glossary, Bibliography, Index, etc.
function! s:calc_sectnum(section_titles) abort " {{{1
  let l:section_number = []
  let l:max_sectnum_length = 0

  " calculate the section numbering
  for l:section_title in a:section_titles
    let l:level = l:section_title['level'] - 1
    if l:level < len(l:section_number)
      while l:level < len(l:section_number)
        call remove(l:section_number, -1)
      endwhile
      if len(l:section_number) > 0
        let l:section_number[-1] += 1
      endif
    elseif l:level > len(l:section_number)
      while l:level > len(l:section_number)
        call add(l:section_number, 1)
      endwhile
    else
      if l:level > 0
        let l:section_number[-1] += 1
      else 
        call add(l:section_number, 1)
      endif
    endif


    let l:number_string = join(l:section_number, '.')
    if len(l:number_string) > l:max_sectnum_length
      let l:max_sectnum_length = len(l:number_string)
    endif

    let l:section_title['sectnum'] = l:number_string
  endfor

  " Add the sectnum to the section title
  for l:section_title in a:section_titles
    " TODO: Also add the file + linenr in the output (configurable)
    " Example:
    "      My large Book ...........       1
    " 1    Introduction ............       20
    " 1.1  The Why .................       32
    " 1.2  The How .................       54
    " 1.3  The Who .................       102
    " 2    Closing ................. other#3
    " 2.1  Bye ..................... other#32
    " A    I've been the appendix ..       143
    " A.1  Happened before .........       193
    " A.2  Happened after ..........       249
    " B    Glossary ................ gloss#304
    let l:section_title['f_sectnum'] = printf('%-' . l:max_sectnum_length . 'S', l:section_title['sectnum'])
  endfor
endfunction " }}}1

function! s:map_to_loclist_entry(idx, section_title) abort " {{{1
  let l:loclist_entry= {}
  let l:loclist_entry['bufnr'] = bufnr()
  let l:loclist_entry['lnum'] = a:section_title['line']
  let l:loclist_entry['col'] = 0
  let l:loclist_entry['text'] = a:section_title['f_sectnum'] . '  ' . a:section_title['title']

  return l:loclist_entry
endfunction " }}}1
