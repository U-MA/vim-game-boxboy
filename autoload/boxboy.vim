" A game like boxboy(hacoboy)
" Version: 0.80
" Author: U-MA
" Lisence: VIM LIAENCE

let s:save_cpo = &cpo
set cpo&vim

"Player information {{{
let s:player_ch = 'A'

" mode
"   0: player move mode
"   1: block generate mode
let s:mode         = 0
let s:previous_dir = 'l'
let s:player_pos   = []

function! s:init_player_information() abort
  let s:mode         = 0
  let s:previous_dir = 'l'
  let s:player_pos   = []
endfunction
" }}}

" Mode {{{
function! s:init_mode() abort
  if s:player_pos != []
    call setpos('.', s:player_pos)
    let s:player_pos = []
  endif
  let s:mode = 0
  while s:is_fall()
    call s:move_down_gen_blocks()
  endwhile
endfunction

function! s:get_mode() abort
  return s:mode
endfunction

function! s:toggle_mode() abort
  if s:mode
    echo 'PLAYER MOVE MODE'

    while s:is_fall()
      call s:move_down_gen_blocks()
    endwhile

    let s:mode = 0
    call setpos('.', s:player_pos)
    let s:player_pos = []
  else
    echo 'BLOCK GENERATE MODE'
    let s:mode = 1
    let s:gen_length = 0
    call s:erase_blocks()
    call s:down()
    let s:player_pos = getpos('.')
  endif
  endfunction
" }}}

" Blocks {{{
  let s:gen_block_ch = '#'
  let s:blocks = [ '=', '#', 'O' ]
" }}}

" Utility {{{

function! s:is_fall() abort
  let l:pos = getpos('.')
  execute 'normal! ' . (line('$')-2) . 'G'
  let l:l = search('#', 'bW')
  if !l:l
    call setpos('.', l:pos)
    return 0
  endif
  execute 'normal! ' . (line('$')-2) . 'G'
  while search('#', 'bW') == l:l
    if !s:is_movable('j')
      call setpos('.', l:pos)
      return 0
    endif
  endwhile
  call setpos('.', l:pos)
  return 1
endfunction

function! s:is_lift() abort
  let l:pos = getpos('.')
  execute 'normal! gg0'
  let l:l = search('[A#]', 'W')
  execute 'normal! gg0'
  while search('[A#]', 'W') == l:l
    if !s:is_movable('k')
      call setpos('.', l:pos)
      return 0
    endif
  endwhile
  call setpos('.', l:pos)
  return 1
endfunction

function! s:move_up_player_and_gen_blocks() abort
  let l:pos = getpos('.')
  execute 'normal! gg0'
  while search('[A#]', 'W', line('$')-2)
    call s:move_ch_on_cursor_to('k')
  endwhile
  call setpos('.', l:pos)
endfunction

function! s:move_down_gen_blocks() abort
  let l:pos = getpos('.')
  execute 'normal! ' . (line('$')-2) . 'G'
  while search('#', 'bW')
    call s:move_ch_on_cursor_to('j')
  endwhile
  call setpos('.', l:pos)
endfunction

function! s:move_ch_on_cursor_to(dir) abort
  let l:ch  = s:getchar_on_cursor()
  let l:pos = getpos('.')
  execute 'normal! r ' . a:dir . 'r' . l:ch
  call setpos('.', l:pos)
endfunction

function! s:move_cursor_to_start() abort
  execute 'normal gg0'
  call search('S', 'W')
endfunction

function! s:search_goal() abort
  execute 'normal gg0'
  return search('G', 'W', line('$')-2) "TODO: erase magic number
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

    if s:current_stage_no > s:nstages-1
      echo 'Finish'
      return 1
    endif

    let s:stage = s:stage_set[s:current_stage_no]
    call s:setup_all()

    return 1
  endif
endfunction

function! s:getchar_on_cursor() abort
  return getline('.')[col('.')-1]
endfunction

