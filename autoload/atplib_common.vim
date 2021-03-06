" Author: 	Marcin Szamotulski
" Description: 	This script has functions which have to be called before ATP_files/options.vim 
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" Language:	tex

" This file contains set of functions which are needed to set to set the atp
" options and some common tools.

" Set the project name
"{{{ atplib_common#SetProjectName (function and autocommands)
" This function sets the main project name (b:atp_MainFile)
"
" It is used by EditInputFile which copies the value of this variable to every
" input file included in the main source file. 
"
" nmap gf (GotoFile function) is not using this function.
"
" the b:atp_MainFile variable is set earlier in the startup
" (by the augroup ATP_Syntax_TikzZone), calling SetProjectName to earlier cause
" problems (g:atp_raw_bibinputs undefined). 
"
" ToDo: CHECK IF THIS IS WORKS RECURSIVELY?
" ToDo: THIS FUNCTION SHUOLD NOT SET AUTOCOMMANDS FOR AuTeX function! 
" 	every tex file should be compiled (the compiler function calls the  
" 	right file to compile!
"
" {{{ SetProjectName ( function )
" store a list of all input files associated to some file
function! atplib_common#SetProjectName(...)
    let bang 	= ( a:0 >= 1 ? a:1 : "" )	" do we override b:atp_project	
    let did 	= ( a:0 >= 2 ? a:2 : 1	) 	" do we check if the project name was set
    						" but also overrides the current b:atp_MainFile when 0 	

    " if the project name was already set do not set it for the second time
    " (which sets then b:atp_MainFile to wrong value!)  
    if &filetype == "fd_atp"
	" this is needed for EditInputFile function to come back to the main
	" file.
	let b:atp_MainFile	= ( g:atp_RelativePath ? expand("%:t") : expand("%:p") )
	let b:did_project_name	= 1
    endif

    if exists("b:did_project_name") && b:did_project_name && did
	return " project name was already set"
    else
	let b:did_project_name	= 1
    endif

    if !exists("b:atp_project") || bang == "!"
	let b:atp_MainFile	= exists("b:atp_MainFile") && did ? b:atp_MainFile : ( g:atp_RelativePath ? expand("%:t") : expand("%:p") )
" 	let b:atp_ProjectDir	= fnamemodify(resolve(b:atp_MainFile), ":h")
	let pn_return		= " set from history or just set to " . b:atp_MainFile . " exists=" . exists("b:atp_MainFile") . " did=" . did
    elseif exists("b:atp_project")
	let b:atp_MainFile	= ( g:atp_RelativePath ? fnamemodify(b:atp_project, ":t") : b:atp_project ) 
" 	let b:atp_ProjectDir	= fnamemodify(resolve(b:atp_MainFile), ":h")
	let pn_return		= " set from b:atp_project to " . b:atp_MainFile 
    endif

    " we need to escape white spaces in b:atp_MainFile but not in all places so
    " this is not done here

    " Now we can run things that needs the project name: 
    " b:atp_PackageList is not used
"     if !exists("b:atp_PackageList")
" 	let b:atp_PackageList	= atplib#GrepPackageList()
"     endif

    if !exists("b:atp_ProjectDir")
	let b:atp_ProjectDir = ( exists("b:atp_ProjectScriptFile") ? fnamemodify(b:atp_ProjectScriptFile, ":h") : fnamemodify(resolve(expand("%:p")), ":h") )
    endif

    return pn_return
endfunction
" }}}
"}}}

