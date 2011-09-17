" Author:	Marcin Szamotulski
" Description:  This file provides searching tools of ATP.
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" Language:	tex
" Last Change:

let s:sourced 	= exists("s:sourced") ? 1 : 0
 
" Functions:
" Find all names of locally defined commands, colors and environments. 
" Used by the completion function.
" {{{ LocalCommands
function! LocalCommands(write, ...)
    let time=reltime()
    let pattern = a:0 >= 1 && a:1 != '' ? a:1 : '\\def\>\|\\newcommand\>\|\\newenvironment\|\\newtheorem\|\\definecolor\|'
		\ . '\\Declare\%(RobustCommand\|FixedFont\|TextFontCommand\|MathVersion\|SymbolFontAlphabet'
			    \ . '\|MathSymbol\|MathDelimiter\|MathAccent\|MathRadical\|MathOperator\)'
		\ . '\|\\SetMathAlphabet\>'
    let bang	= a:0 >= 2 ? a:2 : '' 

    if has("python") && ( !exists("g:atp_no_python") || g:atp_no_python == 0 )
	call atplib_search#LocalCommands_py(a:write, '' , bang)
    else
	call atplib_search#LocalCommands_vim(pattern, bang)
    endif
    if !(exists("g:atp_no_local_abbreviations") && g:atp_no_local_abbreviations == 1)
	call atplib_search#LocalAbbreviations()
    endif
    let g:time_LocalCommands=reltimestr(reltime(time))
endfunction
" }}}

" BibSearch:
"{{{ variables
let g:bibentries=['article', 'book', 'booklet', 'conference', 'inbook', 'incollection', 'inproceedings', 'manual', 'mastertheosis', 'misc', 'phdthesis', 'proceedings', 'techreport', 'unpublished']

let g:bibmatchgroup		='String'
let g:defaultbibflags		= 'tabejsyu'
let g:defaultallbibflags	= 'tabejfsvnyPNSohiuHcp'
let b:lastbibflags		= g:defaultbibflags	" Set the lastflags variable to the default value on the startup.
let g:bibflagsdict=atplib#bibflagsdict
" These two variables were s:... but I switched to atplib ...
let g:bibflagslist		= keys(g:bibflagsdict)
let g:bibflagsstring		= join(g:bibflagslist,'')
let g:kwflagsdict={ 	  '@a' : '@article', 	
	    		\ '@b' : '@book\%(let\)\@<!', 
			\ '@B' : '@booklet', 	
			\ '@c' : '@in\%(collection\|book\)', 
			\ '@m' : '@misc', 	
			\ '@M' : '@manual', 
			\ '@p' : '@\%(conference\)\|\%(\%(in\)\?proceedings\)', 
			\ '@t' : '@\%(\%(master)\|\%(phd\)\)thesis', 
			\ '@T' : '@techreport', 
			\ '@u' : '@unpublished' }    

"}}}

" Mappings:
nnoremap <silent> <Plug>BibSearchLast		:call atplib_search#BibSearch("", b:atp_LastBibPattern, b:atp_LastBibFlags)<CR>
"
" Commands And Highlightgs:
" {{{
command! -buffer -bang -complete=customlist,SearchHistCompletion -nargs=* S 	:call atplib_search#Search(<q-bang>, <q-args>) | let v:searchforward = ( atplib_search#GetSearchArgs(<q-args>, 'bceswW')[1] =~# 'b' ? 0 : 1 )
nmap <buffer> <silent> <Plug>RecursiveSearchn 	:call atplib_search#RecursiveSearch(atplib#FullPath(b:atp_MainFile), expand("%:p"), (exists("b:TreeOfFiles") ? "" : "make_tree"), (exists("b:TreeOfFiles") ? b:TreeOfFiles : {}), expand("%:p"), 1, 1, winsaveview(), bufnr("%"), reltime(), { 'no_options' : 'no_options' }, 'no_cwd', @/, v:searchforward ? "" : "b") <CR>
nmap <buffer> <silent> <Plug>RecursiveSearchN 	:call atplib_search#RecursiveSearch(atplib#FullPath(b:atp_MainFile), expand("%:p"), (exists("b:TreeOfFiles") ? "" : "make_tree"), (exists("b:TreeOfFiles") ? b:TreeOfFiles : {}), expand("%:p"), 1, 1, winsaveview(), bufnr("%"), reltime(), { 'no_options' : 'no_options' }, 'no_cwd', @/, !v:searchforward ? "" : "b") <CR>

if g:atp_mapNn
" These two maps behaves now like n (N): after forward search n (N) acts as forward (backward), after
" backward search n acts as backward (forward, respectively).

    nmap <buffer> <silent> n		<Plug>RecursiveSearchn
    nmap <buffer> <silent> N		<Plug>RecursiveSearchN

    " Note: the final step if the mapps n and N are made is in atplib_search#LoadHistory 
endif

command! -buffer -bang 		LocalCommands					:call LocalCommands(1, "", <q-bang>)
command! -buffer -bang -nargs=* -complete=customlist,DsearchComp Dsearch	:call atplib_search#Dsearch(<q-bang>, <q-args>)
command! -buffer -nargs=? -complete=customlist,atplib#OnOffComp ToggleNn	:call atplib_search#ATP_ToggleNn(<f-args>)
command! -buffer -bang -nargs=* BibSearch					:call atplib_search#BibSearch(<q-bang>, <q-args>)

" Hilighlting:
hi link BibResultsFileNames 	Title	
hi link BibResultEntry		ModeMsg
hi link BibResultsMatch		WarningMsg
hi link BibResultsGeneral	Normal

hi link Chapter 		Normal	
hi link Section			Normal
hi link Subsection		Normal
hi link Subsubsection		Normal
hi link CurrentSection		WarningMsg
"}}}
" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
