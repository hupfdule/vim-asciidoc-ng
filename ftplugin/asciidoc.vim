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
  " Whether to enable concealing for markup (default 0).
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

  ""
  " Whether to auto-align tables while modifying them in insert mode.
  " (default = 0)
  "
  " This option only applies if the 'godlygeek/tabular' plugin is installed.
  if !exists('g:asciidoc_table_autoalign')
    let g:asciidoc_table_autoalign = 0
  endif

  ""
  " Whether the numbering of ordered lists will be increasing when
  " auto-formatting lists or appending list items. (default = 1)
  if !exists('g:asciidoc_list_number_style_increasing')
    let g:asciidoc_list_number_style_increasing = 1
  endif

  ""
  " The length of block delimiters. May be either 'textwidth' to respect
  " the current value of the |textwidth| vim setting or a positive number
  " indicating the number of characters to use. (default = 4)
  "
  if !exists('g:asciidoc_block_delimiter_length')
    let g:asciidoc_block_delimiter_length = 4
  endif

  ""
  " The position of the TOC window (actually the location list).
  " May be either 'left', 'right', 'top' or 'bottom'. (default = 'right')
  "
  if !exists('g:asciidoc_toc_position')
    let g:asciidoc_toc_position = 'right'
  endif

" END Options ============================================================ }}}

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
  " FIXME: Remove these? As is bothers me when creating a comment block and
  " then hitten enter to insert the content it prepends the line with a new
  " comment leader
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

  " FIXME: This is experimental. Does it do what we expect?
  " FIXME: Problem is '[I' only finds values in the current file, not in an
  " included file. However calling gf on an included file _does_ work. But
  " do we really call the internal gf?
  " The filname of include files is the part between '::' and '[]'
  setlocal include=\v^include::\zs[^\[]+\ze\[\]$
  " Prepend the directory of the current file to the included file
  " FIXME: This doesn't seem to be necessary. The referenced files are
  " corretly found.
  "setlocal includeexpr=substitute(v:fname,'^',\=expand('%:h').'/','')
  " FIXME: Does it make sense to set the 'path'?
  "        Or does this make the includeexpr obsolete?
  setlocal path=.

  " FIXME: This is experimental. Does it do what we expect?
  " FIXME: Also include anchors [[myanchor]]?
  let &l:define = '^:\ze\S\+:\s\+\S\+'

  if executable('asciidoctor')
    compiler asciidoctor
  elseif executable('asciidoc')
    compiler asciidoc
  else
    echo 'Neither asciidoctor nor asciidoc found in path. Please set the compiler directly.'
  endif

" END Settings =========================================================== }}}

" Folding ================================================================ {{{

  " Fixme: These are default folding settings. They should be refined
  " with settings.
  " TODO: Allow folding of document header
  " TODO: Allow folding of code blocks
  setlocal foldexpr=asciidoc#folding#foldexpr(v:lnum)
  setlocal foldmethod=expr
  " FIXME: foldlevel 1 is the sanest for asciidoc, but we should not
  "        override user settings
  setlocal foldlevel=1

" END Folding ============================================================ }}}

" Completion ============================================================= {{{
  setlocal omnifunc=asciidoc#completion#omnicomplete
" END Completion ========================================================= }}}

" Commands =============================================================== {{{

  " Navigation ----------------------------------------------------------- {{{

  " Section jumps ........................................................ {{{

    command -buffer -count=1 AsciidocPrevSection        execute 'normal!' . asciidoc#motions#jump_to_prior_section_title()
    command -buffer -count=1 AsciidocPrevSectionEnd     execute 'normal!' . asciidoc#motions#jump_to_prior_section_end()
    command -buffer -count=1 AsciidocNextSection        execute 'normal!' . asciidoc#motions#jump_to_next_section_title()
    command -buffer -count=1 AsciidocNextSectionEnd     execute 'normal!' . asciidoc#motions#jump_to_next_section_end()
    command -buffer -count=1 AsciidocPrevSiblingSection execute 'normal!' . asciidoc#motions#jump_to_prior_sibling_section_title()
    command -buffer -count=1 AsciidocNextSiblingSection execute 'normal!' . asciidoc#motions#jump_to_next_sibling_section_title()
    command -buffer -count=1 AsciidocParentSection      execute 'normal!' . asciidoc#motions#jump_to_parent_section_title()
    command -buffer -count=1 AsciidocFirstSubsection    execute 'normal!' . asciidoc#motions#jump_to_first_subsection_title()
    nnoremap <buffer> <Plug>(AsciidocPrevSection)           :AsciidocPrevSection<cr>
    xnoremap <buffer> <Plug>(AsciidocPrevSection)           :AsciidocPrevSection<cr>
    nnoremap <buffer> <Plug>(AsciidocPrevSectionEnd)        :AsciidocPrevSectionEnd<cr>
    xnoremap <buffer> <Plug>(AsciidocPrevSectionEnd)        :AsciidocPrevSectionEnd<cr>
    nnoremap <buffer> <Plug>(AsciidocNextSection)           :AsciidocNextSection<cr>
    xnoremap <buffer> <Plug>(AsciidocNextSection)           :AsciidocNextSection<cr>
    nnoremap <buffer> <Plug>(AsciidocNextSectionEnd)        :AsciidocNextSectionEnd<cr>
    xnoremap <buffer> <Plug>(AsciidocNextSectionEnd)        :AsciidocNextSectionEnd<cr>
    nnoremap <buffer> <Plug>(AsciidocPrevSiblingSection)    :AsciidocPrevSiblingSection<cr>
    xnoremap <buffer> <Plug>(AsciidocPrevSiblingSection)    :AsciidocPrevSiblingSection<cr>
    nnoremap <buffer> <Plug>(AsciidocNextSiblingSection)    :AsciidocNextSiblingSection<cr>
    xnoremap <buffer> <Plug>(AsciidocNextSiblingSection)    :AsciidocNextSiblingSection<cr>
    nnoremap <buffer> <Plug>(AsciidocParentSection)         :AsciidocParentSection<cr>
    xnoremap <buffer> <Plug>(AsciidocParentSection)         :AsciidocParentSection<cr>
    nnoremap <buffer> <Plug>(AsciidocFirstSubsection)       :AsciidocFirstSubsection<cr>
    xnoremap <buffer> <Plug>(AsciidocFirstSubsection)       :AsciidocFirstSubsection<cr>

    if g:asciidoc_enable_mappings
      map <buffer> [[ <Plug>(AsciidocPrevSection)
      map <buffer> [] <Plug>(AsciidocPrevSectionEnd)
      map <buffer> ]] <Plug>(AsciidocNextSection)
      map <buffer> ][ <Plug>(AsciidocNextSectionEnd)
      map <buffer> [{ <Plug>(AsciidocPrevSiblingSection)
      map <buffer> ]} <Plug>(AsciidocNextSiblingSection)
      map <buffer> [< <Plug>(AsciidocParentSection)
      map <buffer> ]> <Plug>(AsciidocFirstSubsection)
    endif

  " END Section jumps .................................................... }}}

  " Following links and cross references --------------------------------- {{{

    command -buffer -nargs=? AsciidocFollowLinkUnderCursor          call asciidoc#base#follow_cursor_link(<f-args>)
    nnoremap <buffer> <Plug>(AsciidocFollowLinkUnderCursor)              :AsciidocFollowLinkUnderCursor<cr>
    inoremap <buffer> <Plug>(AsciidocFollowLinkUnderCursor)         <c-o>:AsciidocFollowLinkUnderCursor<cr>
    nnoremap <buffer> <Plug>(AsciidocFollowLinkUnderCursorInSplit)       :AsciidocFollowLinkUnderCursor split<cr>
    inoremap <buffer> <Plug>(AsciidocFollowLinkUnderCursorInSplit)  <c-o>:AsciidocFollowLinkUnderCursor split<cr>
    nnoremap <buffer> <Plug>(AsciidocFollowLinkUnderCursorInVsplit)      :AsciidocFollowLinkUnderCursor vsplit<cr>
    inoremap <buffer> <Plug>(AsciidocFollowLinkUnderCursorInVsplit) <c-o>:AsciidocFollowLinkUnderCursor vsplit<cr>
    nnoremap <buffer> <Plug>(AsciidocFollowLinkUnderCursorInTab)         :AsciidocFollowLinkUnderCursor tabedit<cr>
    inoremap <buffer> <Plug>(AsciidocFollowLinkUnderCursorInTab)    <c-o>:AsciidocFollowLinkUnderCursor tabedit<cr>

    if g:asciidoc_enable_mappings
      " FIXME: Use <c-]> also in nmap? Would be more consistent, but also
      " shadows the builtin <c-]> (jump to tag)
      " What about the other mappings. Do they make sense? Are they
      " consistent?
      nmap <buffer> gf <Plug>(AsciidocFollowLinkUnderCursor)
      imap <buffer> <c-]> <Plug>(AsciidocFollowLinkUnderCursor)
      nmap <buffer> <c-w>f     <Plug>(AsciidocFollowLinkUnderCursorInSplit)
      imap <buffer> <c-w>f     <Plug>(AsciidocFollowLinkUnderCursorInSplit)
      nmap <buffer> <c-w><c-f> <Plug>(AsciidocFollowLinkUnderCursorInSplit)
      imap <buffer> <c-w><c-f> <Plug>(AsciidocFollowLinkUnderCursorInSplit)
      nmap <buffer> <c-w>F     <Plug>(AsciidocFollowLinkUnderCursorInVsplit)
      imap <buffer> <c-w>F     <Plug>(AsciidocFollowLinkUnderCursorInVsplit)
      nmap <buffer> <c-w>gf     <Plug>(AsciidocFollowLinkUnderCursorInTab)
      imap <buffer> <c-w>gf     <Plug>(AsciidocFollowLinkUnderCursorInTab)
    endif

  " END Following links and cross references }}}

  " END Navigation }}}

  " Editing -------------------------------------------------------------- {{{

    " Sentence per line .................................................. {{{

    command -buffer -range -nargs=1 AsciidocSentencePerLine call asciidoc#editing#sentence_per_line(<f-args>)
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

    " Emphasize text (surround) .......................................... {{{

    command -buffer -nargs=1 AsciidocSurround call asciidoc#editing#format_text(<f-args>)
    ""
    " Provide possible completions for quoted text attributes
    " See https://www.methods.co.nz/asciidoc/userguide.html#X96
    " This quoted text attribute syntax is deprecated in asciidoctor.
    " However, there is no reason not to support it
    function! s:asciidocQuotedAttr(ArgLead, CmdLine, CursorPos)
      return "big\nsmall\nunderline\noverline\nline-through\n" .
            \ "white\nsilver\ngray\nblack\nred\nmaroon\nyellow\nolive\n" .
            \ "lime\ngreen\naqua\nteal\nblue\nnavy\nfuchsia\npurple" .
            \ "white-background\nsilver-background\ngray-background\n" .
            \ "black-background\nred-background\nmaroon-background\n" .
            \ "yellow-background\nolive-background\nlime-background\n" .
            \ "green-background\naqua-background\nteal-background\n" .
            \ "blue-background\nnavy-background\nfuchsia-background\n" .
            \ "purple-background"
    endfunction
    command -buffer -nargs=1 -complete=custom,s:asciidocQuotedAttr AsciidocSurroundAttr
          \ :normal <Esc>`>a#<Esc>`<i[<args>]#<Esc>
    " Provide a mapping with autocompletion
    " FIXME: This is likely not the best selection of keys
    vnoremap <buffer> <LocalLeader>tt :<c-u>AsciidocSurroundAttr<space>
    nnoremap <buffer> <LocalLeader>tt viw:<c-u>AsciidocSurroundAttr<space>
    " Provide default mappings for the most common attributes
    " FIXME: Refine key strokes
    " line through
    vnoremap <buffer> <LocalLeader>t- :<c-u>AsciidocSurroundAttr line-through<cr>
    nnoremap <buffer> <LocalLeader>t- viw:<c-u>AsciidocSurroundAttr line-through<cr>
    " underline
    vnoremap <buffer> <LocalLeader>t_ :<c-u>AsciidocSurroundAttr underline<cr>
    nnoremap <buffer> <LocalLeader>t_ viw:<c-u>AsciidocSurroundAttr underline<cr>

    " surround with text styles
    nnoremap <buffer> <Plug>(AsciidocSurround*) :AsciidocSurround *<cr>
    vnoremap <buffer> <Plug>(AsciidocSurround*) :AsciidocSurround *<cr>
    nnoremap <buffer> <Plug>(AsciidocSurround_) :AsciidocSurround _<cr>
    vnoremap <buffer> <Plug>(AsciidocSurround_) :AsciidocSurround _<cr>
    nnoremap <buffer> <Plug>(AsciidocSurround`) :AsciidocSurround `<cr>
    vnoremap <buffer> <Plug>(AsciidocSurround`) :AsciidocSurround `<cr>
    nnoremap <buffer> <Plug>(AsciidocSurround^) :AsciidocSurround ^<cr>
    vnoremap <buffer> <Plug>(AsciidocSurround^) :AsciidocSurround ^<cr>
    nnoremap <buffer> <Plug>(AsciidocSurround~) :AsciidocSurround ~<cr>
    vnoremap <buffer> <Plug>(AsciidocSurround~) :AsciidocSurround ~<cr>
    nnoremap <buffer> <Plug>(AsciidocSurround+) :AsciidocSurround +<cr>
    vnoremap <buffer> <Plug>(AsciidocSurround+) :AsciidocSurround +<cr>

    " FIXME: Refine key strokes

    " strong
    nnoremap <buffer> <LocalLeader>ts viw<Esc>:AsciidocSurround *<CR>
    vnoremap <buffer> <LocalLeader>ts <Esc>:AsciidocSurround *<CR>

    " emphasis
    nnoremap <buffer> <LocalLeader>te viw<Esc>:AsciidocSurround _<CR>
    vnoremap <buffer> <LocalLeader>te <Esc>:AsciidocSurround _<CR>

    " code
    nnoremap <buffer> <LocalLeader>tc viw<Esc>:AsciidocSurround `<CR>
    vnoremap <buffer> <LocalLeader>tc <Esc>:AsciidocSurround `<CR>

    " superscript
    nnoremap <buffer> <LocalLeader>tk viw<Esc>:AsciidocSurround ^<CR>
    vnoremap <buffer> <LocalLeader>tk <Esc>:AsciidocSurround ^<CR>

    " subscript
    nnoremap <buffer> <LocalLeader>tj viw<Esc>:AsciidocSurround ~<CR>
    vnoremap <buffer> <LocalLeader>tj <Esc>:AsciidocSurround ~<CR>

    " passthrough
    nnoremap <buffer> <LocalLeader>tp viw<Esc>:AsciidocSurround +<CR>
    vnoremap <buffer> <LocalLeader>tp <Esc>:AsciidocSurround +<CR>

    " END Emphasize text (surround) }}}

    " Insert macros ...................................................... {{{

    " FIXME: Maybe we should totally change these mappings / functions to
    " do a bit less, but be more flexible then. Actually insert macro
    " target/attributes is already near what we want.
    " Do not provide such mappings at all, but describe how the user could
    " define them?
    command! -buffer -nargs=+ AsciidocToMacroTarget call asciidoc#base#insert_macro_target(<f-args>)
    command! -buffer -nargs=+ AsciidocToMacroAttribute call asciidoc#base#insert_macro_attribs(<f-args>)

    " Image
    " FIXME: Provide a sophisticated function for insert mode with
    " omni-completion that takes the :imagesdir: document attribute into account.
    inoremap <buffer> <LocalLeader>img image:[]<Left>
    nnoremap <buffer> <LocalLeader>img :AsciidocToMacroTarget n inline image<CR>
    vnoremap <buffer> <LocalLeader>img :<C-U>AsciidocToMacroTarget v inline image<CR>

    " Include
    " FIXME: This places a space at the start of the line. This is invalid
    " Actually it should not only place it at the start of the line, but
    " also surround it with empty lines
    " FIXME: Converting the current word or selection into an include macro
    " is mostly useless. Most of the time we want to insert a new
    " directive.
    inoremap <buffer> <LocalLeader>inc <C-O>:AsciidocToMacroTarget n block include<CR>
    nnoremap <buffer> <LocalLeader>inc :AsciidocToMacroTarget n block include<CR>
    vnoremap <buffer> <LocalLeader>inc :<C-U>AsciidocToMacroTarget v block include<CR>

    " Link
    " FIXME: The current or selected word is used as the link target. I
    " think in most cases it would be more helpful to place it as the link
    " text and let the user enter the target then.
    inoremap <buffer> <LocalLeader>link <C-O>:AsciidocToMacroTarget n inline link<CR>
    nnoremap <buffer> <LocalLeader>link :AsciidocToMacroTarget n inline link<CR>
    vnoremap <buffer> <LocalLeader>link :<C-U>AsciidocToMacroTarget v inline link<CR>

    " kbd (Asciidoctor experimental)
    " FIXME: Emit warning when this is used without the :experimental:
    " document attribute?
    inoremap <buffer> <LocalLeader>kbd kbd:[]<Left>
    nnoremap <buffer> <LocalLeader>kbd :AsciidocToMacroAttribute n inline kbd<CR>
    vnoremap <buffer> <LocalLeader>kbd :<C-U>AsciidocToMacroAttribute v inline kbd<CR>

    " menu (Asciidoctor experimental)
    " FIXME: Emit warning when this is used without the :experimental:
    " document attribute?
    inoremap <buffer> <LocalLeader>menu menu:[]<Left>
    nnoremap <buffer> <LocalLeader>menu :AsciidocToMacroAttribute n inline menu<CR>
    vnoremap <buffer> <LocalLeader>menu :<C-U>AsciidocToMacroAttribute v inline menu<CR>

    " btn (Asciidoctor experimental)
    " FIXME: Emit warning when this is used without the :experimental:
    " document attribute?
    inoremap <buffer> <LocalLeader>btn btn:[]<Left>
    nnoremap <buffer> <LocalLeader>btn :AsciidocToMacroAttribute n inline btn<CR>
    vnoremap <buffer> <LocalLeader>btn :<C-U>AsciidocToMacroAttribute v inline btn<CR>

    " END Insert macros }}}

    " Insert blocks ...................................................... {{{

    command! -buffer -nargs=+ AdocInsertParagraph call asciidoc#base#insert_paragraph(<f-args>)

    " FIXME: Provide a mapping for a block with empty metadata (eg. to
    " create the 'music' block, that has no mapping on its own).

    " code block
    inoremap <buffer> <LocalLeader>code <Esc>:AdocInsertParagraph i - source<CR>
    nnoremap <buffer> <LocalLeader>code :AdocInsertParagraph n - source<CR>
    vnoremap <buffer> <LocalLeader>code :<C-U>AdocInsertParagraph v - source<CR>

    " comment block
    inoremap <buffer> <LocalLeader>comment <Esc>:AdocInsertParagraph i / <CR>
    nnoremap <buffer> <LocalLeader>comment :AdocInsertParagraph n / <CR>
    vnoremap <buffer> <LocalLeader>comment :<C-U>AdocInsertParagraph v / <CR>

    " example block
    inoremap <buffer> <LocalLeader>example <Esc>:AdocInsertParagraph i = <CR>
    nnoremap <buffer> <LocalLeader>example :AdocInsertParagraph n =CR>
    vnoremap <buffer> <LocalLeader>example :<C-U>AdocInsertParagraph v = <CR>

    " literal block
    inoremap <buffer> <LocalLeader>literal <Esc>:AdocInsertParagraph i . <CR>
    nnoremap <buffer> <LocalLeader>literal :AdocInsertParagraph n .CR>
    vnoremap <buffer> <LocalLeader>literal :<C-U>AdocInsertParagraph v . <CR>

    " open block
    " FIXME: Open blocks don't work anymore with this function
    inoremap <buffer> <LocalLeader>open <Esc>:AdocInsertParagraph i --<CR>
    nnoremap <buffer> <LocalLeader>open :AdocInsertParagraph n --<CR>
    vnoremap <buffer> <LocalLeader>open :<C-U>AdocInsertParagraph v --<CR>

    " passthrough block
    inoremap <buffer> <LocalLeader>passthrough <Esc>:AdocInsertParagraph i + <CR>
    nnoremap <buffer> <LocalLeader>passthrough :AdocInsertParagraph n + <CR>
    vnoremap <buffer> <LocalLeader>passthrough :<C-U>AdocInsertParagraph v + <CR>

    " quote block
    inoremap <buffer> <LocalLeader>quote <Esc>:AdocInsertParagraph i _ quote author source<CR>
    nnoremap <buffer> <LocalLeader>quote :AdocInsertParagraph n _ quote author source<CR>
    vnoremap <buffer> <LocalLeader>quote :<C-U>AdocInsertParagraph v _ quote author source<CR>

    " sidebar block
    inoremap <buffer> <LocalLeader>sidebar <Esc>:AdocInsertParagraph i * <CR>
    nnoremap <buffer> <LocalLeader>sidebar :AdocInsertParagraph n * <CR>
    vnoremap <buffer> <LocalLeader>sidebar :<C-U>AdocInsertParagraph v * <CR>

    " verse block
    inoremap <buffer> <LocalLeader>verse <Esc>:AdocInsertParagraph i _ verse author source<CR>
    nnoremap <buffer> <LocalLeader>verse :AdocInsertParagraph n _ verse author source<CR>
    vnoremap <buffer> <LocalLeader>verse :<C-U>AdocInsertParagraph v _ verse author source<CR>

    " Admonitions
    " caution
    inoremap <buffer> <LocalLeader>caution <Esc>:AdocInsertParagraph i = CAUTION<CR>
    nnoremap <buffer> <LocalLeader>caution :AdocInsertParagraph n = CAUTION<CR>
    vnoremap <buffer> <LocalLeader>caution :<C-U>AdocInsertParagraph v = CAUTION<CR>

    " important
    inoremap <buffer> <LocalLeader>important <Esc>:AdocInsertParagraph i = IMPORTANT<CR>
    nnoremap <buffer> <LocalLeader>important :AdocInsertParagraph n = IMPORTANT<CR>
    vnoremap <buffer> <LocalLeader>important :<C-U>AdocInsertParagraph v = IMPORTANT<CR>

    " note
    inoremap <buffer> <LocalLeader>note <Esc>:AdocInsertParagraph i = NOTE<CR>
    nnoremap <buffer> <LocalLeader>note :AdocInsertParagraph n = NOTE<CR>
    vnoremap <buffer> <LocalLeader>note :<C-U>AdocInsertParagraph v = NOTE<CR>

    " tip
    inoremap <buffer> <LocalLeader>tip <Esc>:AdocInsertParagraph i = TIP<CR>
    nnoremap <buffer> <LocalLeader>tip :AdocInsertParagraph n = TIP<CR>
    vnoremap <buffer> <LocalLeader>tip :<C-U>AdocInsertParagraph v = TIP<CR>

    " warning
    inoremap <buffer> <LocalLeader>warning <Esc>:AdocInsertParagraph i = WARNING<CR>
    nnoremap <buffer> <LocalLeader>warning :AdocInsertParagraph n = WARNING<CR>
    vnoremap <buffer> <LocalLeader>warning :<C-U>AdocInsertParagraph v = WARNING<CR>
    " Admonitions end

    " END Insert blocks }}}

    " Insert tables ...................................................... {{{

    command! -buffer -nargs=1 AdocInsertTable call asciidoc#base#insert_table(<f-args>)

    inoremap <buffer> <LocalLeader>table <C-O>:AdocInsertTable i<CR>
    nnoremap <buffer> <LocalLeader>table :AdocInsertTable n<CR>
    vnoremap <buffer> <LocalLeader>table :<C-U>AdocInsertTable v<CR>
    " Table text objects
    " FIXME: Is this any different than other blocks? I don't think so and
    " I don't think that would be necessary. We could easily support
    " text-objects for any block. Maybe even differentiate _and_ have a
    " generic one like 'ib' for "in block" (generic) and 'i=' for "in block
    " delimited by =".
    " FIXME: More interesting text objects would be "table cell", "table
    " row" and "table column". But the latter two may not be applicable in
    " all situations, because they are not necessarily in a continuous text
    " block.
    vnoremap <buffer> <silent> <LocalLeader>it :<C-U>call asciidoc#table#text_object(1, 1)<CR>
    onoremap <buffer> <silent> <LocalLeader>it :<C-U>call asciidoc#table#text_object(1, 0)<CR>
    vnoremap <buffer> <silent> <LocalLeader>at :<C-U>call asciidoc#table#text_object(0, 1)<CR>
    onoremap <buffer> <silent> <LocalLeader>at :<C-U>call asciidoc#table#text_object(0, 0)<CR>
    " Table attributes
    " FIXME: Only one of the below mappings actually inserts text into the
    " metadata (e.g. [cols=""]). If the other is used afterwards, it just
    " puts the cursor into the brackets, but doesn't insert anything.
    nnoremap <buffer> <silent> <LocalLeader>cols :call asciidoc#table#insert_attributes('cols')<CR>
    nnoremap <buffer> <silent> <LocalLeader>opts :call asciidoc#table#insert_attributes('options')<CR>

    " Support for Tabular plugin . . . . . . . . . . . . . . . . . . . . . {{{
    " TODO: We should also support vim-easyalign and maybe vim-lion
    if exists(':Tabularize')
      " Use <Leader>| to realign tables with the Tabuliarize plugin
      nnoremap <buffer> <LocalLeader><Bar> :Tabularize /<Bar>\(===\)\@!<CR> " we need a negative lookahead to avoid breaking the block delimiters
      vnoremap <buffer> <LocalLeader><Bar> :Tabularize /<Bar>\(===\)\@!<CR> " we need a negative lookahead to avoid breaking the block delimiters

      " Realign table when entering a |
      if g:asciidoc_table_autoalign == 1
        inoremap <buffer> <Bar>   <Bar><Esc>:call <SID>align()<CR>a
        function! s:align()
          if exists(':Tabularize') && getline('.') =~# '^\s*|' && (getline(line('.')-1) =~# '^\s*|' || getline(line('.')+1) =~# '^\s*|')
            let column = strlen(substitute(getline('.')[0:col('.')],'[^|]','','g'))
            let position = strlen(matchstr(getline('.')[0:col('.')],'.*|\s*\zs.*'))
            Tabularize /|\(=\)\@!
            normal! 0
            call search(repeat('[^|]*|',column).'\s\{-\}'.repeat('.',position),'ce',line('.'))
          endif
        endfunction
      endif
    endif
    " END Support for Tabular plugin }}}

    " END Insert tables }}}

    " Insert xref ........................................................ {{{

    " FIXME: When used in normal mode, but nothing is selected, the result
    " is: <<,  >> with the cursor positioned after the comma. Why are there
    " two spaces after the comma? The comma shouldn't be there in the first
    " place, when no target has been inserted. Instead it should be <<>>
    " with the cursor in the middle.
    " FIXME: When used in normal mode with the cursor over an existing
    " word or with a visual selection, this word is used as the target _and_ as the link text. Not
    " very useful.
    " FIXME: We need an insert mode mapping and especially an omnifunc that
    " populates a menu with the possible values! That would be the most
    " helpful.

    command! -buffer -nargs=1 AdocInsertXref call asciidoc#base#create_xref(<f-args>)
    vnoremap <buffer> <LocalLeader>xr :<C-U>AdocInsertXref v<CR>
    nnoremap <buffer> <LocalLeader>xr :AdocInsertXref n<CR>

    " END Insert xref }}}

    " Toggle section heading style ....................................... {{{

    inoremap <buffer> <Plug>(AsciidocToggleSectionHeaderStyle) <c-o>:call asciidoc#editing#toggle_title_style()<cr>
    nnoremap <buffer> <Plug>(AsciidocToggleSectionHeaderStyle) :call asciidoc#editing#toggle_title_style()<cr>

    " TODO: Provide a mapping to toggle between atx sync/async?
    imap <buffer> <LocalLeader>tt <Plug>(AsciidocToggleSectionHeaderStyle)
    nmap <buffer> <LocalLeader>tt <Plug>(AsciidocToggleSectionHeaderStyle)

    " END Toggle section heading style }}}

    " Append list item ................................................... {{{

    inoremap <buffer> <Plug>(AsciidocAppendListItem) <c-o>:call asciidoc#lists#append_list_item()<cr>
    nnoremap <buffer> <Plug>(AsciidocAppendListItem) :call asciidoc#lists#append_list_item()<cr>

    imap <buffer> <s-cr> <Plug>(AsciidocAppendListItem)
    nmap <buffer> <s-cr> <Plug>(AsciidocAppendListItem)

    " END Append list item }}}

  " END Editing }}}

  " TOC ------------------------------------------------------------------ {{{

  command -buffer          TOC   call asciidoc#toc#toc()
  nnoremap <buffer> <Plug>(TOC)  :TOC<cr>

  " END TOC }}}

" END Commands }}}

" Text objects =========================================================== {{{
  xnoremap <buffer> <silent> <LocalLeader>it :<C-U>call asciidoc#textobjects#table(0, 1)<CR>
  onoremap <buffer> <silent> <LocalLeader>it :<C-U>call asciidoc#textobjects#table(0, 0)<CR>
  xnoremap <buffer> <silent> <LocalLeader>at :<C-U>call asciidoc#textobjects#table(1, 1)<CR>
  onoremap <buffer> <silent> <LocalLeader>at :<C-U>call asciidoc#textobjects#table(1, 0)<CR>
  xnoremap <buffer> <silent> <LocalLeader>At :<C-U>call asciidoc#textobjects#table(2, 1)<CR>
  onoremap <buffer> <silent> <LocalLeader>At :<C-U>call asciidoc#textobjects#table(2, 0)<CR>

  xnoremap <buffer> <silent> <LocalLeader>ib :<C-U>call asciidoc#textobjects#delimited_block(0, 1)<CR>
  onoremap <buffer> <silent> <LocalLeader>ib :<C-U>call asciidoc#textobjects#delimited_block(0, 0)<CR>
  xnoremap <buffer> <silent> <LocalLeader>ab :<C-U>call asciidoc#textobjects#delimited_block(1, 1)<CR>
  onoremap <buffer> <silent> <LocalLeader>ab :<C-U>call asciidoc#textobjects#delimited_block(1, 0)<CR>
  xnoremap <buffer> <silent> <LocalLeader>Ab :<C-U>call asciidoc#textobjects#delimited_block(2, 1)<CR>
  onoremap <buffer> <silent> <LocalLeader>Ab :<C-U>call asciidoc#textobjects#delimited_block(2, 0)<CR>
  " Experimental --------------------------------------------------------- {{{

    " FIXME: This operator should convert the the next motion into a block.
    " However, when used with e.g. the 'w' motion, it always starts at the
    " beginning of the line instead of the cursor position.
    "
    "   Fuisset maecenas fusce bonorum voluptatibus doctus tristique.
    "
    " With the cursor somewhere inside 'fusce' and calling '<localleader>blw+'
    " turns it into
    "
    " ++++
    " Fuisset maecenas fusce
    " ++++
    " bonorum voluptatibus doctus tristique.
    "
    " Also using it on a list item converts the whole item into a block.
    " Including the bullet. I think that is a problem with the 'il' text
    " object. It should _exclude_ the bullet.
    nnoremap <buffer> <LocalLeader>bl :set opfunc=asciidoc#experimental#block_operator<CR>g@

    " FIXME: These are really experimental. The dialog asking for the type of
    " block should not appear. Instead it should 'i=' for an example block,
    " 'i*' for a sidebar block, etc. 'ib' should then select any block.
"    xnoremap <buffer> <silent> <LocalLeader>ib :<C-U>call asciidoc#experimental#text_object_block(1, 1)<CR>
"    onoremap <buffer> <silent> <LocalLeader>ib :call asciidoc#experimental#text_object_block(1, 0)<CR>
"    xnoremap <buffer> <silent> <LocalLeader>ab :<C-U>call asciidoc#experimental#text_object_block(0, 1)<CR>
"    onoremap <buffer> <silent> <LocalLeader>ab :call asciidoc#experimental#text_object_block(0, 0)<CR>

    " FIXME: These are really experimental. They are totally broken for
    " numbered lists. Bullet lists only work, it they don't use the '-'
    " bullet at all.
    " Interestingly it _does_ work with list continuation ('+' in the first
    " column)
    " FIXME: The difference betwen il and al is unclear (actually not
    " implemented)
    xnoremap <buffer> <silent> <LocalLeader>il :<C-U>call asciidoc#experimental#text_object_list_item(1, 1)<CR>
    onoremap <buffer> <silent> <LocalLeader>il :call asciidoc#experimental#text_object_list_item(1, 0)<CR>
    xnoremap <buffer> <silent> <LocalLeader>al :<C-U>call asciidoc#experimental#text_object_list_item(0, 1)<CR>
    onoremap <buffer> <silent> <LocalLeader>al :call asciidoc#experimental#text_object_list_item(0, 0)<CR>

    " FIXME: These are really experimental. The dialog asking for the type of
    " block should not appear. The same applies as for 'ib', 'ab', etc.
    nnoremap <buffer> <silent> <LocalLeader>csb :call asciidoc#experimental#change_surround_block()<CR>
    nnoremap <buffer> <silent> <LocalLeader>dsb :call asciidoc#experimental#delete_surround_block(1)<CR>

  " END Experimental }}}
  " Experimental --------------------------------------------------------- {{{

    " FIXME: This operator should convert the the next motion into a block.
    " However, when used with e.g. the 'w' motion, it always starts at the
    " beginning of the line instead of the cursor position.
    "
    "   Fuisset maecenas fusce bonorum voluptatibus doctus tristique.
    "
    " With the cursor somewhere inside 'fusce' and calling '<localleader>blw+'
    " turns it into
    "
    " ++++
    " Fuisset maecenas fusce
    " ++++
    " bonorum voluptatibus doctus tristique.
    "
    " Also using it on a list item converts the whole item into a block.
    " Including the bullet. I think that is a problem with the 'il' text
    " object. It should _exclude_ the bullet.
    nnoremap <buffer> <LocalLeader>bl :set opfunc=asciidoc#experimental#block_operator<CR>g@

    " FIXME: These are really experimental. The dialog asking for the type of
    " block should not appear. Instead it should 'i=' for an example block,
    " 'i*' for a sidebar block, etc. 'ib' should then select any block.
    xnoremap <buffer> <silent> <LocalLeader><LocalLeader>ib :<C-U>call asciidoc#experimental#text_object_block(1, 1)<CR>
    onoremap <buffer> <silent> <LocalLeader><LocalLeader>ib :call asciidoc#experimental#text_object_block(1, 0)<CR>
    xnoremap <buffer> <silent> <LocalLeader><LocalLeader>ab :<C-U>call asciidoc#experimental#text_object_block(0, 1)<CR>
    onoremap <buffer> <silent> <LocalLeader><LocalLeader>ab :call asciidoc#experimental#text_object_block(0, 0)<CR>

    " FIXME: These are really experimental. They are totally broken for
    " numbered lists. Bullet lists only work, it they don't use the '-'
    " bullet at all.
    " Interestingly it _does_ work with list continuation ('+' in the first
    " column)
    " FIXME: The difference betwen il and al is unclear (actually not
    " implemented)
    xnoremap <buffer> <silent> <LocalLeader>il :<C-U>call asciidoc#experimental#text_object_list_item(1, 1)<CR>
    onoremap <buffer> <silent> <LocalLeader>il :call asciidoc#experimental#text_object_list_item(1, 0)<CR>
    xnoremap <buffer> <silent> <LocalLeader>al :<C-U>call asciidoc#experimental#text_object_list_item(0, 1)<CR>
    onoremap <buffer> <silent> <LocalLeader>al :call asciidoc#experimental#text_object_list_item(0, 0)<CR>

    " FIXME: These are really experimental. The dialog asking for the type of
    " block should not appear. The same applies as for 'ib', 'ab', etc.
    nnoremap <buffer> <silent> <LocalLeader>csb :call asciidoc#experimental#change_surround_block()<CR>
    nnoremap <buffer> <silent> <LocalLeader>dsb :call asciidoc#experimental#delete_surround_block(1)<CR>

  " END Experimental }}}

" END Text objects }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set fdm=marker :
