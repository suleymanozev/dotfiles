" Indent adopted from python-mode's indent/python.vim
" vim: set ts=4 sts=4 sw=4:

" DEPRECATED: Use treesitter indent. see $DOTVIM/after/indent/python.lua
" ======================================================================

"setlocal autoindent
"setlocal indentexpr=PEP8PythonIndent(v:lnum)
"setlocal indentkeys=!^F,o,O,<:>,0),0],0},=elif,=except


" PEP8 compatible Python indent file
" from https://github.com/python-mode/python-mode/blob/develop/autoload/pymode/indent.vim
" Language:         Python
" Maintainer:       Hynek Schlawack <hs@ox.cx>
" Prev Maintainer:  Eric Mc Sween <em@tomcom.de> (address invalid)
" Original Author:  David Bustos <bustos@caltech.edu> (address invalid)
" License:          Public Domain

" Even if tabsize is 2 or 4, use 4 spaces for hanging indents
" https://google.github.io/styleguide/pyguide.html#34-indentation
let s:indent_hanging_width = 4


function! PEP8PythonIndent(lnum)

    " First line has indent 0
    if a:lnum == 1
        return 0
    endif

    " If the current line is inside a string, ignore and keep the current one
    let captures = get(b:, 'ts_highlight') ? luaeval('vim.treesitter.get_captures_at_pos(0, _A, 0)', a:lnum - 1) : []
    if ! captures->filter('v:val.capture == "string")')->empty()
        return -1  " inside a string node
    endif

    " If we can find an open parenthesis/bracket/brace, line up with it.
    call cursor(a:lnum, 1)
    let parlnum = s:SearchParensPair()
    if parlnum > 0
        let parcol = col('.')
        let closing_paren = match(getline(a:lnum), '^\s*[])}]') != -1
        if match(getline(parlnum), '[([{]\s*$', parcol - 1) != -1
            if closing_paren
                return indent(parlnum)
            else
                let l:indent_width = (s:indent_hanging_width > 0 ?
                            \ s:indent_hanging_width : &shiftwidth)
                return indent(parlnum) + l:indent_width
            endif
        else
            return parcol
        endif
    endif

    " Examine this line
    let thisline = getline(a:lnum)
    let thisindent = indent(a:lnum)

    " If the line starts with 'elif' or 'else', line up with 'if' or 'elif'
    if thisline =~ '^\s*\(elif\|else\)\>'
        let bslnum = s:BlockStarter(a:lnum, '^\s*\(if\|elif\)\>')
        if bslnum > 0
            return indent(bslnum)
        else
            return -1
        endif
    endif

    " If the line starts with 'except' or 'finally', line up with 'try'
    " or 'except'
    if thisline =~ '^\s*\(except\|finally\)\>'
        let bslnum = s:BlockStarter(a:lnum, '^\s*\(try\|except\)\>')
        if bslnum > 0
            return indent(bslnum)
        else
            return -1
        endif
    endif

    " Examine previous line
    let plnum = a:lnum - 1
    let pline = getline(plnum)
    let sslnum = s:StatementStart(plnum)

    " If the previous line is blank, keep the same indentation
    if pline =~ '^\s*$'
        return -1
    endif

    " If this line is explicitly joined, find the first indentation that is a
    " multiple of four and will distinguish itself from next logical line.
    if pline =~ '\\$'
        let maybe_indent = indent(sslnum) + &sw
        let control_structure = '^\s*\(if\|while\|for\s.*\sin\|except\)\s*'
        if match(getline(sslnum), control_structure) != -1
            " add extra indent to avoid E125
            return maybe_indent + &sw
        else
            " control structure not found
            return maybe_indent
        endif
    endif

    " If the previous line ended with a colon and is not a comment, indent
    " relative to statement start.
    if pline =~ '^[^#]*:\s*\(#.*\)\?$'
        return indent(sslnum) + &sw
    endif

    " If the previous line was a stop-execution statement or a pass
    if getline(sslnum) =~ '^\s*\(break\|continue\|raise\|return\|pass\)\>'
        " See if the user has already dedented
        if indent(a:lnum) > indent(sslnum) - &sw
            " If not, recommend one dedent
            return indent(sslnum) - &sw
        endif
        " Otherwise, trust the user
        return -1
    endif

    " In all other cases, line up with the start of the previous statement.
    return indent(sslnum)
endfunction


function! s:should_skip_search_treesitter() abort
    let captures = get(b:, 'ts_highlight') ? luaeval('vim.treesitter.get_captures_at_cursor(0)') : []
    return captures->index("comment") >= 0 || captures->index("string") >= 0
endfunction


" Find backwards the closest open parenthesis/bracket/brace.
function! s:SearchParensPair() abort " {{{
    let line = line('.')
    let col = col('.')

    " Skip strings and comments and don't look too far
    if get(b:, 'ts_highlight', 0)
        let Skip = { -> s:should_skip_search_treesitter() }
    else
        let Skip = "line('.') < " . (line - 50) . " ? dummy :" .
                    \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? ' .
                    \ '"string\\|comment\\|doctest"'
    endif

    " Search for parentheses
    call cursor(line, col)
    let parlnum = searchpair('(', '', ')', 'bW', Skip)
    let parcol = col('.')

    " Search for brackets
    call cursor(line, col)
    let par2lnum = searchpair('\[', '', '\]', 'bW', Skip)
    let par2col = col('.')

    " Search for braces
    call cursor(line, col)
    let par3lnum = searchpair('{', '', '}', 'bW', Skip)
    let par3col = col('.')

    " Get the closest match
    if par2lnum > parlnum || (par2lnum == parlnum && par2col > parcol)
        let parlnum = par2lnum
        let parcol = par2col
    endif
    if par3lnum > parlnum || (par3lnum == parlnum && par3col > parcol)
        let parlnum = par3lnum
        let parcol = par3col
    endif

    " Put the cursor on the match
    if parlnum > 0
        call cursor(parlnum, parcol)
    endif
    return parlnum
endfunction " }}}


" Find the start of a multi-line statement
function! s:StatementStart(lnum) " {{{
    let lnum = a:lnum
    while 1
        if getline(lnum - 1) =~ '\\$'
            let lnum = lnum - 1
        else
            call cursor(lnum, 1)
            let maybe_lnum = s:SearchParensPair()
            if maybe_lnum < 1
                return lnum
            else
                let lnum = maybe_lnum
            endif
        endif
    endwhile
endfunction " }}}


" Find the block starter that matches the current line
function! s:BlockStarter(lnum, block_start_re) " {{{
    let lnum = a:lnum
    let maxindent = 10000       " whatever
    while lnum > 1
        let lnum = prevnonblank(lnum - 1)
        if indent(lnum) < maxindent
            if getline(lnum) =~ a:block_start_re
                return lnum
            else
                let maxindent = indent(lnum)
                " It's not worth going further if we reached the top level
                if maxindent == 0
                    return -1
                endif
            endif
        endif
    endwhile
    return -1
endfunction " }}}
