let owl_SID = owl#filename_to_SID('boxboy/autoload/boxboy.vim')

" TestUtil {{{
function! s:add_lines(str) abort
  silent put! =a:str
endfunction

function! s:create_tab() abort
  silent! tabnew
endfunction

function! s:close_tab() abort
  bdelete!
endfunction
" }}}

function! s:owl_begin() abort
  call s:create_tab()
endfunction

function! s:owl_end() abort
  call s:close_tab()
endfunction

" Move {{{

function! s:test_move_left_to_press_h()
  call s:add_lines([
    \ '=========',
    \ '=   A   =',
    \ '=========',
    \])

  call search('A', 'w')
  let l:col = col('.')
  execute 'normal h'
  OwlCheck col('.') == l:col-1
endfunction

function! s:test_move_right_to_press_l()
  call s:add_lines([
    \ '=========',
    \ '=   A   =',
    \ '=========',
    \])

  call search('A', 'w')
  let l:col = col('.')
  execute 'normal l'
  OwlCheck col('.') == l:col+1
endfunction

" }}}