function! s:set_player_to_cursor() abort
  execute 'normal! r' . s:player_ch
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
  return !s:is_block(c) && (c !=# s:player_ch)
endfunction

" }}}

" Block generater{{{

let s:gen_length = 0

function! s:generate_block(dir) abort
  if a:dir ==# 'h'
    if s:is_movable(a:dir)
      execute 'normal! hr' . s:gen_block_ch
      let s:gen_length += 1
    endif
  elseif a:dir ==# 'j'
    if s:getchar_on_cursor() != s:player_ch
      if s:is_movable(a:dir)
        execute 'normal! jr' . s:gen_block_ch
        let s:gen_length += 1
      else
        let l:pos = getpos('.')
        if !s:is_lift() || s:getchar_on('j') ==# s:player_ch
          call setpos('.', l:pos)
          return
        endif
        call s:move_up_player_and_gen_blocks()
        execute 'normal! r' . s:gen_block_ch
        call setpos('.', l:pos)
        let s:player_pos[1] -= 1
        let s:gen_length += 1
      endif
    endif
  elseif a:dir ==# 'k'
    if s:is_movable(a:dir)
      execute 'normal! kr' . s:gen_block_ch
      let s:gen_length += 1
    endif
  elseif a:dir ==# 'l'
    if s:is_movable(a:dir)
      execute 'normal! lr' . s:gen_block_ch
      let s:gen_length += 1
    endif
  endif
endfunction

" }}}

" Key event {{{

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
  while !s:is_block(s:getchar_on('j'))
    sleep 250m
    execute 'normal! r jr' . s:player_ch
    redraw
  endwhile
endfunction

function! s:jump() abort
  if !s:is_block(s:getchar_on('j'))
    return
  endif

  let jmp_count = 1
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
  redraw
  sleep 50m
endfunction

function! s:hook_shot() abort
  let line = getline('.')
  if s:previous_dir == 'l'
    if match(line[col('.')-1:], 'A\s*O') != -1
      execute 'normal! r '
      execute 'normal! tOr' . s:player_ch
    endif
  else
    if match(line[:col('.')-1], 'O\s*A') != -1
      execute 'normal! r '
      execute 'normal! TOr' . s:player_ch
    endif
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
    if s:gen_length >= s:gen_length_max
      return
    endif

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

  while s:is_fall()
    call s:move_down_gen_blocks()
  endwhile

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

" Main {{{

let s:default_stage_set_name = '0'
let s:current_stage_no       = 0

let s:stage_set = s:stages[s:default_stage_set_name]
let s:stage     = s:stage_set[s:current_stage_no]

let s:gen_max        = 0 " the max of generatable blocks
let s:gen_length_max = 0 " the max length of generating blocks once

let s:nstages = len(s:stage_set)

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

function! s:setup_all() abort
  %delete
  call s:init_player_information()
  call s:setup_stage()
  call s:move_cursor_to_start()
  call s:set_player_to_cursor()
endfunction

function! boxboy#main() abort
  tabnew boxboy
  call s:setup_all()

  nnoremap <silent><buffer><nowait> h       :call <SID>key_events('h')<CR>
  nnoremap <silent><buffer><nowait> j       :call <SID>key_events('j')<CR>
  nnoremap <silent><buffer><nowait> k       :call <SID>key_events('k')<CR>
  nnoremap <silent><buffer><nowait> l       :call <SID>key_events('l')<CR>
  nnoremap <silent><buffer><nowait> <space> :call <SID>key_events(' ')<CR>
  nnoremap <silent><buffer><nowait> f       :call <SID>key_events('f')<CR>
  nnoremap <silent><buffer><nowait> x       :call <SID>key_events('x')<CR>
  nnoremap <silent><buffer><nowait> t       :call <SID>toggle_mode()<CR>
  nnoremap <silent><buffer><nowait> <esc>   :call <SID>init_mode()<CR>
  nnoremap <silent><buffer><nowait> r       :call <SID>setup_all()<CR>

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
