" A game like boxboy(hacoboy)
" Version: 0.80
" Author: U-MA
" Lisence: VIM LICENSE

let s:save_cpo = &cpo
set cpo&vim

" Constant Values {{{
let s:PLAYER_CH = 'A'
" }}}

"Player information {{{

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
  "highlight boxboy_space_key_hi ctermfg=darkgray
  sleep 300m
  call s:key_events(' ')
  "highlight boxboy_space_key_hi ctermfg=NONE

  redraw
  sleep 1
  "highlight boxboy_space_key_hi ctermfg=darkgray
  sleep 300m
  call s:key_events(' ')
  "highlight boxboy_space_key_hi ctermfg=NONE

  call setpos('.', l:pos)
  execute 'normal! r' . s:PLAYER_CH
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
      if !s:is_block(l:ch) && l:ch !=# s:PLAYER_CH && l:ch !=# 'G'
        call s:setchar_on(l:dir, l:arrows[l:dir])
      endif
    else
      if s:getchar_on_cursor() !=# s:PLAYER_CH && l:ch !=# '#' && l:ch !=# s:PLAYER_CH && l:ch !=# 'G'
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
    execute 'normal! gg0'
    call search(s:PLAYER_CH, 'w', s:stage_bottom_line)
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
    "highlight boxboy_player_hi ctermfg=NONE
    call s:toggle_to('move')
  else
    "highlight boxboy_player_hi ctermfg=magenta
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
  call search(s:PLAYER_CH, 'W', s:stage_bottom_line)
  let l:ret = s:getchar_on('j')
  call setpos('.', l:pos)
  return s:is_block(l:ret)
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
  execute 'normal! r' . s:PLAYER_CH
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
  return !s:is_block(c) && (c !=# s:PLAYER_CH)
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
    if a:dir ==# 'j' && s:getchar_on_cursor() !=# s:PLAYER_CH
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
    execute 'normal! r lr' . s:PLAYER_CH
  endif
endfunction

function! s:left() abort
  let s:previous_dir = 'h'
  if s:is_movable('h')
    execute 'normal! r hr' . s:PLAYER_CH
  endif
endfunction

function! s:down() abort
  if s:is_block(s:getchar_on('j'))
    return
  endif

  while !s:is_block(s:getchar_on('j'))
    sleep 250m
    execute 'normal! r jr' . s:PLAYER_CH
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
      execute 'normal! r kr' . s:PLAYER_CH
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
      execute 'normal! tOr' . s:PLAYER_CH
    endif
  else
    if match(line[:col('.')-1], 'O\s*A') != -1
      execute 'normal! r '
      execute 'normal! TOr' . s:PLAYER_CH
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
  if a:key ==# 't'
    call s:toggle_mode()
    return
  endif
  if s:mode " block generate
    call s:reset_hilight_ch()
    try
      if !s:stack.empty() && s:reverse_dir(a:key) ==# s:stack.top()
        call s:resume_genblock()
      elseif s:gen_length >= s:stage.get_gen_length_max()
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
    if s:gen_length < s:stage.get_gen_length_max()
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

" class Stage {{{

let s:Stage = { 'id' : -1, 'gen_length_max' : 0, 'stage_data' : [] }
function! s:Stage.new(id, gen_length_max, stage_data) abort
  let l:ret = copy(s:Stage)
  let l:ret.id = a:id
  let l:ret.gen_length_max = a:gen_length_max
  let l:ret.stage_data = a:stage_data
  return l:ret
endfunction

function! s:Stage.get_id() abort
  return self.id
endfunction

function! s:Stage.get_gen_length_max() abort
  return self.gen_length_max
endfunction

function! s:Stage.get_data() abort
  return self.stage_data
endfunction

" }}}

" class Room {{{

let s:Room = { 'name' : '', 'idx' : 0, 'stages' : [] }
function! s:Room.new(name) abort
  let l:ret = deepcopy(s:Room)
  let l:ret.name = a:name
  return l:ret
endfunction

" A format of a:stage_data is dict type which has following keys:
"   id         : An id of the stage
"   gen_length : A genblock length which a player can generate
"   stage      : A stage data. Type is list
function! s:Room.add_stage(stage_data)
  let stage = s:Stage.new(a:stage_data.id, a:stage_data.gen_length, a:stage_data.stage)
  call add(self.stages, stage)
endfunction

function! s:Room.get_stage() abort
  return self.stages[self.idx]
endfunction

function! s:Room.next() abort
  let self.idx += 1
endfunction

" }}}

" class Room Manager {{{

" This class is a singleton
let s:RoomManager = { 'rooms' : {} }
function! s:RoomManager.has_room(room_name) abort
  return has_key(self.rooms, a:room_name)
endfunction

function! s:RoomManager.create_room(room_name) abort
  let self.rooms[a:room_name] = s:Room.new(a:room_name)
endfunction

function! s:RoomManager.get_room(room_name) abort
  return self.rooms[a:room_name]
endfunction

" }}}

function! boxboy#add_stage(room_name, stage) abort
  if !s:RoomManager.has_room(a:room_name)
    call s:RoomManager.create_room(a:room_name)
  endif
  call s:RoomManager.get_room(a:room_name).add_stage(a:stage)
endfunction

let s:boxboy_dir = split(globpath(&runtimepath, 'autoload/boxboy'), '\n')
let s:stage_set_files = split(glob(s:boxboy_dir[0] . '/*.vim'), '\n')
for s:stage_set_file in s:stage_set_files
  execute 'source ' . s:stage_set_file
endfor

function! s:is_clear() abort
  let l:pos = getpos('.')
  return (l:pos[1] == s:goal_pos[1]) && (l:pos[2] == s:goal_pos[2])
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

" class Drawer {{{

let s:Drawer = {}
function! s:Drawer.draw_stage(stage) abort
  call setline(1, a:stage.get_data())
endfunction

function! s:Drawer.draw_information() abort
  let s:stage_bottom_line = line('$')
  call setline(line('$')+1, '')
  call setline(line('$')+1, s:room.name . ': ' . s:stage.id)
  call setline(line('$')+1, 'MAX GENERATE LENGTH: ' . s:stage.get_gen_length_max())
  call setline(line('$')+1, '')
  for l:line in s:users_guide
    call setline(line('$')+1, l:line)
  endfor
endfunction

" }}}

" Main {{{

let s:stage_bottom_line = 0

function! s:update() abort
  let l:ch = getchar(0)
  if (l:ch != 0)
    if (nr2char(l:ch) ==# 'Q')
      return 0
    endif
    call s:key_events(nr2char(l:ch))
  endif

  if (s:is_clear())
    call s:room.next()
    let s:stage = s:room.get_stage()
    %delete
    call s:Drawer.draw_stage(s:stage)
    call s:Drawer.draw_information()
    call s:move_cursor_to_start()
    call s:set_player_to_cursor()
  endif
  return 1
endfunction

function! s:open_gametab() abort
  tabnew boxboy
endfunction

function! s:close_gametab() abort
  bdelete!
endfunction

function! boxboy#main() abort
  call s:open_gametab()

  " syntax {{{
  syntax match boxboy_dir /[<^v>]/ contained
  syntax match boxboy_block /=/    contained
  syntax match boxboy_genblock /#/ contained
  syntax match boxboy_space_key /[space]/ contained
  syntax match boxboy_player /A/ contained

  syntax region boxboy_stage start=/\%^/ end=/^$/ contains=boxboy_dir,boxboy_block,boxboy_genblock,boxboy_space_key,boxboy_player

  highlight boxboy_dir_hi guibg=blue ctermbg=blue
  highlight boxboy_block_hi guifg=gray guibg=lightgray ctermfg=gray ctermbg=lightgray
  highlight boxboy_genblock_hi guifg=gray guibg=darkgray ctermfg=gray ctermbg=darkgray
  highlight boxboy_space_key_hi ctermfg=NONE
  highlight boxboy_player_hi ctermfg=NONE

  highlight default link boxboy_dir boxboy_dir_hi
  highlight default link boxboy_block boxboy_block_hi
  highlight default link boxboy_genblock boxboy_genblock_hi
  highlight default link boxboy_space_key boxboy_space_key_hi
  highlight default link boxboy_player boxboy_player_hi
  " }}}

  let s:default_room_name = 'test_play'
  let s:room  = s:RoomManager.get_room(s:default_room_name)
  let s:stage = s:room.get_stage()
  call s:Drawer.draw_stage(s:stage)
  call s:Drawer.draw_information()
  call search('G', 'w')
  let s:goal_pos = getpos('.')
  call s:move_cursor_to_start()
  call s:set_player_to_cursor()
  redraw
  while s:update()
    nohl
    redraw
  endwhile
  call s:close_gametab()
endfunction

" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
