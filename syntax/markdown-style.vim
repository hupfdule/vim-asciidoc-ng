" Vim syntax file
" Language:     Markdown syntax supported by AsciiDoc
" Author:       Marco Herrn <marco@mherrn.de>
" URL:          https://github.com/hupfdule/vim-asciidoc-ng
" Licence:      GPL (http://www.gnu.org)
" Last Change:  2019-08-16
" Remarks:      Vim 6 or greater


" markdown style section headers
syn region asciidocMarkdownSection1      start="^\s*#"                end="$"
syn region asciidocMarkdownSection2      start="^\s*##"               end="$"
syn region asciidocMarkdownSection3      start="^\s*###"              end="$"
syn region asciidocMarkdownSection4      start="^\s*####"             end="$"
syn region asciidocMarkdownSection5      start="^\s*#####"            end="$"
syn region asciidocMarkdownSection6      start="^\s*######"           end="$"

" markdown style block quotes
syn region asciidocMarkdownBlockquote1   start=/^\(\s*>\)\{1}/        end=/$/
syn region asciidocMarkdownBlockquote2   start=/^\(\s*>\)\{2}/        end=/$/
syn region asciidocMarkdownBlockquote3   start=/^\(\s*>\)\{3}/        end=/$/
syn region asciidocMarkdownBlockquote4   start=/^\(\s*>\)\{4}/        end=/$/
syn region asciidocMarkdownBlockquote5   start=/^\(\s*>\)\{5}/        end=/$/
syn region asciidocMarkdownBlockquote6   start=/^\(\s*>\)\{6}/        end=/$/

" markdown style code blocks
syn match  asciidocMarkdownCodeLanguage  /\(`\{3}\)\@<=\i\+/                            containedin=asciidocMarkdownCode
syn region asciidocMarkdownCode          start=/^\z(`\{3}\)[^`]*$/    end=/^\z1`*\s*$/  contains=asciidocMarkdownCodeLanguage

" markdown style horizontal rules
syn match  asciidocMarkdownHRule         /^\s*\*\s\{0,1}\*\s\{0,1}\*\(\*\|\s\)*$/
syn match  asciidocMarkdownHRule         /^\s*-\s\{0,1}-\s\{0,1}-\(-\|\s\)*$/
syn match  asciidocMarkdownHRule         /^\s*_\s\{0,1}_\s\{0,1}_\(_\|\s\)*$/


" TODO: Specify "fancy" colors
hi def link asciidocMarkdownSection1     asciidocOneLineTitle
hi def link asciidocMarkdownSection2     asciidocOneLineTitle
hi def link asciidocMarkdownSection3     asciidocOneLineTitle
hi def link asciidocMarkdownSection4     asciidocOneLineTitle
hi def link asciidocMarkdownSection5     asciidocOneLineTitle
hi def link asciidocMarkdownSection6     asciidocOneLineTitle
" Invent highlighting for quotes (still missing in asciidoc syntasx)
hi def link asciidocMarkdownBlockquote1  Ignore
hi def link asciidocMarkdownBlockquote2  Ignore
hi def link asciidocMarkdownBlockquote3  Ignore
hi def link asciidocMarkdownBlockquote4  Ignore
hi def link asciidocMarkdownBlockquote5  Ignore
hi def link asciidocMarkdownBlockquote6  Ignore
hi def link asciidocMarkdownCode         asciidocListingBlock
" should be the same as in asciidoc (needs to be defined)
hi def link asciidocMarkdownCodeLanguage Type
hi def link asciidocMarkdownHRule        asciidocRuler
