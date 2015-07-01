let owl_SID = owl#filename_to_SID('boxboy/autoload/boxboy.vim')

" Util functions
function! s:add_lines(str) abort
  put! =a:str
endfunction

function! s:create_tab() abort
  silent! tabnew
endfunction

function! s:close_tab() abort
  bdelete!
endfunction

let s:valid_stage = [
  \ '=====', 
  \ '=S G=',
  \ '=====',
  \ '',
  \ 'discription1',
  \ 'discription2',
  \ ]

let s:invalid_stage = [
  \ '=====', 
  \ '=   =',
  \ '=====',
  \ '',
  \ 'discription1',
  \ 'discription2',
  \ ]


" Tests

" move_cursor_to_start() {{{
function! s:test_move_cursor_to_start_func_dont_move_cursor()
  call s:create_tab()
  call s:add_lines(s:invalid_stage)
  OwlCheck !s:move_cursor_to_start()
  OwlCheck getpos('.')[1] == 1
  OwlCheck getpos('.')[2] == 1
  call s:close_tab()
endfunction

function! s:test_move_cursor_to_start_func_moves_cursor_to_S()
  call s:create_tab()
  call s:add_lines(s:valid_stage)
  OwlCheck !s:move_cursor_to_start()
  OwlCheck getpos('.')[1] == 2
  OwlCheck getpos('.')[2] == 2
  call s:close_tab()
endfunction

" }}}

" search_goal() {{{
function! s:test_search_goal_func_returns_zero_when_dont_find_G()
  call s:create_tab()
  call s:add_lines(s:invalid_stage)
  OwlCheck !s:search_goal()
  call s:close_tab()
endfunction

function! s:test_search_goal_func_returns_1_when_find_G()
  call s:create_tab()
  call s:add_lines(s:valid_stage)
  OwlCheck s:search_goal()
  call s:close_tab()
endfunction
" }}}

" vim: foldmethod=marker
