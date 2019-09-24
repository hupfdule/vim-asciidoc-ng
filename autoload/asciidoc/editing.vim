let g:setext_to_atx = {
            \ '=': '=',
            \ '-': '==',
            \ '~': '===',
            \ '^': '====',
            \ '+': '=====',
            \ }

let g:atx_to_setext = {
            \ '='    : '=',
            \ '=='   : '-',
            \ '==='  : '~',
            \ '====' : '^',
            \ '=====': '+',
            \ }

"" {{{2
" Surround the selected text or the word under the cursor with the given
" {fchar}.
"
" If the selected text doesn't end at word boundaries, it doubles the
" {fchar} to create an unconstrained quote.
"
" FIXME: In line-wise visual mode, it wraps leading (and trailing?)
" whitespace. I think that this is normally not desired.
" FIXME: Also block-wise visual mode works as if character-wise visual
" mode was used. What would be expected? I think the visual selection for
" each line should be surrounded, like from
"
" first term
" secnd term
" third term
" forth term
"
" to
"
" *first* term
" *secnd* term
" *third* term
" *forth* term
"
" if the visual block was put around the words in the first column.
" FIXME: Also it seems that normal mode is misidentified as v-mode.
"        But still it behaves correctly…
" FIXME: V does include the line ending. Actually leading and trailing
" whitespace should always be omitted.
function! asciidoc#editing#format_text(fchar) abort " {{{1
    let mode = visualmode()
    let save_reg = getreg('a', 1, 1)
    let save_reg_type = getregtype('a')
    let char = a:fchar
    " If the selected area is not around a word boundary, double the fchar
    " to create unconstrained quotes
    if mode == 'v'
        let p1 = '\w\%' . col("'<") . 'c'
        let p2 = '\%' . col("'>") . 'c.\w'
        let m1 = match(getline("'<"), p1)
        let m2 = match(getline("'>"), p2)
        if -1 != m1 || -1 != m2
            let char .= char
        endif
    endif
    execute 'normal! gv"ay'
    call setreg('a', '', 'ac')
    let text = @a
    let @a = char . text . char
    execute "silent normal! `>a=char`<i=char"
    call setreg('a', save_reg, save_reg_type)
endfunc " }}}

"" {{{2
" Reformat a block of text to 1 sentence per line.
"
" If called in visual mode it reformats the selected lines of text.
"
" If called in normal mode it reformats the current paragraph.
"
" @param {mode} 'n' if this function was called from normal mode or 'v' if
"               it was called in visual mode.
function! asciidoc#editing#sentence_per_line(mode) range abort " {{{1
    let save_cursor = getcurpos()
    if a:mode == 'n'
        let pat = '^$\|^[-_.*+=]\{2}'
        let bot = search(pat, 'n') - 1
        let top = search(pat, 'bn') + 1
        if top != bot
            execute ":" . top
            execute 'normal! V' . (bot - top) . 'jJ0'
        endif
    elseif a:mode == 'v'
        " Join all lines, retaining all blank lines. Idea was taken from https://superuser.com/a/200691/730833
        " We also unset joinspace to avoid double spaces between the
        " sentences (which would leave trailing whitespace characters)
        let save_tw = &textwidth
        let save_js = &joinspaces
        setlocal textwidth=9999999
        setlocal nojoinspaces
        normal! gvgqg'<
        let &textwidth=save_tw
        let &joinspaces=save_js
        unlet save_tw
        unlet save_js
    else
      echoerr "Invalid mode: " . a:mode
    endif

    " Now break the sentences starting at the last one
    let firstline = line("'<")
    let lastline = line("'>")
    call cursor(lastline, 0)
    normal! $
    while 1
      normal! (
      if col('.') ==# 1 && line('.') ==# firstline
        " finish if we are at the start of the first line
        break
      elseif col('.') ==# 1
        normal! k$
      else
        normal! hr
      endif
    endwhile

    call setpos('.', save_cursor)
endfunc " }}}

"" {{{2
" Toggle section title style of the current section between ATX and SETEXT
" style.
"
" This changes the style of the section the cursor is positioned in. The
" cursor may be anywhere inside the section or the actual heading.
"
" FIXME: We need a way to _remove_ the heading indicators (make a heading
" to a normal text).
function! asciidoc#editing#toggle_title_style() abort "{{{1
    let save_pos = getcurpos()
    let title_line = asciidoc#motions#find_next_section_heading(line('.'), 'bcW')
    if title_line ==# 0
      " Don't do anything if no title for the current section is found.
      return
    endif

    " jump to the title
    execute 'normal! ' . title_line . 'G0'

    " Find out which kind of title it is. Make the search land on the _text_
    " for SETEXT and we can rely on a '=' at column one means it's ATX.
    let save_reg = @"
    if getline(line('.')) =~ '^='
        " Do the deed: ATX to SETEXT
        execute "normal! df\<Space>"
        " If title has trailing '=', remove them also
        let lead = asciidoc#base#strip(@")
        if getline(line('.')) =~ (lead . '$')
            execute "normal! $" . repeat('h', len(lead)) . "d$"
        endif
        let ix = split(@")[0]
        if has_key(g:atx_to_setext, ix)
          let char = g:atx_to_setext[ix]
          call append(line('.'), repeat(char, len(getline(line('.')))))
          " Adjust the cursor position since SETEXT titles consume 1 line
          " more than ATX.
          " _Except_ the current cursor pos is on the title text.
          " We want to stay there then.
          if save_pos[1] !=# title_line
            let save_pos[1] += 1
          endif
        else
          " Reset if this level doesn't exist in Setext
          echohl ErrorMsg | echo "Unsupported heading level for Setext" | echohl None
          call setline(line('.'), ix . " " . getline(line('.')))
        endif
    else
        " Do the deed: SETEXT to ATX
        execute "normal! jdd"
        execute "normal! kI" . g:setext_to_atx[@"[0]] . " \<Esc>"
        if g:asciidoc_title_style_atx ==# 'symmetric'
          execute "normal! $a " . g:setext_to_atx[@"[0]] . "\<Esc>"
        endif
        " Adjust the cursor position since ATX titles consume 1 line
        " less than SETEXT.
        " _Except_ the current cursor pos is on the title text.
        " Otherwise we would land _above_ the title.
        if save_pos[1] !=# title_line
          let save_pos[1] -= 1
        endif
    endif
    let @" = save_reg
    call setpos('.', save_pos)
endfunc "}}}

" vim: set foldmethod=marker :
