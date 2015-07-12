" A game like boxboy(hacoboy)
" Version: 0.80
" Author: U-MA
" Lisence: VIM LICENSE

let s:save_cpo = &cpo
set cpo&vim

"Player information {{{
let s:player_ch = 'A'

" mode
"   0: player move mode
"   1: block generate mode
let s:mode         = 0
let s:previous_dir = 'l'

function! s:init_player_information() abort
  let s:mode         = 0
  let s:previous_dir = 'l'
  let s:save_ch      = []
endfunction
" }}}

" Script {{{

let s:users_guide = [
  \ '[ 操作説明 ]',
  \ 'h: 左に動く / ブロックを左に生成',
  \ 'j:  / ブロックを下に生成',
  \ 'k:  / ブロックを上に生成',
  \ 'l: 右に動く / ブロックを右に生成',
  \ 'f: 進行方向のOの直前まで動く /',
  \ 't: モード切り替え',
  \ 'x: ブロックを消去 /',
  \ '<space>: 進行方向のブロックを１段登る /',
  \ 'Q: ゲームをやめる',
  \ ]

" }}}}

" Hilight {{{

" ['h', 'j', 'k', 'l']
let s:save_ch = []

function! s:set_hilight_ch() abort
  for l:dir in ['h', 'j', 'k', 'l']
    let l:ch = s:getchar_on(l:dir)
    call add(s:save_ch, l:ch)
    if l:dir =~# '[hkl]'
      if !s:is_block(l:ch) && l:ch !=# s:player_ch && l:ch !=# 'G'
        call s:setchar_on(l:dir, '.')
      endif
    else
      if s:getchar_on_cursor() !=# s:player_ch && l:ch !=# '#' && l:ch !=# s:player_ch && l:ch !=# 'G'
        call s:setchar_on(l:dir, '.')
      endif
    endif
  endfor
endfunction

function! s:reset_hilight_ch() abort
  if s:save_ch == []
    return
  endif

  call s:setchar_on('h', s:save_ch[0])
  call s:setchar_on('j', s:save_ch[1])
  call s:setchar_on('k', s:save_ch[2])
  call s:setchar_on('l', s:save_ch[3])
  let s:save_ch = []
endfunction

" }}}

" Mode {{{

function! s:get_mode() abort
  return s:mode
endfunction

" a:mode == 'move' or 'gen'
function! s:ready_to_switch(mode) abort
  if a:mode ==# 'move'
    call s:reset_hilight_ch()
    execute 'normal! gg0'
    call search(s:player_ch, 'w', s:stage_bottom_line)
    call s:genblocks_fall_if_possible()
  else
    let s:gen_length = 0
    call s:erase_blocks()
    call s:down()
    call s:set_hilight_ch()
  endif
endfunction

" a:mode == 'move' or 'gen'
function! s:switch_to(mode) abort
  if a:mode ==# 'move'
    let s:mode = 0
  else
    let s:mode = 1
  endif
endfunction

function! s:toggle_to(mode) abort
  if a:mode ==# 'move'
    call s:ready_to_switch('move')
    call s:switch_to('move')
    echo 'PLAYER MOVE MODE'
  else
    call s:ready_to_switch('gen')
    call s:switch_to('gen')
    echo 'BLOCK GENERATE MODE'
  endif
endfunction

function! s:toggle_mode() abort
  if s:mode
    call s:toggle_to('move')
  else
    call s:toggle_to('gen')
  endif
  endfunction
" }}}

" Blocks {{{
  let s:gen_block_ch = '#'
  let s:blocks = [ '=', '#', 'O' ]
" }}}

" Utility {{{

function! s:set_gen_length_max(len) abort
  let s:gen_length_max = a:len
endfunction

function! s:can_fall() abort
  let l:pos = getpos('.')
  execute 'normal! gg0'
  while search('#', 'W')
    if s:getchar_on('j') =~# '[=AO]'
      call setpos('.', l:pos)
      return 0
    endif
  endwhile
  call setpos('.', l:pos)
  return 1
endfunction

function! s:can_lift() abort
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

function! s:lift_up_player_and_gen_blocks() abort
  let l:pos = getpos('.')
  execute 'normal! gg0'
  while search('[A#]', 'W', s:stage_bottom_line)
    call s:move_ch_on_cursor_to('k')
  endwhile
  call setpos('.', l:pos)
endfunction

function! s:move_down_gen_blocks() abort
  let l:pos = getpos('.')
  execute 'normal! ' . s:stage_bottom_line . 'G'
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
  execute 'normal! gg0'
  call search('S', 'W')
endfunction

function! s:search_goal() abort
  execute 'normal! gg0'
  return search('G', 'W', s:stage_bottom_line)
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

function! s:setchar_on(dir, ch) abort
  let s:reverse_dir = {'h' : 'l', 'j' : 'k', 'k' : 'j', 'l' : 'h'}
  execute 'normal! ' . a:dir . 'r' . a:ch
  execute 'normal! ' . s:reverse_dir[a:dir]
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

