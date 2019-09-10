" Vim filetype plugin for asciidoc files
" Language:     AsciiDoc
" Maintainer:   Marco Herrn <marco@mherrn.de>
" Last Changed: 07. September 2019
" URL:          http://github.com/hupfdule/vim-asciidoc-ng/
" License:      MIT?

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim


" Options ================================================================ {{{

""
" Whether to enable mappings (default 1)
if !exists('g:asciidoc_enable_mappings')
  let g:asciidoc_enable_mappings = 1
endif

""
" Whether to enable spell checking (default 0)
if !exists('g:asciidoc_enable_spell_checking')
  let g:asciidoc_enable_spell_checking = 0
endif

""
" Whether to enable the fancy syntax highlighting (default 0)
" See |...|
if !exists('g:asciidoc_enable_fancy_syntax_highlighting')
  let g:asciidoc_enable_fancy_syntax_highlighting = 0
endif

""
" Whether to enable concealing for markup (default 1).
" If set to 1 the |conceallevel| must also be set.
" If set to 0 the |conceallevel| has no effect.
if !exists('g:asciidoc_enable_conceal')
  let g:asciidoc_enable_conceal = 0
endif

""
" The default style for section headings. (default 'atx')
" May be set to 'atx' (one-line) or 'setext' (two-line).
"
" Example atx title:
"   == Level 2 section
"
" Example setext title:
"   Level 2 section
"   ---------------
if !exists('g:asciidoc_title_style')
  let g:asciidoc_title_style = 'atx'
endif

""
" The default style to use for atx style headings. (default 'asymmetric')
" May be set to 'asymmetric' or 'symmetric'.
"
" Example asymmetric atx title:
"   == Level 2 section
"
" Example symmetric atx title:
"   == Level 2 section ==
if !exists('g:asciidoc_title_style_atx')
  let g:asciidoc_title_style_atx = 'asymmetric'
endif

" END Options }}}

" Settings =============================================================== {{{
" FIXME; Provide an option to disable setting these?
"        Or rather only options for specific settings (like
"        g:asciidoc_enable_spell_checking)?
setlocal commentstring=//\ %s
setlocal comments=://
" FIXME: Is there an easy way to delete the (auto-inserted) comment leader with a single <BS>?
"        I think we need a separate mapping to delete to the start of the line without moving the cursor
setlocal comments+=fb:*,fb:.,fb:- " Misuse the 'comments' options for auto-insertion of bullet points

" FIXME: Let the user avoid setting these options via config flag?
setlocal formatoptions+=t " Auto-wrap text using textwidth
setlocal formatoptions+=c " Auto-wrap comments using textwidth, inserting the current comment leader automatically
setlocal formatoptions+=r " Automatically insert the current comment leader after hitting <Enter> in Insert mode
setlocal formatoptions+=o " Automatically insert the current comment leader after hitting 'o' or 'O' in Normal mode
setlocal formatoptions+=q " Allow formatting of comments with 'gq'
setlocal formatoptions+=n " When formatting text, recognize numbered lists. Requires a useful 'formatlistpat'
setlocal formatoptions+=j " Where it makes sense, remove a comment leader when joining lines.

" FIXME: This only has an effect when indentexpr is set.
"        Therefore we need such an indentexpr. Use implementation from dahu?
setlocal indentkeys=!^F,o,O " Autoindent only if user presses ^F in insert mode or 'o' or 'O' in normal mode

" Remove '#' from isfname to let 'gf' correctly handle cross references to external files
setlocal isfname-=#

" END Settings }}}

" Folding ================================================================ {{{
" END Folding }}}

