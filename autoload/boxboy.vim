" A game like boxboy(hacoboy)
" Version: 0.80
" Author: U-MA
" Lisence: VIM LICENSE

let s:save_cpo = &cpo
set cpo&vim

" Public functions {{{

" window_data is a dictionary which has following keys:
"   name   : a window name
"   window : a window. value type is list.
"   start  : a player relative position from upper-left of this window
"   script : player moves following this script
function! boxboy#add_help_window(name, window_data) abort
  call s:HelpWindowManager.add_window(a:name, a:window_data)
endfunction

" stage is a dictionary which has following keys:
"   TODO: add discription
function! boxboy#add_stage(room_name, stage) abort
  if !s:RoomManager.has_room(a:room_name)
    call s:RoomManager.create_room(a:room_name)
  endif
  call s:RoomManager.get_room(a:room_name).add_stage(a:stage)
endfunction

function! boxboy#add_script(script_name, script) abort
  if !has_key(s:scripts, a:script_name)
    let s:scripts[a:script_name] = []
  endif
  call add(s:scripts[a:script_name], a:script)
endfunction

" }}}


" Constant values {{{

let s:PLAYER_CH = 'A'

" Blocks {{{
let s:gen_block_ch = '#'
let s:blocks = [ '=', '#', 'O' ]
" }}}

" }}}

" Global values {{{

  let s:scripts = {}
  let s:stage_bottom_line = 0

" }}}


" Change view depending on player's mode {{{

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

" Block generater{{{

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

" class GenBlock {{{

" start is [ row, col ]
let s:GenBlock = { 'start' : [0, 0], 'dirctions' : {}, 'head' : [0, 0], 'len' : 0 }
function! s:GenBlock.new(start) abort
  let l:ret = deepcopy(s:GenBlock)
  let l:ret.start = a:start
  let l:ret.head  = a:start
  let l:ret.directions = s:NewStack()
  return l:ret
endfunction

function! s:GenBlock.move_head(dir) abort
  if a:dir ==# 'h'
    let self.head[1] -= 1
  elseif a:dir ==# 'j'
    let self.head[0] += 1
  elseif a:dir ==# 'k'
    let self.head[0] -= 1
  elseif a:dir ==# 'l'
    let self.head[1] += 1
  endif
endfunction

function! s:GenBlock.extend(dir) abort
  call cursor(self.head[0], self.head[1])
  execute 'normal! ' . a:dir . 'r' . s:gen_block_ch
  call self.move_head(a:dir)
  call self.directions.push(a:dir)
  let self.len += 1
endfunction

function! s:GenBlock.shrink() abort
  let l:rev = { 'h' : 'l', 'j' : 'k', 'k' : 'j', 'l' : 'h' }
  let l:ch = l:rev[self.directions.pop()]
  call cursor(self.head[0], self.head[1])
  execute 'normal! r ' . l:ch
  call self.move_head(l:ch)
  let self.len -= 1
endfunction

" }}}

let s:stack = s:NewStack()

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

" class Player {{{

" Note: player do not detect any collisions.
" Note: player repaint gamebuffer.

" mode is 0 or 1.
"   mode 0 is PLAYER MOVE MODE
"   mode 1 is BLOCK GENERATE MODE
" prev_dir is a direction which player move to previously
" genblock is GenBlock class
let s:Player = { 'x' : 0, 'y' : 0 , 'mode' : 0, 'prev_dir' : 'l', 'genblock' : {} }
function! s:Player.new(row, col) abort
  let l:ret   = copy(s:Player)
  let l:ret.x = a:col
  let l:ret.y = a:row
  let l:genblock = s:GenBlock.new([a:row, a:col])
  return l:ret
endfunction

function! s:Player.toggle_mode() abort
  if self.mode == 0
    " TOGGLE TO GENERATE BLOCK MODE
    echo 'GENERATE BLOCK MODE'
    let self.genblock = s:GenBlock.new([self.y, self.x])
    let self.mode = 1
  else
    " TOGGLE TO PLAYER MOVE MODE
    echo 'PLAYER MOVE MODE'
    let l:pos = s:player.genblock.head
    call cursor(l:pos[0], l:pos[1])
    call s:reset_hilight_ch()
    let self.mode = 0
  endif
endfunction

" Player moves to a specifiing direction.
function! s:Player.move(dir) abort
  if a:dir ==# 'h'
    execute 'normal! r hr' . s:PLAYER_CH
    let self.x -= 1
  elseif a:dir ==# 'l'
    execute 'normal! r lr' . s:PLAYER_CH
    let self.x += 1
  endif
  let self.prev_dir = a:dir
endfunction

