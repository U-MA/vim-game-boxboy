" A game like boxboy(hacoboy)
" Version: 0.80
" Author: U-MA
" Lisence: VIM LIAENCE

let s:save_cpo = &cpo
set cpo&vim

" Player mode {{{
" mode
"   0: player move mode
"   1: block  move mode
let s:mode = 0

let s:current_cursor_position = []

function! s:init_mode() abort
  let s:mode = 0
endfunction

function! s:toggle_mode() abort
  if s:mode
    echo 'PLAYER MOVE MODE'
    let s:mode = 0
    call setpos('.', s:current_cursor_position)
  else
    echo 'BLOCK GENERATE MODE'
    let s:mode = 1
    let s:gen_length = 0
    let s:current_cursor_position = getpos('.')
    call s:erase_blocks()
    call s:down()
  endif
  endfunction
" }}}

" Objects {{{

" player variable {{{
let s:player_ch = 'A'
let s:player = { 'x': 0, 'y': 0 }

" dir == [hjkl]
function! s:player.move(dir) abort
endfunction

"}}}

" blocks {{{
  let s:block_ch = '#'
  let s:blocks = [ '=', '#', 'O' ]
" }}}

"}}}

" util functions {{{

function! s:move_cursor_to_start() abort
  execute 'normal gg0'
  call search('S', 'W')
endfunction

function! s:search_goal() abort
  execute 'normal gg0'
  return search('G', 'W', line('$')-2)
endfunction

function! s:is_clear() abort
  let p = getpos('.')
  if s:search_goal()
    call setpos('.', p)
    return 0
  else
    call setpos('.', p)
    echo 'Clear'

    let s:current_stage_no += 1

    if s:current_stage_no > s:max_stage-1
      echo 'Finish'
      return 1
    endif

    let s:stage = s:stage_set[s:current_stage_no]
    %delete " buffer clear
    call s:setup_stage()
    call s:move_cursor_to_start()
    call s:set_player_to_cursor()
    call s:init_mode()

    return 1
  endif
endfunction

function! s:getchar_on_cursor() abort
  return getline('.')[col('.')-1]
endfunction

function! s:set_player_to_cursor() abort
  execute 'normal! r' . s:player_ch
endfunction

function! s:getchar_under_player() abort
  return getline(line('.')+1)[col('.')-1]
endfunction

function! s:getchar_on(dir) abort
  if a:dir ==# 'h'
    return getline('.')[col('.')-2]
  elseif a:dir ==# 'j'
    return getline(line('.')+1)[col('.')-1]
  elseif a:dir ==# 'k'
    return getline(line('.')-1)[col('.')-1]
  elseif a:dir ==# 'l'
    return getline('.')[col('.')]
  endif
endfunction

function! s:is_block(ch) abort
  for l:i in s:blocks
    if l:i ==# a:ch
      return 1
    endif
  endfor
  return 0
endfunction

" dir == [hjkl]
function! s:is_movable(dir) abort
  let c = s:getchar_on(a:dir)
  return !s:is_block(c)
endfunction

" }}}

" Block generater{{{

let s:gen_length = 0

function! s:generate_block(dir) abort
  if a:dir ==# 'h'
    if s:is_movable(a:dir) && s:gen_length < s:gen_length_max
      execute 'normal! hr' . s:block_ch
      let s:gen_length += 1
    endif
  elseif a:dir ==# 'j'
  elseif a:dir ==# 'k'
    if s:is_movable(a:dir) && s:gen_length < s:gen_length_max
      execute 'normal! kr' . s:block_ch
      let s:gen_length += 1
    endif
  elseif a:dir ==# 'l'
    if s:is_movable(a:dir) && s:gen_length < s:gen_length_max
      execute 'normal! lr' . s:block_ch
      let s:gen_length += 1
    endif
  endif
  echo s:gen_length . ' ' . s:gen_length_max
endfunction

" }}}

" key event {{{

function! s:right() abort
  let s:previous_dir = 'l'
  if s:is_movable('l')
    execute 'normal! r lr' . s:player_ch
  endif
endfunction

function! s:left() abort
  let s:previous_dir = 'h'
  if s:is_movable('h')
    execute 'normal! r hr' . s:player_ch
  endif
endfunction

function! s:down() abort
  while s:getchar_under_player() ==# ' '
    sleep 300m
    execute 'normal! r jr' . s:player_ch
    redraw
  endwhile
endfunction

let s:previous_dir = 'l'