function! s:exist_genblocks() abort
  let l:pos = getpos('.')
  execute 'normal! gg0'
  let l:is_exist = search('#', 'W')
  call setpos('.', l:pos)
  return l:is_exist
endfunction

" }}}

" Block generater{{{

let s:gen_length = 0

function! s:set_gen_block_on(dir) abort
  execute 'normal! ' . a:dir . 'r' . s:gen_block_ch
  let s:gen_length += 1
endfunction

function! s:generate_block(dir) abort
  if s:is_movable(a:dir)
    call s:set_gen_block_on(a:dir)
  else
    if a:dir ==# 'j' && s:getchar_on_cursor() !=# s:player_ch
      if s:can_lift() && s:getchar_on('j') !~# '[A#]'
        call s:lift_up_player_and_gen_blocks()
        call s:set_gen_block_on('')
      endif
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

    call s:reset_hilight_ch()
    if a:key ==# 'h'
      call s:generate_block('h')
    elseif a:key ==# 'j'
      call s:generate_block('j')
    elseif a:key ==# 'k'
      call s:generate_block('k')
    elseif a:key ==# 'l'
      call s:generate_block('l')
    endif
    if s:gen_length < s:gen_length_max
      call s:set_hilight_ch()
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

    call s:genblocks_fall_if_possible()
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
let s:stage_set_files = split(glob(s:boxboy_dir[0] . '/*.vim'), '\n')
for s:stage_set_file in s:stage_set_files
  execute 'source ' . s:stage_set_file
endfor

" }}}

" Disable keys {{{

function! s:disable_all_keys() abort
  let keys = []
  call extend(keys, range(33, 48))
  call extend(keys, range(58, 126))
  for key in keys
    if nr2char(key) == '|'
      continue
    endif

    execute 'nnoremap <silent><buffer><nowait> ' . nr2char(key) . ' <Nop>'
    execute 'vnoremap <silent><buffer><nowait> ' . nr2char(key) . ' <Nop>'
    execute 'onoremap <silent><buffer><nowait> ' . nr2char(key) . ' <Nop>'

    execute 'nnoremap <silent><buffer><nowait> g' . nr2char(key) . ' <Nop>'
    execute 'vnoremap <silent><buffer><nowait> g' . nr2char(key) . ' <Nop>'
    execute 'onoremap <silent><buffer><nowait> g' . nr2char(key) . ' <Nop>'
  endfor
endfunction

" }}}

" Animation {{{

function! s:genblocks_fall_if_possible() abort
  if s:exist_genblocks()
    while s:can_fall()
      call s:move_down_gen_blocks()
    endwhile
  endif
endfunction

" }}}

" Main {{{

let s:default_stage_set_name = '0'
let s:current_stage_no       = 0

let s:stage_set = s:stages[s:default_stage_set_name]
let s:stage     = s:stage_set[s:current_stage_no]

let s:gen_max        = 0 " the max of generatable blocks
let s:gen_length_max = 0 " the max length of generating blocks once

let s:nstages = len(s:stage_set)
let s:stage_bottom_line = 0

function! s:draw_stage_and_information() abort
  call setline(1, s:stage['stage'])
  let s:stage_bottom_line = line('$')
  call setline(line('$')+1, '')
  call setline(line('$')+1, 'MAX GENERATE LENGTH: ' . s:stage['gen_length'])
  call setline(line('$')+1, '')
  for l:line in s:users_guide
    call setline(line('$')+1, l:line)
  endfor
endfunction

function! s:setup_stage() abort
  let s:gen_max        = s:stage['gen_max']
  let s:gen_length_max = s:stage['gen_length']
  call s:draw_stage_and_information()
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

  call s:disable_all_keys()
  nnoremap <silent><buffer><nowait> h       :<C-u>call <SID>key_events('h')<CR>
  nnoremap <silent><buffer><nowait> j       :<C-u>call <SID>key_events('j')<CR>
  nnoremap <silent><buffer><nowait> k       :<C-u>call <SID>key_events('k')<CR>
  nnoremap <silent><buffer><nowait> l       :<C-u>call <SID>key_events('l')<CR>
  nnoremap <silent><buffer><nowait> <space> :<C-u>call <SID>key_events(' ')<CR>
  nnoremap <silent><buffer><nowait> f       :<C-u>call <SID>key_events('f')<CR>
  nnoremap <silent><buffer><nowait> x       :<C-u>call <SID>key_events('x')<CR>
  nnoremap <silent><buffer><nowait> t       :<C-u>call <SID>toggle_mode()<CR>
  nnoremap <silent><buffer><nowait> <esc>   :<C-u>call <SID>toggle_to('move')<CR>
  nnoremap <silent><buffer><nowait> r       :<C-u>call <SID>setup_all()<CR>
  nnoremap <silent><buffer><nowait> Q       :<C-u>bd!<CR>

  augroup BoxBoy
    autocmd!
    autocmd CursorMoved <buffer> call <SID>is_clear()
  augroup END

  syntax match boxboy_dir /\./
  highlight boxboy_dir_hi guibg=blue ctermbg=blue
  highlight default link boxboy_dir boxboy_dir_hi

  call s:setup_all()

  redraw
endfunction

" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