" Player jumps up.
function! s:Player.jump() abort
  execute 'normal! r kr' . s:PLAYER_CH
  let self.y -= 1
endfunction

" Player hookshots before 'O'
function! s:Player.hook_shot() abort
  if s:player.prev_dir ==# 'l'
    execute 'normal! r '
    execute 'normal! tOr' . s:PLAYER_CH
  else
    execute 'normal! r '
    execute 'normal! TOr' . s:PLAYER_CH
  endif
  let s:player.x = col('.')
endfunction

function! s:Player.init_block() abort
  let self.genblock = s:GenBlock.new([self.y, self.x])
endfunction

function! s:Player.extend_block(dir) abort
  call self.genblock.extend(a:dir)
endfunction

function! s:Player.shrink_block(dir) abort
  call self.genblock.shrink(a:dir)
endfunction

" }}}


" Utility {{{

function! s:genblocks_fall_if_possible() abort
  if s:exist_genblocks()
    while s:can_fall()
      call s:move_down_gen_blocks()
    endwhile
  endif
endfunction

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


" Help window {{{

" class HelpWindow {{{

let s:HelpWindow = { 'name' : '', 'window' : [], 'pos' : [0, 0], 'start' : [0, 0], 'script' : '', 'turn' : 0, 'player' : {} }
function! s:HelpWindow.new(name, window, start, script) abort
  let l:ret = deepcopy(s:HelpWindow)
  let l:ret.name   = a:name
  let l:ret.window = a:window
  let l:ret.start  = a:start
  let l:ret.script = a:script

  " player position is a relative position from upper-left of window
  let l:ret.player = s:Player.new(a:start[0], a:start[1])

  return l:ret
endfunction

function! s:HelpWindow.set_pos(row, col) abort
  let self.pos[0] = a:row
  let self.pos[1] = a:col
endfunction

function! s:HelpWindow.move() abort
  call cursor(self.player.y+self.pos[0], self.player.x+self.pos[1])
  if (self.turn >= len(self.script))
    let self.turn = 0
    execute 'normal! r '
    let self.player.x = self.start[1]
    let self.player.y = self.start[0]
    call cursor(self.player.y+self.pos[0], self.player.x+self.pos[0])
    execute 'normal! r' . s:PLAYER_CH
  else
    let l:key = self.script[self.turn]
    call self.player.move(l:key)
    let self.turn += 1
  endif
endfunction
" }}}

" class HelpWindowManager {{{

" window is a dictionary which has following keys:
"   name   : Window name
"   window : A list of string.
"   start  : Player initial position. [ row, col ]. upper-left is [0, 0]
"   script : Player moves following this script
let s:HelpWindowManager = { 'windows' : {} }
function! s:HelpWindowManager.add_window(name, window) abort
  let self.windows[a:name] = s:HelpWindow.new(a:window.name, a:window.window, a:window.start, a:window.script)
endfunction

function! s:HelpWindowManager.get_window(name) abort
  return self.windows[a:name]
endfunction

" }}}

"}}}

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
  for l:line in s:scripts['user_guide']
    call setline(line('$')+1, l:line)
  endfor
endfunction

function! s:Drawer.draw_appriciate() abort
  for l:line in s:scripts['congrats']
    call setline(line('$')+1, l:line)
  endfor
endfunction

" (row, col) is the upper-left corner.
function! s:Drawer.draw_help_window(help_window, row, col) abort
  call cursor(a:row, a:col)
  for l:line in a:help_window.window
    call s:replace(l:line)
    execute 'normal! j'
  endfor
endfunction

" }}}

" class MovableObjectsManager {{{

" All registered objects MUST have move().
let s:MovableObjectsManager = { 'objects' : [] }
function! s:MovableObjectsManager.add(object) abort
  call add(self.objects, a:object)
endfunction

function! s:MovableObjectsManager.clear() abort
  let self.objects = []
endfunction

" All registered objects invoke move()
function! s:MovableObjectsManager.move() abort
  for l:obj in self.objects
    call l:obj.move()
  endfor
endfunction

" }}}

" Key event {{{

function! s:down() abort
  if s:is_block(s:getchar_on('j'))
    return
  endif

  while !s:is_block(s:getchar_on('j'))
    sleep 250m
    execute 'normal! r jr' . s:PLAYER_CH
    let s:player.y += 1
    redraw!
  endwhile
  sleep 150m
endfunction

function! s:erase_blocks() abort
  let tmp_pos = getpos('.')
  execute 'normal! gg0'
  if search('#', 'W')
    silent %substitute/#/ /g
  endif
  call setpos('.', tmp_pos)
endfunction