" This functions sets the value of b:atp_OutDir variable
" {{{ atplib_common#SetOutDir
" This options are set also when editing .cls files.
" It can overwrite the value of b:atp_OutDir
" if arg != 0 then set errorfile option accordingly to b:atp_OutDir
" if a:0 >0 0 then b:atp_atp_OutDir is set iff it doesn't exsits.
function! atplib_common#SetOutDir(arg, ...)

    " THIS FUNCTION SHOULD BE REVIEWED !!!

    if exists("b:atp_OutDir") && a:0 >= 1
	return "atp_OutDir EXISTS"
    endif


    " first we have to check if this is not a project file
    if exists("b:atp_project") || exists("s:inputfiles") && 
		\ ( index(keys(s:inputfiles),fnamemodify(bufname("%"),":t:r")) != '-1' || 
		\ index(keys(s:inputfiles),fnamemodify(bufname("%"),":t")) != '-1' )
	    " if we are in a project input/include file take the correct value of b:atp_OutDir from the atplib#s:outdir_dict dictionary.
	    
	    if index(keys(s:inputfiles),fnamemodify(bufname("%"),":t:r")) != '-1'
		let b:atp_OutDir=substitute(g:outdir_dict[s:inputfiles[fnamemodify(bufname("%"),":t:r")][1]], '\\\s', ' ', 'g')
	    elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":t")) != '-1'
		let b:atp_OutDir=substitute(g:outdir_dict[s:inputfiles[fnamemodify(bufname("%"),":t")][1]], '\\\s', ' ', 'g')
	    endif
    else
	
	    " if we are not in a project input/include file set the b:atp_OutDir
	    " variable	

	    " if the user want to be asked for b:atp_OutDir
	    if g:askfortheoutdir == 1 
		let b:atp_OutDir=substitute(input("Where to put output? do not escape white spaces "), '\\\s', ' ', 'g')
	    endif

	    if ( get(getbufvar(bufname("%"),""),"outdir","optionnotset") == "optionnotset" 
			\ && g:askfortheoutdir != 1 
			\ || b:atp_OutDir == "" && g:askfortheoutdir == 1 )
			\ && !exists("$TEXMFOUTPUT")
		 let b:atp_OutDir=substitute(fnamemodify(resolve(expand("%:p")),":h") . "/", '\\\s', ' ', 'g')

	    elseif exists("$TEXMFOUTPUT")
		 let b:atp_OutDir=substitute($TEXMFOUTPUT, '\\\s', ' ', 'g') 
	    endif	

	    " if arg != 0 then set errorfile option accordingly to b:atp_OutDir
	    if bufname("") =~ ".tex$" && a:arg != 0
" 			\ &&  ( !exists("t:atp_QuickFixOpen") || exists("t:atp_QuickFixOpen") && !t:atp_QuickFixOpen )
		 call atplib_common#SetErrorFile()
	    endif

	    if exists("g:outdir_dict")
		let g:outdir_dict	= extend(g:outdir_dict, {fnamemodify(bufname("%"),":p") : b:atp_OutDir })
	    else
		let g:outdir_dict	= { fnamemodify(bufname("%"),":p") : b:atp_OutDir }
	    endif
    endif
    return b:atp_OutDir
endfunction
" }}}