function! s:jump() abort
  let jmp_count = 2
  while jmp_count > 0
    if s:is_movable('k')
      execute 'normal! r kr' . s:player_ch
      let jmp_count -= 1
    else
      break
    endif
  endwhile
  if s:previous_dir ==# 'l'
    call s:right()
  else
    call s:left()
  endif
endfunction

function! s:hook_shot() abort
  let check_str = 'A\s*O'
  let line = getline('.')
  if match(line[col('.')-1:], 'A\s*O') != -1
    execute 'normal! r '
    execute 'normal! tOr' . s:player_ch
  endif
endfunction

function! s:erase_blocks() abort
  let tmp_pos = getpos('.')
  execute 'normal! gg0'
  if search('#', 'W')
    silent %substitute/#/ /g
  endif
  call setpos('.', tmp_pos)
endfunction

function! s:key_events(key) abort
  if s:mode " block generate
    if a:key ==# 'h'
      call s:generate_block('h')
    elseif a:key ==# 'j'
      call s:generate_block('j')
    elseif a:key ==# 'k'
      call s:generate_block('k')
    elseif a:key ==# 'l'
      call s:generate_block('l')
    endif
  else "player move
    if a:key ==# 'l'
      call s:right()
      call s:down()
    elseif a:key ==# 'h'
      call s:left()
      call s:down()
    elseif a:key ==# ' '
      call s:jump()
      call s:down()
    elseif a:key ==# 'f'
      call s:hook_shot()
      call s:down()
    elseif a:key ==# 'x'
      call s:erase_blocks()
      call s:down()
    endif
  endif
endfunction
"}}}

" Stages {{{

function! boxboy#add_stage(stage_set_name, stage) abort
  if !has_key(s:stages, a:stage_set_name)
    let s:stages[a:stage_set_name] = []
  endif
  call add(s:stages[a:stage_set_name], a:stage)
endfunction

let s:stages = {}

let s:boxboy_dir = split(globpath(&runtimepath, 'autoload/boxboy'), '\n')
let s:stage_set_files = split(s:boxboy_dir[0] . '/*.vim', '\n')
for s:stage_set_file in s:stage_set_files
  execute 'source ' . s:stage_set_file
endfor

" }}}

" main {{{

let s:default_stage_set_name = '0'
let s:current_stage_no       = 0

let s:stage_set = s:stages[s:default_stage_set_name]
let s:stage     = s:stage_set[s:current_stage_no]

let s:gen_max        = 0 " the max of generatable blocks
let s:gen_length_max = 0 " the max length of generating blocks once

let s:max_stage = len(s:stage_set)

function! s:draw_stage() abort
  call setline(1, s:stage['stage'])
  call setline(line('$')+1, '')
  call setline(line('$')+1, 'MAX GENERATE: ' . s:stage['gen_max'])
  call setline(line('$')+1, 'MAX GENERATE LENGTH: ' . s:stage['gen_length'])
endfunction

function! s:setup_stage() abort
  call s:draw_stage()
  let s:gen_max        = s:stage['gen_max']
  let s:gen_length_max = s:stage['gen_length']
endfunction

function! s:restart() abort
  %delete " buffer clear
  call s:setup_stage()
  call s:move_cursor_to_start()
  call s:set_player_to_cursor()
  call s:init_mode()
endfunction

function! boxboy#main() abort
  tabnew boxboy
  %delete " buffer clear
  call s:setup_stage()
  call s:move_cursor_to_start()
  call s:set_player_to_cursor()
  call s:init_mode()

  nnoremap <silent><buffer><nowait> h       :call <SID>key_events('h')<CR>
  nnoremap <silent><buffer><nowait> j       :call <SID>key_events('j')<CR>
  nnoremap <silent><buffer><nowait> k       :call <SID>key_events('k')<CR>
  nnoremap <silent><buffer><nowait> l       :call <SID>key_events('l')<CR>
  nnoremap <silent><buffer><nowait> <space> :call <SID>key_events(' ')<CR>
  nnoremap <silent><buffer><nowait> f       :call <SID>key_events('f')<CR>
  nnoremap <silent><buffer><nowait> x       :call <SID>key_events('x')<CR>
  nnoremap <silent><buffer><nowait> t       :call <SID>toggle_mode()<CR>
  nnoremap <silent><buffer><nowait> r       :call <SID>restart()<CR>

  augroup BoxBoy
    autocmd!
    autocmd CursorMoved <buffer> call <SID>is_clear()
  augroup END

  redraw
endfunction

" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
