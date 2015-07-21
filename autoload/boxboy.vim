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
  \ '[ user guide ]',
  \ '',
  \ '   h   : Move left',
  \ '   l   : Move right',
  \ '<space>: Jump',
  \ '',
  \ '   r   : Restart',
  \ '   Q   : Quit game'
  \ ]

" }}}}

" Help window {{{

" a:pos == [ row, col ]
function! s:create_help_window(str, pos) abort
  if a:str ==# 'jump'
    call s:help_jump(a:pos)
  endif
endfunction

function! s:help_jump(ver) abort
  let l:window = [
    \  '+-----------+',
    \  '|           |',
    \  '|     A     |',
    \  '|===========|',
    \  '|  [space]  |',
    \  '+-----------+',
    \]


  let l:pos = getpos('.')
  execute 'normal! r*'

  call cursor(a:ver)
  for l:line in l:window
    call s:replace(l:line)
    execute 'normal! j'
  endfor
  call search('A', 'bw')

  redraw
  sleep 1
  highlight boxboy_space_key_hi ctermfg=darkgray
  redraw
  sleep 300m
  call s:key_events(' ')
  highlight boxboy_space_key_hi ctermfg=NONE
  redraw
  sleep 1
  highlight boxboy_space_key_hi ctermfg=darkgray
  sleep 300m
  call s:key_events(' ')
  highlight boxboy_space_key_hi ctermfg=NONE

  call setpos('.', l:pos)
  execute 'normal! r' . s:player_ch
endfunction

" }}}

" Hilight {{{

" ['h', 'j', 'k', 'l']
let s:save_ch = []

function! s:set_hilight_ch() abort
  let l:arrows = {'h' : '<', 'j' : 'v', 'k' : '^', 'l' : '>'}
  for l:dir in ['h', 'j', 'k', 'l']
    let l:ch = s:getchar_on(l:dir)
    call add(s:save_ch, l:ch)
    if l:dir =~# '[hkl]'
      if !s:is_block(l:ch) && l:ch !=# s:player_ch && l:ch !=# 'G'
        call s:setchar_on(l:dir, l:arrows[l:dir])
      endif
    else
      if s:getchar_on_cursor() !=# s:player_ch && l:ch !=# '#' && l:ch !=# s:player_ch && l:ch !=# 'G'
        call s:setchar_on(l:dir, l:arrows[l:dir])
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
    call s:change_to_genblocks()
    execute 'normal! gg0'
    call search(s:player_ch, 'w', s:stage_bottom_line)
    call s:genblocks_fall_if_possible()
  else
    let s:gen_length = 0
    call s:erase_blocks()
    call s:down()
    call s:set_hilight_ch()
    call s:stack.clear()
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
    highlight boxboy_player ctermfg=NONE
    call s:toggle_to('move')
  else
    highlight boxboy_player ctermfg=magenta
    call s:toggle_to('gen')
  endif
  endfunction
" }}}

" Blocks {{{
  let s:gen_block_ch = '#'
  let s:blocks = [ '=', '#', 'O' ]
" }}}

" Utility {{{

" Stack {{{
" Stack size is 10
let s:Stack = { 'data': [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ], 'head': -1 }
function! s:Stack.push(a) abort
  let self.head += 1
  let self.data[self.head] = a:a
endfunction

function! s:Stack.pop() abort
  try
    let l:ret = self.top()
  catch /^Stack.*/
    echomsg 'error'
  endtry

  let self.head -= 1
  return l:ret
endfunction

function! s:Stack.clear() abort
  let self.head = -1
endfunction

function! s:Stack.empty() abort
  return self.head == -1
endfunction

function! s:Stack.top() abort
  if self.head == -1
    throw 'top(): Stack is empty'
  endif
  return self.data[self.head]
endfunction

function! s:Stack.print() abort
  if self.empty()
    return
  endif
  for l:i in range(self.head, 0, -1)
    echo self.data[l:i]
  endfor
endfunction

function! s:NewStack() abort
  return copy(s:Stack)
endfunction
" }}}

function! s:replace(str) abort
  let l:pos = getpos('.')
  execute 'normal! ' . len(a:str) . 'x'
  execute 'normal! i' . a:str
  call cursor(l:pos[1], l:pos[2])
endfunction

function! s:is_on_ground() abort
  let l:pos = getpos('.')
  execute 'normal! gg0'
  call search(s:player_ch, 'W', s:stage_bottom_line)
  let l:ret = s:getchar_on('j')
  call setpos('.', l:pos)
  return s:is_block(l:ret)
endfunction

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

function! s:lift_down_player_and_gen_blocks() abort
  let l:pos = getpos('.')
  execute 'normal! ' . s:stage_bottom_line . 'G'
  echo s:stage_bottom_line
  while search('[A#]', 'bW')
    call s:move_ch_on_cursor_to('j')
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
  let l:pos = getpos('.')
  execute 'normal! gg0'
  let l:ret = search('G', 'W', s:stage_bottom_line)
  call setpos('.', l:pos)
  return l:ret
endfunction

function! s:is_stage_with_button() abort
  return s:stage['button']
endfunction

function! s:exist_button() abort
  let l:pos = getpos('.')
  execute 'normal! gg0'
  let l:ret = search('_', 'W', s:stage_bottom_line)
  call setpos('.', l:pos)
  return l:ret
endfunction

function! s:open_door() abort
  let l:pos = getpos('.')
  if search('|', 'w')
    silent %substitute/|/ /g
  endif
  call setpos('.', l:pos)
endfunction

function! s:close_door() abort
  "TODO
endfunction

