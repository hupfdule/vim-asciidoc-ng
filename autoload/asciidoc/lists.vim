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
function! asciidoc#lists#dent_list(in_out) range abort
  let old_search = @/
  if a:in_out == 'in'
    silent! exe a:firstline . ',' . a:lastline . 's/^[*.]//'
  else
    silent! exe a:firstline . ',' . a:lastline . 's/^\([*.]\)/&&/'
  endif
  let @/ = old_search
endfunction

