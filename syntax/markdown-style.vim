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


" TODO: Link all the other syntax groups
hi def link asciidocMarkdownCode Identifier
hi def link asciidocMarkdownCodeLanguage Type