" Commands =============================================================== {{{

  " Navigation ----------------------------------------------------------- {{{

    " Section jumps ........................................................ {{{

    " FIXME: Should we allow arguments to jump to the x-most section from here?
    "        (Accept a count)
    command -buffer          AsciidocPrevSection    execute 'normal!' . asciidoc#motions#jump_to_prior_section_title()
    command -buffer          AsciidocPrevSectionEnd execute 'normal!' . asciidoc#motions#jump_to_prior_section_end()
    command -buffer          AsciidocNextSection    execute 'normal!' . asciidoc#motions#jump_to_next_section_title()
    command -buffer          AsciidocNextSectionEnd execute 'normal!' . asciidoc#motions#jump_to_next_section_end()
    nnoremap <buffer> <Plug>(AsciidocPrevSection)    :AsciidocPrevSection<cr>
    xnoremap <buffer> <Plug>(AsciidocPrevSection)    :AsciidocPrevSection<cr>
    nnoremap <buffer> <Plug>(AsciidocPrevSectionEnd) :AsciidocPrevSectionEnd<cr>
    xnoremap <buffer> <Plug>(AsciidocPrevSectionEnd) :AsciidocPrevSectionEnd<cr>
    nnoremap <buffer> <Plug>(AsciidocNextSection)    :AsciidocNextSection<cr>
    xnoremap <buffer> <Plug>(AsciidocNextSection)    :AsciidocNextSection<cr>
    nnoremap <buffer> <Plug>(AsciidocNextSectionEnd) :AsciidocNextSectionEnd<cr>
    xnoremap <buffer> <Plug>(AsciidocNextSectionEnd) :AsciidocNextSectionEnd<cr>

    if g:asciidoc_enable_mappings
      map <buffer> [[ <Plug>(AsciidocPrevSection)
      map <buffer> [] <Plug>(AsciidocPrevSectionEnd)
      map <buffer> ]] <Plug>(AsciidocNextSection)
      " FIXME: This should be placed on the last empty line. Otherwise it
      " lands on the anchors of the section. The same for []
      map <buffer> ][ <Plug>(AsciidocNextSectionEnd)
    endif

    " END Section jump }}}

    " Following links and cross references --------------------------------- {{{

    command -buffer -nargs=? AsciidocFollowLinkUnderCursor call asciidoc#base#follow_cursor_link(<f-args>)
    nnoremap <buffer> <Plug>(AsciidocFollowLinkUnderCursor) :AsciidocFollowLinkUnderCursor<cr>
    inoremap <buffer> <Plug>(AsciidocFollowLinkUnderCursor) <c-o>:AsciidocFollowLinkUnderCursor<cr>

    if g:asciidoc_enable_mappings
      " FIXME: Use <c-]> also in nmap? Would be more consistent, but also
      " shadows the builtin <c-]> (jump to tag)
      nmap <buffer> gf <Plug>(AsciidocFollowLinkUnderCursor)
      imap <buffer> <c-]> <Plug>(AsciidocFollowLinkUnderCursor)
    endif

    " END Following links and cross references }}}

  " END Navigation }}}

  " Editing -------------------------------------------------------------- {{{

    " Sentence per line .................................................. {{{

    " FIXME: Should accept a range
    command -buffer -nargs=1 AsciidocSentencePerLine call asciidoc#editing#sentence_per_line(<f-args>)
    nnoremap <buffer> <Plug>(AsciidocSentencePerLine) :AsciidocSentencePerLine n<cr>
    xnoremap <buffer> <Plug>(AsciidocSentencePerLine) :AsciidocSentencePerLine v<cr>

    if g:asciidoc_enable_mappings
      nmap <buffer> <leader>. <Plug>(AsciidocSentencePerLine)
      xmap <buffer> <leader>. <Plug>(AsciidocSentencePerLine)
    endif

    " END Sentence per line }}}

    " Set section title level ............................................ {{{

    command -buffer -nargs=1 AsciidocSectionLevel call asciidoc#motions#set_section_title_level(<f-args>)
    nnoremap <buffer> <Plug>(AsciidocSectionLevel0) :AsciidocSectionLevel 1<cr>
    inoremap <buffer> <Plug>(AsciidocSectionLevel0) <c-o>:AsciidocSectionLevel 1<cr>
    nnoremap <buffer> <Plug>(AsciidocSectionLevel1) :AsciidocSectionLevel 2<cr>
    inoremap <buffer> <Plug>(AsciidocSectionLevel1) <c-o>:AsciidocSectionLevel 2<cr>
    nnoremap <buffer> <Plug>(AsciidocSectionLevel2) :AsciidocSectionLevel 3<cr>
    inoremap <buffer> <Plug>(AsciidocSectionLevel2) <c-o>:AsciidocSectionLevel 3<cr>
    nnoremap <buffer> <Plug>(AsciidocSectionLevel3) :AsciidocSectionLevel 4<cr>
    inoremap <buffer> <Plug>(AsciidocSectionLevel3) <c-o>:AsciidocSectionLevel 4<cr>
    nnoremap <buffer> <Plug>(AsciidocSectionLevel4) :AsciidocSectionLevel 5<cr>
    inoremap <buffer> <Plug>(AsciidocSectionLevel4) <c-o>:AsciidocSectionLevel 5<cr>
    nnoremap <buffer> <Plug>(AsciidocSectionLevel5) :AsciidocSectionLevel 6<cr>
    inoremap <buffer> <Plug>(AsciidocSectionLevel5) <c-o>:AsciidocSectionLevel 6<cr>

    if g:asciidoc_enable_mappings
      nmap <buffer> <leader>0 <Plug>(AsciidocSectionLevel0)
      imap <buffer> <leader>0 <Plug>(AsciidocSectionLevel0)
      nmap <buffer> <leader>1 <Plug>(AsciidocSectionLevel1)
      imap <buffer> <leader>1 <Plug>(AsciidocSectionLevel1)
      nmap <buffer> <leader>2 <Plug>(AsciidocSectionLevel2)
      imap <buffer> <leader>2 <Plug>(AsciidocSectionLevel2)
      nmap <buffer> <leader>3 <Plug>(AsciidocSectionLevel3)
      imap <buffer> <leader>3 <Plug>(AsciidocSectionLevel3)
      nmap <buffer> <leader>4 <Plug>(AsciidocSectionLevel4)
      imap <buffer> <leader>4 <Plug>(AsciidocSectionLevel4)
      nmap <buffer> <leader>5 <Plug>(AsciidocSectionLevel5)
      imap <buffer> <leader>5 <Plug>(AsciidocSectionLevel5)
    endif

    " END Set section title level }}}

  " END Editing }}}

" END Commands }}}

" FIXME: Do we need to separate mappings? I think it is better to map them
" where we define the commands (above)
" Mappings =============================================================== {{{
" END Mappings }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set fdm=marker :
