" Vim autoload file
" vim-ft-asciidoc/autoload/base.vim

let s:macro_patterns = {
            \ 'include': '\f*\%#\f*',
            \ 'image': '\f*\%#\f*',
            \ 'kbd': '\S*\%#\S*',
            \ 'menu': '\S*\%#\S*',
            \ 'btn': '\S*\%#\S*',
            \ }

let g:list_prefix_pattern  = ''
let g:list_prefix_pattern .= '^\s*\%('                        " optional leading space
let g:list_prefix_pattern .= '\([\*\.]\+\)'                   " bulleted or numbered lists with increasing number of * or .
let g:list_prefix_pattern .= '\|'                             " or
let g:list_prefix_pattern .= '\(\-\)'                         " a single hyphen for a bulleted list
let g:list_prefix_pattern .= '\|'                             " or
let g:list_prefix_pattern .= '\('
let g:list_prefix_pattern .=   '\%([0-9]\+\.\)'               " decimal numbered list (1.)
let g:list_prefix_pattern .=   '\|'
let g:list_prefix_pattern .=   '\%([a-z]\+\.\)'               " lowercase alpha numbered list (a.)
let g:list_prefix_pattern .=   '\|'
let g:list_prefix_pattern .=   '\%([A-Z]\+\.\)'               " uppercase alpha numbered list (A.)
let g:list_prefix_pattern .=   '\|'
let g:list_prefix_pattern .=   '\%([ivx]\+)\)'                " lowercase roman numbered list (i))
let g:list_prefix_pattern .=   '\|'
let g:list_prefix_pattern .=   '\%([IVX]\+)\)'                " uppercase roman numbered list (I))
let g:list_prefix_pattern .= '\)'
let g:list_prefix_pattern .= '\)\s\+'                         " mandatory trailing whitespace

" A single-line ordered list item (or the first line of a multi-line one)
let g:ordered_list_item_pattern  = ''
let g:ordered_list_item_pattern .= '^\(\s*\)'                 " optional leading whitespace
let g:ordered_list_item_pattern .= '\('
let g:ordered_list_item_pattern .=   '[0-9]\+\.\@='           " arabic numbers
let g:ordered_list_item_pattern .=   '\|'
let g:ordered_list_item_pattern .=   '[a-z]\+\.\@='           " lowercase alpha letters
let g:ordered_list_item_pattern .=   '\|'
let g:ordered_list_item_pattern .=   '[A-Z]\+\.\@='           " uppercase alpha letters
let g:ordered_list_item_pattern .=   '\|'
let g:ordered_list_item_pattern .=   '[ivx]\+)\@='            " lowercase roman numbers
let g:ordered_list_item_pattern .=   '\|'
let g:ordered_list_item_pattern .=   '[IVX]\+)\@='            " uppercase roman numbers
let g:ordered_list_item_pattern .= '\)'
let g:ordered_list_item_pattern .= '\([\.\)]\)'               " either . or )
let g:ordered_list_item_pattern .= '\(\s\+.*\)$'              " the remainder of the line (with mandatory white space)

function! asciidoc#base#follow_cursor_link(...) abort " {{{
    let [type, link] = asciidoc#base#get_cursor_link()
    if link =~ '{[^}]*}'
        let link = asciidoc#base#expand_attributes(link)
    endif
    if type == 'link'
        let link = strpart(link, matchend(link, 'link::\?'), len(link))
        if link =~ '\[[^\]]*\]$'
            let link = strpart(link, 0, match(link, '\[[^\]]*\]$'))
        endif
    elseif type == 'xref'
        let link = link[2:-3]
        if link =~ ','
            let [link, title] = split(link, ',')
        endif
    endif

    if empty(type)
      " FIXME: This alway calls 'gf'. How about <c-w><c-f>? Can we find out
      " what the user actually used as keybinding?
      :normal! gf
    else
      if a:0
          return asciidoc#base#follow_link(link, type, a:1)
      else
          return asciidoc#base#follow_link(link, type)
      endif
    endif
endfunc " }}}