" This function sets vim 'errorfile' option.
" {{{ atplib_common#SetErrorFile (function and autocommands)
" let &l:errorfile=b:atp_OutDir . fnameescape(fnamemodify(expand("%"),":t:r")) . ".log"
"{{{ atplib_common#SetErrorFile
function! atplib_common#SetErrorFile()

    " set b:atp_OutDir if it is not set
    if !exists("b:atp_OutDir")
	call atplib_common#SetOutDir(0)
    endif

    " set the b:atp_MainFile varibale if it is not set (the project name)
    if !exists("b:atp_MainFile")
	call SetProjectName()
    endif

    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)

    " vim doesn't like escaped spaces in file names ( cg, filereadable(),
    " writefile(), readfile() - all acepts a non-escaped white spaces)
    if has("win16") || has("win32") || has("win64") || has("win95")
	let errorfile	= substitute(atplib#append(b:atp_OutDir, '\') . fnamemodify(atp_MainFile,":t:r") . ".log", '\\\s', ' ', 'g') 
    else
	let errorfile	= substitute(atplib#append(b:atp_OutDir, '/') . fnamemodify(atp_MainFile,":t:r") . ".log", '\\\s', ' ', 'g') 
    endif
    let &l:errorfile	= errorfile
    return &l:errorfile
endfunction
"}}}

"}}}

" Make a tree of input files.
" {{{ TreeOfFiles
" this is needed to make backward searching.
" It returns:
" 	[ {tree}, {list}, {type_dict}, {level_dict} ]
" 	where {tree}:
" 		is a tree of files of the form
" 			{ file : [ subtree, linenr ] }
"		where the linenr is the linenr of \input{file} iline the one level up
"		file.
"	{list}:
"		is just list of all found input files (except the main file!).
"	{type_dict}: 
"		is a dictionary of types for files in {list}
"		type is one of: preambule, input, bib. 
"
" {flat} =  1 	do not be recursive
" {flat} =  0	the deflaut be recursive for input files (not bib and not preambule) 
" 		bib and preambule files are not added to the tree	
" {flat} = -1 	include input and premabule files into the tree
" 		

" TreeOfFiles({main_file}, [{pattern}, {flat}, {run_nr}])
" debug file - /tmp/tof_log
" a:main_file	is the main file to start with
function! atplib_common#TreeOfFiles_vim(main_file,...)
" let time	= reltime()

    let atp_MainFile = atplib#FullPath(b:atp_MainFile)

    if !exists("b:atp_OutDir")
	call atplib_common#SetOutDir(0, 1)
    endif

    let tree		= {}

    " flat = do a flat search, i.e. fo not search in input files at all.
    let flat		= a:0 >= 2	? a:2 : 0	

    " This prevents from long runs on package files
    " for example babel.sty has lots of input files.
    if expand("%:e") != 'tex'
	return [ {}, [], {}, {} ]
    endif
    let run_nr		= a:0 >= 3	? a:3 : 1 
    let biblatex	= 0

    " Adjust g:atp_inputfile_pattern if it is not set right 
    if run_nr == 1 
	let pattern = '^[^%]*\\\(input\s*{\=\|include\s*{'
	if '\subfile{' !~ g:atp_inputfile_pattern && atplib#SearchPackage('subfiles')
	    let pattern .= '\|subfiles\s*{'
	endif
	let biblatex = atplib#SearchPackage('biblatex')
	if biblatex
	    " If biblatex is present, search for bibliography files only in the
	    " preambule.
	    if '\addbibresource' =~ g:atp_inputfile_pattern || '\addglobalbib' =~ g:atp_inputfile_pattern || '\addsectionbib' =~ g:atp_inputfile_pattern || '\bibliography' =~ g:atp_inputfile_pattern
		echo "[ATP:] You might remove biblatex patterns from g:atp_inputfile_pattern if you use biblatex package."
	    endif
	    let biblatex_pattern = '^[^%]*\\\%(bibliography\s*{\|addbibresource\s*\%(\[[^]]*\]\)\?\s*{\|addglobalbib\s*\%(\[[^]]*\]\)\?\s*{\|addsectionbib\s*\%(\[[^]]*\]\)\?\s*{\)'
	else
	    let pattern .= '\|bibliography\s*{'
	endif
	let pattern .= '\)'
    endif
    let pattern		= a:0 >= 1 	? a:1 : g:atp_inputfile_pattern

	if g:atp_debugToF
	    if exists("g:atp_TempDir")
		if run_nr == 1
		    exe "redir! > ".g:atp_TempDir."/TreeOfFiles.log"
		else
		    exe "redir! >> ".g:atp_TempDir."/TreeOfFiles.log"
		endif
	    endif
	endif

	if g:atp_debugToF
	    silent echo run_nr . ") |".a:main_file."| expand=".expand("%:p") 
	endif
	
    if run_nr == 1
	let cwd		= getcwd()
	exe "lcd " . fnameescape(b:atp_ProjectDir)
    endif
	

    let line_nr		= 1
    let ifiles		= []
    let list		= []
    let type_dict	= {}
    let level_dict	= {}

    let saved_llist	= getloclist(0)
    if run_nr == 1 && &l:filetype =~ '^\(ams\)\=tex$'
	try
	    silent execute 'lvimgrep /\\begin\s*{\s*document\s*}/j ' . fnameescape(a:main_file)
	catch /E480:/
	endtry
	let end_preamb	= get(get(getloclist(0), 0, {}), 'lnum', 0)
	call setloclist(0,[])
	if biblatex
	    try
		silent execute 'lvimgrep /'.biblatex_pattern.'\%<'.end_preamb.'l/j ' . fnameescape(a:main_file)
	    catch /E480:/
	    endtry
	endif
    else
	let end_preamb	= 0
	call setloclist(0,[])
    endif

    try
	silent execute "lvimgrepadd /".pattern."/jg " . fnameescape(a:main_file)
    catch /E480:/
"     catch /E683:/ 
" 	let g:pattern = pattern
" 	let g:filename = fnameescape(a:main_file)
    endtry
    let loclist	= getloclist(0)
    call setloclist(0, saved_llist)
    let lines	= map(loclist, "[ v:val['text'], v:val['lnum'], v:val['col'] ]")

    	if g:atp_debugToF
	    silent echo run_nr . ") Lines: " .string(lines)
	endif

    for entry in lines

	    let [ line, lnum, cnum ] = entry
	    " input name (iname) as appeared in the source file
	    let iname	= substitute(matchstr(line, pattern . '\(''\|"\)\=\zs\f\%(\f\|\s\)*\ze\1\='), '\s*$', '', '') 
	    if iname == "" && biblatex 
		let iname	= substitute(matchstr(line, biblatex_pattern . '\(''\|"\)\=\zs\f\%(\f\|\s\)*\ze\1\='), '\s*$', '', '') 
	    endif
	    if g:atp_debugToF
		silent echo run_nr . ") iname=".iname
	    endif
	    if line =~ '{\s*' . iname
		let iname	= substitute(iname, '\\\@<!}\s*$', '', '')
	    endif

	    let iext	= fnamemodify(iname, ":e")
	    if g:atp_debugToF
		silent echo run_nr . ") iext=" . iext
	    endif

	    if iext == "ldf"  || 
			\( &filetype == "plaintex" && getbufvar(fnamemodify(b:atp_MainFile, ":t"), "&filetype") != "tex") 
			\ && expand("%:p") =~ 'texmf'
		" if the extension is ldf (babel.sty) or the file type is plaintex
		" and the filetype of main file is not tex (it can be empty when the
		" buffer is not loaded) then match the full path of the file: if
		" matches then doesn't go below this file. 
		if g:atp_debugToF
		    silent echo run_nr . ") CONTINUE"
		endif
		continue
	    endif

	    " type: preambule,bib,input.
	    if strpart(line, cnum-1)  =~ '^\s*\(\\bibliography\>\|\\addglobalbib\>\|\\addsectionbib\>\|\\addbibresource\>\)'
		let type	= "bib"
	    elseif lnum < end_preamb && run_nr == 1
		let type	= "preambule"
	    else
		let type	= "input"
	    endif

	    if g:atp_debugToF
		silent echo run_nr . ") type=" . type
	    endif

	    let inames	= []
	    if type != "bib"
		let inames		= [ atplib#append_ext(iname, '.tex') ]
	    else
		let inames		= map(split(iname, ','), "atplib#append_ext(v:val, '.bib')")
	    endif

	    if g:atp_debugToF
		silent echo run_nr . ") inames " . string(inames)
	    endif

	    " Find the full path only if it is not already given. 
	    for iname in inames
		let saved_iname = iname
		if iname != fnamemodify(iname, ":p")
		    if type != "bib"
			let iname	= atplib#KpsewhichFindFile('tex', iname, b:atp_OutDir . "," . g:atp_texinputs , 1, ':p', '^\%(\/home\|\.\)', '\(^\/usr\|texlive\|kpsewhich\|generic\|miktex\)')
		    else
			let iname	= atplib#KpsewhichFindFile('bib', iname, b:atp_OutDir . "," . g:atp_bibinputs , 1, ':p')
		    endif
		endif

		if fnamemodify(iname, ":t") == "" 
		    let iname  = expand(saved_iname, ":p")
		endif

		if g:atp_debugToF
		    silent echo run_nr . ") iname " . string(iname)
		endif

		if g:atp_RelativePath
		    let iname = atplib#RelativePath(iname, (fnamemodify(resolve(b:atp_MainFile), ":h")))
		endif

		call add(ifiles, [ iname, lnum] )
		call add(list, iname)
		call extend(type_dict, { iname : type } )
		call extend(level_dict, { iname : run_nr } )
	    endfor
    endfor

	    if g:atp_debugToF
		silent echo run_nr . ") list=".string(list)
	    endif

    " Be recursive if: flat is off, file is of input type.
    if !flat || flat <= -1
    for [ifile, line] in ifiles	
	if type_dict[ifile] == "input" && flat <= 0 || ( type_dict[ifile] == "preambule" && flat <= -1 )
	     let [ ntree, nlist, ntype_dict, nlevel_dict ] = atplib_common#TreeOfFiles_vim(ifile, pattern, flat, run_nr+1)

	     call extend(tree, 		{ ifile : [ ntree, line ] } )
	     call extend(list, nlist, index(list, ifile)+1)  
	     call extend(type_dict, 	ntype_dict)
	     call extend(level_dict, 	nlevel_dict)
	endif
    endfor
    else
	" Make the flat tree
	for [ ifile, line ]  in ifiles
	    call extend(tree, { ifile : [ {}, line ] })
	endfor
    endif

"	Showing time takes ~ 0.013sec.
"     if run_nr == 1
" 	echomsg "TIME:" . join(reltime(time), ".") . " main_file:" . a:main_file
"     endif
    let [ b:TreeOfFiles, b:ListOfFiles, b:TypeDict, b:LevelDict ] = deepcopy([ tree, list, type_dict, level_dict])

    " restore current working directory
    if run_nr == 1
	exe "lcd " . fnameescape(cwd)
    endif

    if g:atp_debugToF && run_nr == 1
	silent! echo "========TreeOfFiles========================"
	silent! echo "TreeOfFiles b:ListOfFiles=" . string(b:ListOfFiles)
	redir END
    endif


    return [ tree, list, type_dict, level_dict ]

endfunction "}}}
" TreeOfFiles_py "{{{
function! atplib_common#TreeOfFiles_py(main_file)
let time=reltime()
python << END_PYTHON

import vim, re, subprocess, os, glob

filename=vim.eval('a:main_file')
relative_path=vim.eval('g:atp_RelativePath')
project_dir=vim.eval('b:atp_ProjectDir')

def vim_remote_expr(servername, expr):
# Send <expr> to vim server,

# expr must be well quoted:
#       vim_remote_expr('GVIM', "atplib#TexReturnCode()")
    cmd=[options.progname, '--servername', servername, '--remote-expr', expr]
    subprocess.Popen(cmd, stdout=subprocess.PIPE).wait()

def isnonempty(string):
    if str(string) == "":
        return False
    else:
        return True

def scan_preambule(file, pattern):
# scan_preambule for a pattern

# file is list of lines
    for line in file:
        ret=re.search(pattern, line)
        if ret:
            return True
        elif re.search('\\\\begin\s*{\s*document\s*}', line):
            return False
    return False

def preambule_end(file):
# find linenr where preambule ends,

# file is list of lines
    nr=1
    for line in file:
        if re.search('\\\\begin\s*{\s*document\s*}', line):
            return nr
        nr+=1
    return 0

def addext(string, ext):
# the pattern is not matching .tex extension read from file.
    if not re.search("\."+ext+"$", string):
        return string+"."+ext
    else:
        return string

def kpsewhich_path(format):
# find fname of format in path given by kpsewhich,

    kpsewhich=subprocess.Popen(['kpsewhich', '-show-path', format], stdout=subprocess.PIPE)
    kpsewhich.wait()
    path=kpsewhich.stdout.read()
    path=re.sub("!!", "",path)
    path=re.sub("\/\/+", "/", path)
    path=re.sub("\n", "",path)
    path_list=path.split(":")
    return path_list

def kpsewhich_find(file, path_list):
    results=[]
    for path in path_list:
        found=glob.glob(os.path.join(path, "*"+os.sep+file))
        results.extend(found)
        found=glob.glob(os.path.join(path, file))
        results.extend(found)
    return results


def scan_file(file, fname, pattern, bibpattern):
# scan file for a pattern, return all groups,

# file is a list of lines, 
    matches_d={}
    matches_l=[]
    nr = 0
    for line in file:
        nr+=1
        match_all=re.findall(pattern, line)
        if len(match_all) > 0:
            for match in match_all:
                for m in match:
                    if str(m) != "":
                        m=addext(m, "tex")
                        if not os.access(m, os.F_OK):
                            try:
                                m=kpsewhich_find(m, tex_path)[0]
                            except IndexError:
                                pass
                        elif relative_path == "0":
                            m=os.path.join(project_dir,m)
                        if fname == filename and nr < preambule_end:
                            matches_d[m]=[m, fname, nr, 'preambule']
                            matches_l.append(m)
                        else:
                            matches_d[m]=[m, fname, nr, 'input']
                            matches_l.append(m)
        match_all=re.findall(bibpattern, line)
        if len(match_all) > 0:
            for match in match_all:
                if str(match) != "":
                    for m in  match.split(','):
                        m=addext(m, "bib")
                        if not os.access(m, os.F_OK):
                            m=kpsewhich_find(m, bib_path)[0]
                        matches_d[m]=[m, fname,  nr, 'bib']
                        matches_l.append(m)
    return [ matches_d, matches_l ]

def tree(file, level, pattern, bibpattern):
# files - list of file names to scan, 

    try:
        file_ob = open(file, 'r')
    except IOError:
        if re.search('\.bib$', file):
            path=bib_path
        else:
            path=tex_path
        try:
            file=kpsewhich_find(file, path)[0]
        except IndexError:
            pass
        try:
            file_ob = open(file, 'r')
        except IOError:
            return [ {}, [], {}, {} ]
    file_l  = file_ob.read().split("\n")
    file_ob.close()
    [found, found_l] =scan_file(file_l, file, pattern, bibpattern)
    t_list=[]
    t_level={}
    t_type={}
    t_tree={}
    for item in found_l:
        t_list.append(item)
        t_level[item]=level
        t_type[item]=found[item][3]
    i_list=[]
    for file in t_list:
        if found[file][3]=="input":
            i_list.append(file)
    for file in i_list:
        [ n_tree, n_list, n_type, n_level ] = tree(file, level+1, pattern, bibpattern)
        for f in n_list:
            t_list.append(f)
            t_type[f]   =n_type[f]
            t_level[f]  =n_level[f]
        t_tree[file]    = [ n_tree, found[file][2] ]
    return [ t_tree, t_list, t_type, t_level ]

try:
    mainfile_ob = open(filename, 'r')
    mainfile    = mainfile_ob.read().split("\n")
    mainfile_ob.close()
    if scan_preambule(mainfile, re.compile('\\\\usepackage\s*\[.*\]\s*{\s*subfiles\s*}')):
	pat_str='^[^%]*(?:\\\\input\s+([\w_\-\.]*)|\\\\(?:input|include(?:only)?|subfiles)\s*{([^}]*)})'
	pattern=re.compile(pat_str)
    else:
	pat_str='^[^%]*(?:\\\\input\s+([\w_\-\.]*)|\\\\(?:input|include(?:only)?)\s*{([^}]*)})'
	pattern=re.compile(pat_str)

    bibpattern=re.compile('^[^%]*\\\\(?:bibliography|addbibresource|addsectionbib(?:\s*\[.*\])?|addglobalbib(?:\s*\[.*\])?)\s*{([^}]*)}')

    bib_path=kpsewhich_path('bib')
    tex_path=kpsewhich_path('tex')
    preambule_end=preambule_end(mainfile)

# Make TreeOfFiles:
    [ tree_of_files, list_of_files, type_dict, level_dict]= tree(filename, 1, pattern, bibpattern)
    vim.command("let b:TreeOfFiles="+str(tree_of_files))
    vim.command("let b:ListOfFiles="+str(list_of_files))
    vim.command("let b:TypeDict="+str(type_dict))
    vim.command("let b:LevelDict="+str(level_dict))
except IOError:
    vim.command("let b:TreeOfFiles={}")
    vim.command("let b:ListOfFiles=[]")
    vim.command("let b:TypeDict={}")
    vim.command("let b:LevelDict={}")
END_PYTHON
let g:time_TreeOfFiles_py=reltimestr(reltime(time))
endfunction
"}}}

" This function finds all the input and bibliography files declared in the source files (recursive).
" {{{ FindInputFiles 
" Returns a dictionary:
" { <input_name> : [ 'bib', 'main file', 'full path' ] }
"			 with the same format as the output of FindInputFiles
" a:MainFile	- main file (b:atp_MainFile)
" a:1 = 0 [1]	- use cached values of tree of files.
function! atplib_common#FindInputFiles(MainFile,...)

"     let time=reltime()
    call atplib#write()

    let cached_Tree	= a:0 >= 1 ? a:1 : 0

    let saved_llist	= getloclist(0)
    call setloclist(0, [])

    if cached_Tree && exists("b:TreeOfFiles")
	let [ TreeOfFiles, ListOfFiles, DictOfFiles, LevelDict ]= deepcopy([ b:TreeOfFiles, b:ListOfFiles, b:TypeDict, b:LevelDict ]) 
    else
	
	if &filetype == "plaintex"
	    let flat = 1
	else
	    let flat = 0
	endif

	let [ TreeOfFiles, ListOfFiles, DictOfFiles, LevelDict ]= TreeOfFiles(fnamemodify(a:MainFile, ":p"), g:atp_inputfile_pattern, flat)
	" Update the cached values:
	let [ b:TreeOfFiles, b:ListOfFiles, b:TypeDict, b:LevelDict ] = deepcopy([ TreeOfFiles, ListOfFiles, DictOfFiles, LevelDict ])
    endif

    let AllInputFiles	= keys(filter(copy(DictOfFiles), " v:val == 'input' || v:val == 'preambule' "))
    let AllBibFiles	= keys(filter(copy(DictOfFiles), " v:val == 'bib' "))

    let b:AllInputFiles	= deepcopy(AllInputFiles)
    let b:AllBibFiles	= deepcopy(AllBibFiles)
    let b:atp_BibFiles	= copy(b:AllBibFiles)


    " this variable will store unreadable bibfiles:    
    let NotReadableInputFiles=[]

    " this variable will store the final result:   
    let Files		= {}

    for File in ListOfFiles
	let File_Path	= atplib#FullPath(File)
	if filereadable(File) 
	call extend(Files, 
	    \ { fnamemodify(File_Path,":t:r") : [ DictOfFiles[File] , fnamemodify(a:MainFile, ":p"), File_Path ] })
	else
	" echo warning if a bibfile is not readable
" 	    echohl WarningMsg | echomsg "File " . File . " not found." | echohl None
	    if count(NotReadableInputFiles, File_Path) == 0 
		call add(NotReadableInputFiles, File_Path)
	    endif
	endif
    endfor
    let g:NotReadableInputFiles	= NotReadableInputFiles

    " return the list  of readable bibfiles
"     let g:time_FindInputFiles=reltimestr(reltime(time))
    return Files
endfunction
function! atplib_common#UpdateMainFile()
    if b:atp_MainFile =~ '^\s*\/'
	let cwd = getcwd()
	exe "lcd " . fnameescape(b:atp_ProjectDir)
	let b:atp_MainFile	= ( g:atp_RelativePath ? fnamemodify(b:atp_MainFile, ":.") : b:atp_MainFile )
	exe "lcd " . fnameescape(cwd)
    else
	let b:atp_MainFile	= ( g:atp_RelativePath ? b:atp_MainFile : atplib#FullPath(b:atp_MainFile) )
    endif
    return
endfunction
"}}}
" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
