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

" Adding room 'testing' {{{

call boxboy#add_stage('testing', {
  \ 'id'      : 0,
  \ 'gen_max' : 0,
  \ 'gen_length' : 0,
  \ 'stage'   : [
  \   '======',
  \   '= S G=',
  \   '======',
  \ ]
  \ })

call boxboy#add_stage('testing', {
  \ 'id'      : 1,
  \ 'gen_max' : 0,
  \ 'gen_length' : 0,
  \ 'stage'   : [
  \   '====',
  \   '=SG=',
  \   '====',
  \ ]
  \ })

" }}}

function! s:test_check_player_initial_position()
  call s:create_tab()
  OwlCheck !s:go_to_room('testing')
  OwlCheck col('.') == 3
  call s:close_tab()
endfunction

function! s:test_player_move_right()
  call s:create_tab()
  OwlCheck !s:go_to_room('testing')
  let l:col = col('.')
  OwlCheck !s:key_events('l')
  OwlCheck col('.') == l:col+1
  call s:close_tab()
endfunction

function! s:test_player_move_left()
  call s:create_tab()
  OwlCheck !s:go_to_room('testing')
  let l:col = col('.')
  OwlCheck !s:key_events('h')
  OwlCheck col('.') == l:col-1
  call s:close_tab()
endfunction

function! s:test_setup_initial_stage()
  call s:create_tab()
  OwlCheck !s:go_to_room('testing')
  OwlCheck s:get_stage_id() == 0
  call s:close_tab()
endfunction

function! s:test_player_do_clear()
  call s:create_tab()
  OwlCheck !s:go_to_room('testing')
  OwlCheck !s:key_events('l')
  OwlCheck !s:key_events('l')
  OwlCheck s:is_clear()
  call s:close_tab()
endfunction

function! s:test_go_to_next_stage_when_player_do_clear()
  call s:create_tab()
  OwlCheck !s:go_to_room('testing')
  OwlCheck !s:go_to_next_stage()
  OwlCheck s:get_stage_id() == 1
  call s:close_tab()
endfunction

" vim: foldmethod=marker