function! asciidoc#base#get_attribute(name) " {{{
" Get a single attribute value by name.
" Returns attribute name if no value was found.
    let res = get(asciidoc#base#parse_attributes(1), a:name, a:name)
    return res
endfunc " }}}

function! asciidoc#base#strip(s) abort " {{{
    return substitute(a:s, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunc " }}}

function! asciidoc#base#parse_attributes(refresh) " {{{
" Parse document attributes from current buffer.
    " Todo: use `search` instead
    if (exists('b:document_attributes') && !a:refresh)
        return b:document_attributes
    endif
    let b:document_attributes = {}
    let lines = getline(1, '$')
    let line_count = 0
    for line in lines
        let line_count = line_count + 1
        let m = matchlist(line, '^:\(\w\+\): \(.*\)$')
        if len(m) > 2
            let b:document_attributes[m[1]] = m[2]
        endif
    endfor
    let b:document_attributes['b'] = line_count
    return b:document_attributes
endfunc " }}}

function! asciidoc#base#expand_attributes(s) " {{{
" Expand attributes in a string.
    let res = substitute(a:s, '{\([^}]*\)}', '\=asciidoc#base#get_attribute(submatch(1))', 'g')
    return res
endfunc " }}}

function! asciidoc#base#get_cursor_link() abort "{{{
    " The pattern approach is taken from  https://vi.stackexchange.com/a/21112/21417
    let patterns = {
                \ 'xref': '\(.*\%#\)\@=\s*<<\([^>]\|>[^>]\)*>>\(\%#.*\)\@<=',
                \ 'link': '\(.*\%#\)\@=\s*link:[^[]*\[[^[]*\]\(\%#.*\)\@<='
    \ }
    let save_cursor = getcurpos()
    let link_type = ""
    let link = ""
    for [type, pattern] in items(patterns)
        if search(pattern, 'cn')
            let save_search = @/
            let save_reg = @"
            let @/ = pattern
            normal! ygn
            let link_type = type
            let link = trim(@")
            let @" = save_reg
            let @/ = save_search
            call setpos('.', save_cursor)
            break
        endif
    endfor
    return [link_type, link]
endfunc " }}}

function! asciidoc#base#follow_link(link, kind, ...) " {{{
    let link = a:link
    let kind = a:kind
    " FIXME: This method should also allow jumping to the target in the
    " current file (which should also be the default). This can be
    " accomplished by leaving the optional argument out.
    " Still needs to refine the creating of the resulting command.
    " Update: It already does. Param "edit" does it. However, it brings
    " an additional error about swapfile in use, if the current file is
    " already opened twice.
    let cmd = ""
    if kind ==# 'link'
        "let cmd = "!open " . link . " -a " . g:asciidoc_browser
        let cmd = "!" . g:asciidoc_preview_app . " " . link
    elseif kind ==# 'xref'
        if a:0
            if a:1 ==# 'split' || a:1 ==# 'vsplit' || a:1 ==# 'tabedit'
              let cmd = a:1 . " % | "
            else
              echohl ErrorMsg | echomsg 'Invalid command "' . a:1 . '"' | echohl None
              return
            endif
        endif
        let file = ""
        if link =~ '#'
            let target = split(link, '#')
            let file = target[0]
            let anchor = len(target) > 1 ? target[1] : ""
            if file !~ '/'
                let file = expand("%:p:h") . "/" . file
            endif
            if filereadable(file)
                if empty(cmd)
                  let cmd = 'edit '
                endif
                let cmd .= file
                if !empty(anchor)
                    let cmd .= '| /\[\[' . anchor . ']]'
                endif
            else
                let yn = confirm("File " . file . " does not exist. Edit it anyway?", "&Yes\n&No", 0, "Question")
                if yn == 1
                    if empty(cmd)
                      let cmd = 'edit '
                    endif
                    let cmd .= file . ' | normal! i[[' . anchor . ']]0'
                else
                    let cmd = ''
                endif
            endif
        else
            let search_pattern = '\V[[' . link . ']]\|[#' . link . ']'
            let target_line = search(search_pattern, 'w')
            " If no match is found, try to find matching section titles
            if target_line ==# 0
               " find section with exact title
               let l:target_pattern = '^' . link . '$'
               " find section title based on automatically generated id
               let l:relaxed_pattern = '\c\v[_ .-]*' . substitute(trim(link, '_ '), '_', '[_ .-]+', 'g')

               for l:pattern in [l:target_pattern, l:relaxed_pattern]
                 let target_line = asciidoc#motions#find_next_section_matching(l:pattern)
                 if target_line !=# 0
                   let cmd .= 'normal! ' . target_line . 'G'
                   break
                 endif
               endfor

               " if no valid target was found, don't do anything
               if target_line ==# 0
                  let cmd = ''
                  "echoerr 'No target found for ' . link " This looks too much like a stracktrace
                  echohl ErrorMsg | echomsg 'No target found for ' . link | echohl None
               endif
            endif
        endif
    endif
    echo cmd
    exe cmd
    return cmd
endfunc " }}}

""
" Converts the current word or the selection into the attributes of a macro
" without target.
"
" For example if the text 'Ctrl+\]' is selected in the following line:
"
"   Press Ctrl+\] to jump to a tag definition.
"
" calling this function as asciidoc#base#insert_macro_attrib('v', 'inline',
" 'kbd') would result in:
"
"   Press kbd:[Ctrl+\]] to jump to a tag definition.
"
" The cursor will be placed inside the brackets at the end of the
" attributes, but insert mode will not be started automatically.
"
" {mode} The vim mode in which to operate. May be either 'n' for normal
"        mode or 'v' for visual mode.
" {type} Whether to generate an inline macro (single colon) or a block
"        macro (double colon). May be either 'inline' or 'block'.
" {name} The name of the macro (the part before the colon(s), actually the
"        'target').
"        For example 'image' or 'include'.
"
" FIXME: Should this leave the user in insert mode afterwards?
" FIXME: It seems to have whitespace problems sometimes. Sometimes it adds
"        an additional space before the macro, sometimes it removes the
"        space after the macro and sometimes it does both. Also sometimes
"        it adds a space after the macro.
" FIXME: Use omnicompletion? Auto start completion menu?
" FIXME: Allow to operate on motions
" FIXME: Do not throw an error on unescaped ], but instead escape it.
" FIXME: Placing the cursor at the end of the attribute list my not be the
"        expected behaviour.
function! asciidoc#base#insert_macro_attribs(mode, type, name) abort " {{{
    " This first part (..else) is kind of dumb. It's a convenience, but is it really
    " worth it to make the function harder to read?
    let inline = ['i', 'in', 'inl', 'inli', 'inlin', 'inline'] " {{{
    let block  = ['b', 'bl', 'blo', 'bloc', 'block']
    if a:type == inline[(len(a:type)-1)]
        let type = 'inline'
    elseif a:type == block[(len(a:type)-1)]
        let type = 'block'
    else
        echoerr "invalid macro type (" . a:type . ")"
        return -1
    endif " }}}
    let name = a:name
    let target = ""
    let save_reg = getreg('a', 1, 1)
    let save_reg_type = getregtype('a')
    let save_search = @/
    let viz_eol = a:mode != 'n' && col("'>") < (col("$") - 1)
    if a:mode == 'n'
        let @/ = get(s:macro_patterns, a:name, '\w*\%#\w*')
        execute 'normal! gn"ad'
    elseif a:mode == 'v'
        execute 'normal! gv"ad'
    else
        echoerr "invalid mode (" . a:mode . ")"
    endif
    call setreg('a', '', 'ac')
    let quoted_attribs = split(@a, ', \?')
    let attribs = []
    for attrib in quoted_attribs
        call add(attribs, substitute(attrib, "^'\|'$", '', ''))
    endfor
    let @a = <SID>insert_macro(type, name, target, attribs)
    if viz_eol
        normal! "aP
    else
        normal! "ap
    endif
    call setreg('a', save_reg, save_reg_type)
    let @/ = save_search
endfunc " }}}

""
" Converts the current word or the selection into the target of a macro.
"
" For example if the cursor in somewhere inside the word 'icon.png'
" in the following line:
"
"   See this nice icon.png inline image.
"
" calling this function as asciidoc#base#insert_macro_target('n', 'inline',
" 'image') would result in:
"
"   See this nice image:icon.png[] inline image.
"
" The cursor will be placed inside the brackets, but insert mode will not
" be started automatically.
"
" {mode} The vim mode in which to operate. May be either 'n' for normal
"        mode or 'v' for visual mode.
" {type} Whether to generate an inline macro (single colon) or a block
"        macro (double colon). May be either 'inline' or 'block'.
" {name} The name of the macro (the part before the colon(s), actually the
"        'target').
"        For example 'image' or 'include'.
"
" FIXME: Should this leave the user in insert mode afterwards?
" FIXME: It seems to have whitespace problems sometimes. Sometimes it adds
"        an additional space before the macro, sometimes it removes the
"        space after the macro and sometimes it does both. Also sometimes
"        it adds a space after the macro.
" FIXME: Use omnicompletion? Auto start completion menu?
" FIXME: Allow to operate on motions
function! asciidoc#base#insert_macro_target(mode, type, name) abort " {{{
    " This first part (..else) is kind of dumb. It's a convenience, but is it really
    " worth it to make the function harder to read?
    let inline = ['i', 'in', 'inl', 'inli', 'inlin', 'inline'] " {{{
    let block  = ['b', 'bl', 'blo', 'bloc', 'block']
    if a:type == inline[(len(a:type)-1)]
        let type = 'inline'
    elseif a:type == block[(len(a:type)-1)]
        let type = 'block'
    else
        echoerr "invalid macro type (" . a:type . ")"
        return -1
    endif " }}}
    let attribs = []
    let save_reg = getreg('a', 1, 1)
    let save_reg_type = getregtype('a')
    let save_search = @/
    let viz_eol = col("'>") < (col("$") - 1)
    if a:mode == 'n'
        let @/ = get(s:macro_patterns, a:name, '\w*\%#\w*')
        execute 'normal! gn"ad'
    elseif a:mode == 'v'
        execute 'normal! gv"ad'
    else
        echoerr "invalid mode (" . a:mode . ")"
    endif
    call setreg('a', '', 'ac')
    let target = @a
    let @a = <SID>insert_macro(type, a:name, @a, attribs)
    if viz_eol
        normal! "aP
    else
        normal! "ap
    endif
    call setreg('a', save_reg, save_reg_type)
    let @/ = save_search
endfunc " }}}

function! asciidoc#base#create_xref(mode) abort " {{{
" The function uses a normal mode command to wrap text in <<,>>.
" It operates either on the word under the cursor or on a visual selection.
    if a:mode == 'v'
        let mode = visualmode()
        if mode == 'v'
            execute "normal gvy"
            let sub = <SID>escape_linkname(@")
            execute "normal `>a>>`<i<<" . sub . ", "
        elseif mode == 'V'
            execute "normal gvy"
            let sub = <SID>escape_linkname(@")
            execute "normal A>>I<<" . sub . ", "
        endif
    elseif a:mode == 'n'
        execute "normal viwy"
        let sub = <SID>escape_linkname(@")
        execute "normal `>a>>`<i<<" . sub . ", "
    endif
endfunc " }}}

""
" FIXME: This comment is not valid yet. Implementaion needs to be changed.
"        Also the varargs will not work with delim-count
" Insert a block delimited with the given delimiter char.
"
" {mode} The mode this function was called in. May be either 'i' for insert
"        mode, 'n' for normal mode or 'v' visual mode.
" {delim} The delimiter to use for surrounding.
" [delim-count] How many delimiter chars to use. May be either 'textwidth'
"        to respect the current value of the |textwidth| vim setting or a positive
"        number indicating the number of characters to use. If omitted the value
"        of g:asciidoc_block_delimiter_length is used.
function! asciidoc#base#insert_paragraph(mode, delim, ...) abort " {{{
    let delim = a:delim
    if a:mode == 'i' || a:mode == 'n'
        let line_before = line('.') - 1
        let line_after = line('.')
        let append_before = getline(line('.') - 1) == "" ? [delim] : ["", delim]
        let append_after = getline(line('.') + 1) == "" ? [delim] : [delim, ""]
    elseif a:mode == 'v'
        let line_before = line("'<") - 1
        let line_after = line("'>")
        let append_before = getline(line("'<'") - 1) == "" ? [delim] : ["", delim]
        let append_after = getline(line("'>") + 1) == "" ? [delim] : [delim, ""]
    endif
    call append(line_after, append_after)
    call append(line_before, append_before)
    if a:0
        let cmd = "normal! 2ko["
        for ix in range(0, len(a:000) - 1)
            let cmd .= a:000[ix]
            if ix < (len(a:000) - 1)
                let cmd .= ", "
            endif
        endfor
        let cmd .= "]\<Esc>"
        if len(a:000) > 1
            let cmd .= "0Wvt]"
        else
            let cmd .= "2j0"
        endif
        execute cmd
        " if len(a:000) == 1 | startinsert | endif
        if a:mode == 'i' | startinsert | endif
    endif
endfunc " }}}

function! asciidoc#base#insert_table(mode) abort " {{{
    if a:mode == 'i'
        execute "normal! i|===\<CR>|\<CR>|===\<Up>"
    elseif a:mode == 'n'
        execute "normal! O|===\<Esc>"
        if getline(line('.') - 1) !~ '^$'
            execute "normal! O\<Esc>j"
        endif
        execute "normal! j0i| \<Esc>o|===\<Esc>"
        if getline(line('.') + 1) !~ '^$'
            execute "normal! o\<Esc>k"
        endif
        execute "normal! 2k02l"
    elseif a:mode == 'v'
        execute "normal! \<Esc>`>o|===\<Esc>"
        if getline(line('.') + 1) !~ '^$'
            execute "normal! o\<Esc>k"
        endif
        execute "normal! `<O|===\<Esc>"
        if getline(line('.') - 1) !~ '^$'
            execute "normal! O\<Esc>j"
        endif
        execute "'<,'>s/.*/| \\0/"
        execute "nohlsearch"
    else
        echoerr "invalid mode (" . a:mode . ")"
    endif
endfunc " }}}

function! s:insert_macro(type, name, target, attribs) abort " {{{
    let name = a:name
    if a:type == "block"
        let colon = "::"
    elseif a:type == "inline"
        let colon = ":"
    else
        echoerr "invalid macro type (" . a:type . ")"
        return -1
    endif
    if !<SID>validate_macro_name(name)
        echoerr "invalid macro name (" . name . ")"
        return -1
    endif
    let attribs = <SID>validate_macro_attribs(a:attribs)
    if type(attribs) != type([])
        echoerr "attributes may not contain unescaped ']' (" . string(a:attribs) . ")"
        return -1
    endif
    let target = <SID>escape_macro_target(a:target)
    let macro = name . colon . target . '[' . join(attribs, ', ') . ']'
    " echo macro
    return macro
endfunc " }}}

function! s:validate_macro_name(name) abort " {{{
    " may not start with a dash
    " may not include any char other than letters, digits and dashes
    return a:name !~ '^-' && a:name !~ '[^-[:alnum:]]'
endfunc " }}}

function! s:validate_macro_attribs(attribs) abort " {{{
    " Attribute may not contain an unescaped `]`.
    for attrib in a:attribs
        if string(attrib) =~ '[^\\]\]'
            return -1
        endif
    endfor
    return a:attribs
endfunc " }}}

function! s:escape_linkname(unsub) abort " {{{
    let sub = a:unsub
    let sub = substitute(sub, '\n', '', 'g')
    let sub = substitute(sub, '^[ \t\\.,!?;:/]\+', '', 'g')
    let sub = substitute(sub, '[ \t\\.,!?;:/]\+$', '', 'g')
    let sub = substitute(sub, '[ \t\\.,!?;:/]\+', '-', 'g')
    return sub
endfunc " }}}

function! s:escape_macro_target(target) abort " {{{
    return substitute(a:target, ' ', '%20', 'g')
endfunc " }}}

function! asciidoc#base#custom_jump(motion, visual) range " {{{
    let cnt = v:count1
    let save_search = @/
    mark '
    while cnt > 0
        silent! execute a:motion
        let cnt = cnt - 1
    endwhile
    call histdel('/', -1)
    if (a:visual)
        let save_pos = getcurpos()
        normal! ''V
        call setpos('.', save_pos)
    endif
    let @/ = save_search
endfunction "}}}