" cursor MUST point to player
function! s:can_hook() abort
  let line = getline('.')
  if s:player.prev_dir ==# 'l'
    return match(line[col('.')-1:], 'A\s*O') != -1
  else
    return match(line[:col('.')-1], 'O\s*A') != -1
  endif
endfunction

function! s:process_genmode(key) abort
  call s:reset_hilight_ch()
  try
    if !s:stack.empty() && s:reverse_dir(a:key) ==# s:stack.top()
      echo 'nonono'
      call s:resume_genblock()
    elseif s:player.genblock.len >= s:stage.get_gen_length_max()
      return
    elseif a:key ==# 'h'
      call s:player.extend_block('h')
    elseif a:key ==# 'j'
      call s:player.extend_block('j')
    elseif a:key ==# 'k'
      call s:player.extend_block('k')
    elseif a:key ==# 'l'
      echo 'right'
      call s:player.extend_block('l')
    endif
  catch /^Stack.*/
    echomsg 'key_events:stack is empty'
  endtry
  if s:player.genblock.len < s:stage.get_gen_length_max()
    call s:set_hilight_ch()
  endif
endfunction

function! s:process_movemode(key) abort
  " TODO: detect some collisions
  if a:key ==# 'l'
    if s:is_movable('l')
      call s:player.move('l')
    endif
  elseif a:key ==# 'h'
    if s:is_movable('h')
      call s:player.move('h')
    endif
  elseif a:key ==# ' '
    call s:player.jump()
    if s:is_movable(s:player.prev_dir)
      call s:player.move(s:player.prev_dir)
    endif

    " TODO:
    " for stop always jump
    " But ugly code
    " Hope beautiful code
    let l:i = getchar(0)
    while l:i
      let l:i = getchar(0)
    endwhile
    call feedkeys(nr2char(l:i), 't')
  elseif a:key ==# 'f'
    if s:can_hook()
      call s:player.hook_shot()
    endif
  elseif a:key ==# 'x'
    call s:erase_blocks()
  endif
endfunction

function! s:key_events(key) abort
  if a:key ==# 't'
    call s:player.toggle_mode()
    if s:player.mode
      call s:erase_blocks()
    endif
    return
  endif

  if s:player.mode
    " BLOCK GENEREATE MODE
    let l:pos = s:player.genblock.head
    call cursor(l:pos[0], l:pos[1])
    echo getpos('.')
    call s:process_genmode(a:key)
  else
    " PLAYER MOVE MODE
    call s:set_cursor_to_player()
    call s:process_movemode(a:key)
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

function! s:Room.has_next() abort
  return self.idx+1 < len(self.stages)
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

" Main {{{

function! s:set_cursor_to_player() abort
  call cursor(s:player.y, s:player.x)
endfunction

let s:FRATE = 5000
let s:frate = 0

" This function is kernel of this game.
function! s:update() abort

  " process Player event {{{
  let l:ch = getchar(0)
  if l:ch != 0
    if nr2char(l:ch) ==# 'Q'
      return 0
    endif
    call s:key_events(nr2char(l:ch))
  endif
  " }}}

  " Gravity {{{
  " player mode is PLAYER MOVE MODE
  if s:player.mode == 0
    call s:set_cursor_to_player()
    call s:down()
    call s:genblocks_fall_if_possible()
  endif
  " }}}

  " Repeat object moves {{{
  "if s:frate > s:FRATE
  "  call s:MovableObjectsManager.move()
  "  let s:frate = 0
  "endif
  "let s:frate += 1
  " }}}

  " Is checking stage clear in update() ?
  " clear check {{{
  if (s:is_clear())
    if (s:room.has_next())
      call s:room.next()
      let s:stage = s:room.get_stage()
      %delete
      call s:Drawer.draw_stage(s:stage)
      call s:Drawer.draw_information()
      call search('G', 'w')
      let s:goal_pos = getpos('.')
      call s:move_cursor_to_start()
      call s:set_player_to_cursor()
      let l:pos = getpos('.')
      let s:player = s:Player.new(l:pos[1], l:pos[2])
      call s:MovableObjectsManager.clear()
    else
      %delete
      call s:Drawer.draw_appriciate()
      call getchar()
      return 0
    endif
  endif
  " }}}

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

  " playable character
  let l:pos = getpos('.')
  let s:player = s:Player.new(l:pos[1], l:pos[2])

  while 1
    redraw
    let l:start = reltime()

    if !s:update()
      break
    endif
    nohl

    let l:elapsed = reltime(l:start)
    let l:sec = l:elapsed[0] + l:elapsed[1] / 1000000.0
    let l:fps = 1.0 / l:sec
    call setline(1, string(l:fps))
  endwhile
  call s:close_gametab()
endfunction

" }}}


let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
