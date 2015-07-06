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

" key_events('j') {{{
function! s:test_key_events_func_with_arg_j_rift_up_player()
  call s:create_tab()
  call s:add_lines([
    \ '======',
    \ '=    =',
    \ '=    =',
    \ '= A  =',
    \ '======',
    \ '',
    \ 'discription1',
    \ 'discription2',
    \])

  call search('A', 'w')
  OwlCheck !s:init_player_information()
  OwlCheck !s:toggle_mode()
  OwlCheck !s:key_events('l')
  OwlCheck !s:key_events('j')
  call search('A', 'w')
  OwlCheck getpos('.')[1] == 3
  OwlCheck getpos('.')[2] == 3
  call s:close_tab()
endfunction

function! s:test_key_events_func_with_arg_j_rift_up_player2()
  call s:create_tab()
  call s:add_lines([
    \ '======',
    \ '=    =',
    \ '=    =',
    \ '=  A =',
    \ '======',
    \ '',
    \ 'discription1',
    \ 'discription2',
    \])

  call search('A', 'w')
  OwlCheck !s:init_player_information()
  OwlCheck !s:toggle_mode()
  OwlCheck !s:key_events('h')
  OwlCheck !s:key_events('j')
  call search('A', 'w')
  OwlCheck getpos('.')[1] == 3
  OwlCheck getpos('.')[2] == 4
  call s:close_tab()
endfunction

" }}}

" toggle_mode() {{{
function! s:test_toggle_mode_func_toggles_mode()
  call s:create_tab()
  OwlCheck !s:init_player_information()
  OwlCheck s:get_mode() == 0
  OwlCheck !s:toggle_mode()
  OwlCheck s:get_mode() == 1
  OwlCheck !s:toggle_mode()
  OwlCheck s:get_mode() == 0
  call s:close_tab()
endfunction
" }}}

" vim: foldmethod=marker