function! s:check_stage() abort
  if s:search_goal()
    if s:is_stage_with_button() 
      if !s:exist_button()
        call s:open_door()
      else
        call s:close_door()
      endif
    endif
    return 0
  else
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

function! s:reverse_dir(dir) abort
  let l:reverse_dir = {'h' : 'l', 'j' : 'k', 'k' : 'j', 'l' : 'h'}
  return l:reverse_dir[a:dir]
endfunction

function! s:setchar_on(dir, ch) abort
  execute 'normal! ' . a:dir . 'r' . a:ch
  execute 'normal! ' . s:reverse_dir(a:dir)
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
let s:stack = s:NewStack()

function! s:change_to_genblocks() abort
  let l:pos = getpos('.')
  execute 'normal! gg0'
  while search('*', 'W', s:stage_bottom_line)
    execute 'normal! r' . s:gen_block_ch
  endwhile
  call setpos('.', l:pos)
endfunction

function! s:set_gen_block_on(dir) abort
  execute 'normal! ' . a:dir . 'r' . s:gen_block_ch
  let s:gen_length += 1
endfunction

function! s:generate_block(dir) abort
  if s:is_movable(a:dir) && s:getchar_on(a:dir) !=# 'G'
    if s:gen_length == 0 && a:dir =~# '[hl]'
      let s:previous_dir = a:dir
    endif
    call s:set_gen_block_on(a:dir)
    call s:stack.push(a:dir)
  else
    if a:dir ==# 'j' && s:getchar_on_cursor() !=# s:player_ch
      if s:can_lift() && s:getchar_on('j') !~# '[A#]'
        call s:lift_up_player_and_gen_blocks()
        call s:set_gen_block_on('')
        call s:stack.push(a:dir)
      endif
    endif
  endif
endfunction

function! s:resume_genblock() abort
  try
    if !s:stack.empty()
      if s:stack.top() =~# '[hkl]'
        execute 'normal! r ' . s:reverse_dir(s:stack.top())
        call s:stack.pop()
      else
        execute 'normal! r '
        if !s:is_on_ground()
          call s:lift_down_player_and_gen_blocks()
        else
          execute 'normal! r ' . s:reverse_dir(s:stack.top())
        endif
        call s:stack.pop()
      endif
      redraw
      let s:gen_length -= 1
    endif
  catch /^Stack.*/
    echomsg 'Stack is empty'
  endtry
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
  if s:is_block(s:getchar_on('j'))
    return
  endif

  while !s:is_block(s:getchar_on('j'))
    sleep 250m
    execute 'normal! r jr' . s:player_ch
    redraw!
  endwhile
  sleep 150m
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
  redraw!
  sleep 50m
endfunction

function! s:hook_shot() abort
  let line = getline('.')
  if s:previous_dir ==# 'l'
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
    call s:reset_hilight_ch()
    try
      if !s:stack.empty() && s:reverse_dir(a:key) ==# s:stack.top()
        call s:resume_genblock()
      elseif s:gen_length >= s:gen_length_max
        return
      elseif a:key ==# 'h'
        call s:generate_block('h')
      elseif a:key ==# 'j'
        call s:generate_block('j')
      elseif a:key ==# 'k'
        call s:generate_block('k')
      elseif a:key ==# 'l'
        call s:generate_block('l')
      endif
    catch /^Stack.*/
      echomsg 'key_events:stack is empty'
    endtry
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

      " for stop always jump
      " But ugly code
      " Hope beautiful code
      let l:i = getchar(0)
      while l:i
        let l:i = getchar(0)
      endwhile
      call feedkeys(nr2char(l:i), 't')
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
    if nr2char(key) ==# '|'
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

"let s:default_stage_set_name = '0'
let s:default_stage_set_name = 'test_play'
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

let s:button_pos = []
function! s:save_button_pos() abort
  if search('_', 'w')
    let s:button_pos = getpos('.')
  else
    let s:button_pos = []
  endif
endfunction

function! s:setup_all() abort
  %delete
  highlight boxboy_player ctermfg=NONE
  call s:init_player_information()
  call s:setup_stage()
  call s:save_button_pos()
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

  "nnoremap <silent><buffer><nowait> v       :<C-u>call <SID>create_help_window('jump', [2, 4])<CR>

  augroup BoxBoy
    autocmd!
    autocmd CursorMoved <buffer> call <SID>check_stage()
  augroup END

  syntax match boxboy_dir /[<v^>]/ contained
  syntax match boxboy_player /A/ contained
  syntax match boxboy_block /=/ contained
  syntax match boxboy_genblock /#/ contained
  syntax match boxboy_space_key /[space]/ contained
  syntax region boxboy_stage start=/\%^/ end=/^$/ contains=boxboy_dir,boxboy_player,boxboy_block,boxboy_genblock,boxboy_space_key
  highlight boxboy_dir_hi guibg=blue ctermbg=blue
  highlight boxboy_player_hi guifg=cyan ctermfg=cyan
  highlight boxboy_block_hi guifg=gray guibg=lightgray ctermfg=gray ctermbg=lightgray
  highlight boxboy_genblock_hi guifg=gray guibg=darkgray ctermfg=gray ctermbg=darkgray
  highlight boxboy_space_key_hi ctermfg=NONE
  highlight default link boxboy_dir boxboy_dir_hi
  highlight default link boxboy_block boxboy_block_hi
  highlight default link boxboy_genblock boxboy_genblock_hi
  highlight default link boxboy_space_key boxboy_space_key_hi
  "highlight default link boxboy_player boxboy_player_hi

  call s:setup_all()

  redraw
endfunction

" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
