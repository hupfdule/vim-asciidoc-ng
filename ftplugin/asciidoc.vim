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

  " Navigation =========================================================== {{{

  " Section jumps
  " FIXME: Should we allow arguments to jump to the x-most section from here?
  "        (Accept a count)
  command -buffer          AsciidocPrevSection    execute 'normal!' . asciidoc#motions#jump_to_prior_section_title()
  command -buffer          AsciidocPrevSectionEnd execute 'normal!' . asciidoc#motions#jump_to_prior_section_end()
  command -buffer          AsciidocNextSection    execute 'normal!' . asciidoc#motions#jump_to_next_section_title()
  command -buffer          AsciidocNextSectionEnd execute 'normal!' . asciidoc#motions#jump_to_next_section_end()

  " Following links and cross references
  command -buffer -nargs=? AdocFollowLinkUnderCursor call asciidoc#base#follow_cursor_link(<f-args>)
  " END Navigation }}}

  " Editing ============================================================== {{{
  " FIXME: Should accept a range
  command -buffer -nargs=1 AsciidocSentencePerLine call asciidoc#editing#sentence_per_line(<f-args>)
  nnoremap <buffer> <Plug>(AsciidocSentencePerLine) :AsciidocSentencePerLine n<cr>
  xnoremap <buffer> <Plug>(AsciidocSentencePerLine) :AsciidocSentencePerLine v<cr>
  "if g:asciidoc_enable_mappings
  if 1
    nnoremap <buffer> <leader>. <Plug>(AsciidocSentencePerLine)
    xnoremap <buffer> <leader>. <Plug>(AsciidocSentencePerLine)
  endif

  command -buffer -nargs=1 AsciidocSectionLevel call asciidoc#motions#set_section_title_level(<f-args>)
  " END Editing }}}

" END Commands }}}

" Mappings =============================================================== {{{
" END Mappings }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set fdm=marker :
