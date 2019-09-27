"" {{{2
"
"
function! asciidoc#toc#toc() abort " {{{1
  let l:save_pos = getpos('.')

  let l:section_titles = []
  let l:section_title_line = asciidoc#motions#find_next_section_heading(1, 'Wcn')

  while l:section_title_line !=# 0
    let l:section_title = asciidoc#motions#get_section_title(l:section_title_line)
    call add(l:section_titles, l:section_title)
    let l:section_title_line = asciidoc#motions#find_next_section_heading(l:section_title_line, 'Wn')
  endwhile

  call s:calc_sectnum(l:section_titles)

  call setpos('.', l:save_pos)
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
  let l:longest_number = 0

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
      endif
    endif

    let l:number_string = join(l:section_number, '.')
    if len(l:number_string) > l:longest_number
      let l:longest_number = len(l:number_string)
    endif

    let l:section_title['sectnum'] = l:number_string
  endfor

  " Add the sectnum to the section title
  for l:section_title in a:section_titles
    let l:section_title['f_sectnum'] = printf('%-' . l:longest_number . 'S', l:section_title['sectnum'])
  endfor

  " Put the entries in the loclist
  call map(a:section_titles, function('s:map_to_loclist_entry'))
  call setloclist(0, a:section_titles)

  lopen

  " Now reformat the loclist
  set modifiable
  silent %s/\v^([^|]*\|){2,2}//e
  set nomodified
  set nomodifiable

  " Rehighlight the loclist buffer
  " FIXME: This doesn't work. Why?
  syntax clear
  syntax sync fromstart
  syntax match asciidocTocLine       /^.*\n/
  syntax match asciidocTocSectNum    /^\s*\zs\[\d\.]\+\ze\s*/ containedin=asciidocTocLine
  syntax keyword zehn 10 contained
  syntax on

  highlight link asciidocTocLine Normal
  highlight link asciidocTocSectNum Keyword
  highlight link zehn Label

  noremap <buffer> q :lclose<cr>
endfunction " }}}1

function! s:map_to_loclist_entry(idx, section_title) abort " {{{1
  let l:loclist_entry= {}
  "FIXME: How to get the buffer number?
  let l:loclist_entry['bufnr'] = 4
  let l:loclist_entry['lnum'] = a:section_title['line']
  let l:loclist_entry['col'] = 0
  let l:loclist_entry['text'] = a:section_title['f_sectnum'] . '  ' . a:section_title['title']

  return l:loclist_entry
endfunction " }}}1
