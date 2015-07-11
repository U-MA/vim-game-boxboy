let owl_SID = owl#filename_to_SID('boxboy/autoload/boxboy.vim')

" Util functions
function! s:add_lines(str) abort
  silent put! =a:str
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

let s:stage_existing_block = [
  \ '=====', 
  \ '=###=',
  \ '=###=',
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

" erase_blocks() {{{
function! s:test_erase_blocks_func_erase_generated_blocks()
  call s:create_tab()
  call s:add_lines(s:stage_existing_block)
  OwlCheck !s:erase_blocks()
  execute 'normal! gg0'
  OwlCheck !search('#', 'W')
  call s:close_tab()
endfunction
" }}}

" ModeTest {{{

function! s:test_ModeTest_switch_to_func_switch_the_mode()
  call s:create_tab()
  OwlCheck !s:switch_to('move')
  OwlCheck s:get_mode() == 0
  OwlCheck !s:switch_to('gen')
  OwlCheck s:get_mode() == 1
  OwlCheck !s:switch_to('move')
  OwlCheck s:get_mode() == 0
  call s:close_tab()
endfunction

function! s:test_ModeTest_switch_to_func_switch_the_mode_whichever_the_previous_mode_is()
  call s:create_tab()
  OwlCheck !s:switch_to('move')
  OwlCheck !s:switch_to('move')
  OwlCheck s:get_mode() == 0
  call s:close_tab()
  OwlCheck !s:switch_to('gen')
  OwlCheck !s:switch_to('gen')
  OwlCheck s:get_mode() == 1
endfunction

" }}}

" is_fall() {{{

function! s:test_is_fall_returns_1_when_genblock_can_fall()
  call s:create_tab()
  call s:add_lines([
    \ '=====',
    \ '=   =',
    \ '=#  =',
    \ '=   =',
    \ '=====',
    \])

  OwlCheck s:is_fall()
  call s:close_tab()
endfunction

function! s:test_is_fall_returns_0_when_genblock_cannot_fall()
  call s:create_tab()
  call s:add_lines([
    \ '=====',
    \ '=   =',
    \ '=   =',
    \ '=#  =',
    \ '=====',
    \])

  OwlCheck !s:is_fall()
  call s:close_tab()
endfunction

function! s:test_is_fall_returns_0_following_case()
  call s:create_tab()
  call s:add_lines([
    \ '=====',
    \ '=## =',
    \ '=A# =',
    \ '==  =',
    \ '=====',
    \])

  OwlCheck !s:is_fall()
  call s:close_tab()
endfunction

" }}}

" vim: foldmethod=marker
