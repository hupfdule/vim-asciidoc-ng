""
" Converts the currently selected lines into list items preceded by the
" character given as {type}..
"
" FIXME: This is a bit dumb as it converts each line to another list item.
" There is no way to retain paragraphs or other complex content.
" Should this be changed?
function! asciidoc#lists#make_list(type) range abort
  let old_search = @/
  exe a:firstline . ',' . a:lastline . 's/^\s*\([*.]*\)\s*/\=repeat("' . a:type . '", max([1, len(submatch(1))]))." "/'
  let @/ = old_search
endfunction

""
" Indent or outdent the selected list items.
" If {in_out} is 'in' the selected items will get indented (one level
" deeper) otherwise they get outdented.
"
" FIXME: This only works for "*" and "." bullets. All other (valid)
" characters are ignored. This needs to be changed.
" It should support
"  - bullets as '-' characters (depending on some
"    g:asciidoc_bulletted_list_formats = ['-', '*'] variable)
"    Attention! While it works in other cases, this makes only sense if '-'
"    is the first level and '*' is used for all subsequent levels.
"  - "real" numbered lists (e.g. 1., a., i), A., I)) depending on some g:
"    g:asciidoc_numbered_list_formats = ['1.', 'a.', 'i)', 'A.', 'I)', '.'] variable
"  - use indentation to visually clarify the structure (based on some
"    g:asciidoc_list_item_indentation = 1 setting)
function! asciidoc#lists#dent_list(in_out) range abort
  let old_search = @/
  if a:in_out == 'in'
    silent! exe a:firstline . ',' . a:lastline . 's/^[*.]//'
  else
    silent! exe a:firstline . ',' . a:lastline . 's/^\([*.]\)/&&/'
  endif
  let @/ = old_search
endfunction

""
" Append a new list item after the current one at the cursor position.
"
" The new list item gets the same indent as spacing after the list item
" prefix as the current one and the same style.
" If the current list item is an ordered list item its number will be
" increased (unless g:asciidoc_list_number_style_increasing is 0).
"
" Attention! This function currently only works with single-line list
" items.
"
" FIXME: We will also need a function + mapping to increase / decrease the
" level of
"  - the current item
"  - the selected item range
" FIXME: It doesn't work with CLI vim! See https://stackoverflow.com/questions/16359878
" and https://vi.stackexchange.com/questions/13328
" It does work if the terminal supports differentiation. Not really nice,
" but a solution for some people.
" <s-cr> can still be the default mapping. We should document the problems
" with CLI vim and mention that this cn be changed. We provide a
" <Plug>-mapping anyway.
" Damn! It doesn't even work in gvim!
" FIXME: This doesn't work if called on a multi-line list item.
"        However this should be possible.
function! asciidoc#lists#append_list_item() abort "{{{
    let syntax_name = synIDattr(synID(line('.'), 1, 1), "name")
    let save_reg = @"
    let save_search = @/
    if syntax_name =~? "table"
        execute "normal! o| "
        startinsert!
    elseif syntax_name =~? "list"
        let @" = ""
        call append(line('.'), '')
        let line = getline(line('.'))
        let list_prefix = matchstr(line, g:list_prefix_pattern)
        let @" = list_prefix
        normal! j0P$

        if g:asciidoc_list_number_style_increasing
          call asciidoc#lists#increase_list_item_prefix(line('.'))
        endif

        startinsert!
    endif
    let @/ = save_search
    let @" = save_reg
endfunc "}}}


""
" Increase the number of the numbered list item on line {line}.
" Does nothing if the given {line} doesn't contain a numbered list item.
"
" @param {line} the line containing the single-line numbered list item
"        or the first line of a multi-line one
"
" TODO: Should this function also work when the given {line} is somewhere
"       in multi-line list item? I think it is better to handle this case
"       outside of this function.
" TODO: Handle the case when the number of characters need to be increased?
"       e.g. when increasing from 9 to 10. We need to adjust all other list
"       items then. For example from
"       9. first
"       9. second
"       to
"        9. first
"       10. second
"       Actually, I don't think so. There should be an extra function
"       providing that formatting logic, but it should be called by the
"       user.
function! asciidoc#lists#increase_list_item_prefix(line) abort
  let l:matchlist = matchlist(getline(a:line), g:ordered_list_item_pattern)
  if empty(l:matchlist)
    return
  endif

  let l:list_item_number = l:matchlist[2]
  if empty(l:list_item_number)
    return
  endif

  if l:list_item_number =~# '\d\+'
    " arabic numbers
    let l:matchlist[2] = l:list_item_number + 1
  elseif l:matchlist[3] ==# ')'
    " roman numbers
    " TODO: Find a good algorighm to increase roman numbers
    echo "Increasing roman numbers is not yet implemented"
  elseif l:matchlist[3] ==# '.'
    " alphabetic characters
    let l:matchlist[2] = nr2char(char2nr(l:matchlist[2]) + 1)
  endif

  " now replace the line with the modified one
  call setline(a:line, l:matchlist[1] . l:matchlist[2] . l:matchlist[3] . l:matchlist[4])
endfunction

