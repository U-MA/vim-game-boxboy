" A game like boxboy(hacoboy)
" Version: 0.80
" Author: U-MA
" Lisence: VIM LICENSE

let s:save_cpo = &cpo
set cpo&vim

" Game Engine {{{

" class EventListenerPlayerReaches {{{

" position: a position which player reaches.
" func_ref: a calling func_ref which player reaches position
" args    : arguments for func_ref.
let s:EventListenerPlayerReaches = {
  \ 'position' : [0, 0], 'func_ref' : '',
  \ 'args' : [] }

function! s:EventListenerPlayerReaches.new(position, func_ref, args) abort
  let l:listener          = copy(s:EventListenerPlayerReaches)
  let l:listener.position = a:position
  let l:listener.func_ref = function(a:func_ref)
  let l:listener.args     = a:args
  return l:listener
endfunction

" }}}

" class EventDispatcher {{{

let s:EventDispatcher = { 'listeners' : [] }
function! s:EventDispatcher.register(listener) abort
  call add(self.listeners, a:listener)
endfunction

function! s:EventDispatcher.clear() abort
  let self.listeners = []
endfunction

function! s:EventDispatcher.check() abort
  for l:listner in self.listeners
    let l:position = l:listner.position
    if (l:position[0] == 0 || l:position[0] == s:player.y) &&
     \ (l:position[1] == 0 || l:position[1] == s:player.x)
      call call(l:listner.func_ref, l:listner.args)
    endif
  endfor
endfunction

" }}}

" class Action {{{

let s:Action = { 'func_ref' : '', 'args' : [], 'done' : 0 }

function! s:Action.new(func_ref, args) abort
  let l:action          = copy(s:Action)
  let l:action.func_ref = function(a:func_ref)
  let l:action.args     = a:args
  return l:action
endfunction

function! s:Action.run() abort
  call call(self.func_ref, self.args)
  let self.done = 1
endfunction

function! s:Action.init() abort
  let self.done = 0
endfunction

" }}}

" class Wait {{{
let s:Wait = { 'wait_count' : 0, 'count' : 0, 'done' : 0 }

function! s:Wait.new(wait_count) abort
  let l:wait = copy(s:Wait)
  let l:wait.wait_count = a:wait_count
  return l:wait
endfunction

function! s:Wait.run() abort
  let self.count += 1
  if self.count >= self.wait_count
    let self.done = 1
  endif
endfunction

function! s:Wait.init() abort
  let self.done  = 0
  let self.count = 0
endfunction

" }}}

" class Sequence {{{
let s:Sequence = { 'actions' : [], 'idx' : 0 }

function! s:Sequence.new() abort
  return deepcopy(s:Sequence)
endfunction

function! s:Sequence.init() abort
  for l:action in self.actions
    call l:action.init()
  endfor
endfunction

function! s:Sequence.next() abort
  let self.idx += 1

  if self.idx >= len(self.actions)
    let self.idx = 0
    call self.init()
  endif
endfunction

function! s:Sequence.add(action) abort
  call add(self.actions, a:action)
endfunction

function! s:Sequence.run() abort
  let l:action = self.actions[self.idx]
  call l:action.run()
  if l:action.done
    call self.next()
  endif
endfunction
" }}}

" class SequenceManager {{{
let s:SequenceManager = { 'sequences' : [] }

function! s:SequenceManager.register(sequence) abort
  call add(self.sequences, a:sequence)
endfunction

function! s:SequenceManager.run() abort
  for l:sequence in self.sequences
    call l:sequence.run()
  endfor
endfunction

function! s:SequenceManager.clear() abort
  let self.sequences = []
endfunction
" }}}

" }}}


" Public functions {{{

" function! boxboy#add_help_window(name, window_data) abort {{{
" window_data is a dictionary which has following keys:
"   name   : a window name
"   window : a window. value type is list.
"   start  : a player relative position from upper-left of this window
"   script : player moves following this script
function! boxboy#add_help_window(name, window_data) abort
  call s:HelpWindowManager.add_window(a:name, a:window_data)
endfunction
" }}}

" function! boxboy#add_stage(room_name, stage) abort {{{
" stage is a dictionary which has following keys:
"   TODO: add discription
function! boxboy#add_stage(room_name, stage) abort
  if !s:RoomManager.has_room(a:room_name)
    call s:RoomManager.create_room(a:room_name)
  endif
  call s:RoomManager.get_room(a:room_name).add_stage(a:stage)
endfunction
" }}}

function! boxboy#add_script(script_name, script) abort " {{{
  if !has_key(s:scripts, a:script_name)
    let s:scripts[a:script_name] = []
  endif
  call add(s:scripts[a:script_name], a:script)
endfunction
" }}}

function! boxboy#main() abort "{{{
  call s:boxboy_main()
endfunction
" }}}

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

" class Stack {{{
" Note: Stack size is 10

let s:Stack = { 'data': [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ], 'head': -1 }

function! s:Stack.new() abort
  return copy(s:Stack)
endfunction

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
  endfor
endfunction

" }}}

" class GenBlock {{{

" start is [ row, col ]
let s:GenBlock = { 'start' : [0, 0], 'dirctions' : {}, 'head' : [0, 0], 'len' : 0 }
function! s:GenBlock.new(start) abort
  let l:ret = deepcopy(s:GenBlock)
  let l:ret.start = copy(a:start)
  let l:ret.directions = s:Stack.new()
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

function! s:genblock_move_cursor(head) abort
  if a:head[0] > 0
    execute 'normal! ' . a:head[0] . 'j'
  elseif a:head[0] < 0
    execute 'normal! ' . a:head[0] . 'k'
  endif
  
  if a:head[1] > 0
    execute 'normal! ' . a:head[1] . 'l'
  elseif a:head[1] < 0
    execute 'normal! ' . a:head[1] . 'h'
  endif
endfunction

function! s:GenBlock.extend(dir) abort
  call s:genblock_move_cursor(self.head)
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
  let l:ret   = deepcopy(s:Player)
  let l:ret.x = a:col
  let l:ret.y = a:row
  let l:ret.genblock = s:GenBlock.new([a:row, a:col])
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
    let self.prev_dir = a:dir
  elseif a:dir ==# 'l'
    execute 'normal! r lr' . s:PLAYER_CH
    let self.x += 1
    let self.prev_dir = a:dir
  elseif a:dir ==# ' '
    execute 'normal! r kr' . s:PLAYER_CH
    let self.y -= 1
    call self.move(self.prev_dir)
  endif
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

function! s:set_cursor_to_player() abort
  call cursor(s:player.y, s:player.x)
endfunction

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
    if s:getchar_on('j') =~# '[=AOG]'
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
  "echo s:stage_bottom_line
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
  return s:player.genblock.len > 0
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
  echomsg string(l:ret.player.genblock.head)

  return l:ret
endfunction

function! s:HelpWindow.set_pos(row, col) abort
  let self.pos[0] = a:row
  let self.pos[1] = a:col
endfunction

let s:is_set_hi = 0
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
    if l:key ==# '*'
      highlight boxboy_right_key ctermfg=darkgray
      let s:is_set_hi = 1
      let self.turn += 1
      let l:key = self.script[self.turn]
    endif
    call self.player.move(l:key)
    redraw
    let self.turn += 1
    if s:is_set_hi
      sleep 250m
      highlight boxboy_right_key ctermfg=NONE
      let s:is_set_hi = 0
    endif
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
  call setline(1, a:stage.stage())
endfunction

function! s:Drawer.draw_information() abort
  let s:stage_bottom_line = line('$')
  call setline(line('$')+1, '')
  call setline(line('$')+1, 'STAGE ' . s:room.name . '-' . s:stage.id())
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

function! s:Drawer.erase_help_window(help_window, row, col) abort
  call cursor(a:row, a:col)
  for l:line in a:help_window.window
    execute 'normal! v' . len(l:line) . 'lr j'
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
    execute 'normal! r jr' . s:PLAYER_CH
    let s:player.y += 1
    redraw!
  endwhile
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
    if s:player.genblock.len >= s:stage.get_gen_length_max()
      return
    elseif a:key ==# 'h'
      let s:player.prev_dir = 'h'
      if s:is_movable('h') && s:getchar_on('h') != 'G'
        call s:player.extend_block('h')
      endif
    elseif a:key ==# 'j'
      if s:is_movable('j') && s:getchar_on('j') != 'G'
        call s:player.extend_block('j')
      endif
    elseif a:key ==# 'k'
      if s:is_movable('k') && s:getchar_on('k') != 'G'
        call s:player.extend_block('k')
      endif
    elseif a:key ==# 'l'
      let s:player.prev_dir = 'l'
      if s:is_movable('l') && s:getchar_on('l') != 'G'
        call s:player.extend_block('l')
      endif
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
    let s:player.prev_dir = 'l'
    if s:is_movable('l')
      call s:player.move('l')
    endif
  elseif a:key ==# 'h'
    let s:player.prev_dir = 'h'
    if s:is_movable('h')
      call s:player.move('h')
    endif
  elseif a:key ==# ' '
    if s:is_movable('k')
      call s:player.jump()
    endif
    if s:is_movable(s:player.prev_dir)
      call s:player.move(s:player.prev_dir)
    endif
  elseif a:key ==# 'f'
    if s:can_hook()
      call s:player.hook_shot()
    endif
  elseif a:key ==# 'x'
    call s:erase_blocks()
    call s:player.init_block()
  endif
endfunction

function! s:key_events(key) abort
  if a:key ==# 't'
    call s:player.toggle_mode()
    if s:player.mode
      call s:erase_blocks()
      call s:set_hilight_ch()
    else
      call s:reset_hilight_ch()
    endif
    return
  endif

  if s:player.mode
    " BLOCK GENEREATE MODE
    let l:pos = s:player.genblock.head
    call cursor(l:pos[0], l:pos[1])
    "echo getpos('.')
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

let s:Stage = { 'stage_data' : {} }
function! s:Stage.new(stage_data) abort
  let l:ret = deepcopy(s:Stage)
  let l:ret.stage_data = a:stage_data
  return l:ret
endfunction

function! s:Stage.has_help_window() abort
  return has_key(self.stage_data, 'help_window')
endfunction

function! s:Stage.id() abort
  return self.stage_data.id
endfunction

function! s:Stage.get_gen_length_max() abort
  return self.stage_data.gen_length
endfunction

function! s:Stage.stage() abort
  return self.stage_data.stage
endfunction

function! s:Stage.help_window() abort
  return self.stage_data.help_window
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
  let stage = s:Stage.new(a:stage_data)
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

" }}}

function! s:get_hilight_name(key) abort " {{{
  if a:key ==# 'h'
    return 'left_key'
  elseif a:key ==# 'l'
    return 'right_key'
  elseif a:key ==# ' '
    return 'jump_key'
  elseif a:key ==# 't'
    return 'toggle_key'
  endif
endfunction
" }}}

" Callback functions {{{

function! s:cb_init_help_window(help_window) abort " {{{
  let l:player = a:help_window.player
  let l:abs_position = [
    \ a:help_window.pos[0]+l:player.y-1,
    \ a:help_window.pos[1]+l:player.x-1]
  call cursor(l:abs_position[0], l:abs_position[1])
  execute 'normal! r '
  let l:player.x = a:help_window.start[1]
  let l:player.y = a:help_window.start[0]
  call cursor(a:help_window.pos[0]+l:player.y-1,
    \         a:help_window.pos[1]+l:player.x-1)
  execute 'normal! rA'
endfunction
" }}}

function! s:cb_player_in_window_moves(help_window, player, key) abort " {{{
  let l:abs_position = [
    \ a:help_window.pos[0]+a:player.y-1,
    \ a:help_window.pos[1]+a:player.x-1]
  call cursor(l:abs_position[0], l:abs_position[1])
  call a:player.move(a:key)
endfunction
" }}}

function! s:cb_player_generate_block(help_window, player, key) abort
  let l:abs_position = [
    \ a:help_window.pos[0]+a:player.y-1,
    \ a:help_window.pos[1]+a:player.x-1]
  call cursor(l:abs_position[0], l:abs_position[1])
  call a:player.extend_block(a:key)
endfunction

function! s:cb_player_toggle_mode(help_window, player) abort
  call a:player.toggle_mode()
endfunction

function! s:cb_set_hl_specifing_string(str) abort " {{{
  execute 'highlight boxboy_' . a:str . ' ctermfg=darkgray'
endfunction
" }}}

function! s:cb_reset_hl_specifing_string(str) abort " {{{
  execute 'highlight boxboy_' . a:str . ' ctermfg=NONE'
endfunction
" }}}

" function! s:create_sequence_with_script(help_window) abort {{{
" Script formats
"  h       : player move left  / genblock extend to left
"  j       : nop               / genblock extend to down
"  k       : nop               / genblock extend to up
"  l       : player move right / genblock extend to right
"  <space> : player jumps to a previous direction / nop
"  t       : player mode toggles
let s:toggle_on = 0
function! s:create_sequence_with_script(help_window) abort
  let l:sequence = s:Sequence.new()
  call l:sequence.add(s:Wait.new(5000))
  for l:i in range(0, len(a:help_window.script)-1)
    let l:ch = a:help_window.script[l:i]
    let l:hl_name = s:get_hilight_name(l:ch)
    if l:ch ==# 't' " TOGGLE
      let s:toggle_on = !s:toggle_on
      call l:sequence.add(
        \ s:Action.new('s:cb_set_hl_specifing_string', [l:hl_name]))
      call l:sequence.add(
        \ s:Action.new('s:cb_player_toggle_mode',
        \ [a:help_window, a:help_window.player]))
      call l:sequence.add(s:Wait.new(500))
      call l:sequence.add(
        \ s:Action.new('s:cb_reset_hl_specifing_string', [l:hl_name]))
      call l:sequence.add(s:Wait.new(5000))
    else
      if !s:toggle_on
        call l:sequence.add(
          \ s:Action.new('s:cb_set_hl_specifing_string', [l:hl_name]))
        call l:sequence.add(
          \ s:Action.new('s:cb_player_in_window_moves',
          \ [a:help_window, a:help_window.player, l:ch]))
        call l:sequence.add(s:Wait.new(500))
        call l:sequence.add(
          \ s:Action.new('s:cb_reset_hl_specifing_string', [l:hl_name]))
        call l:sequence.add(s:Wait.new(5000))
      else
        call l:sequence.add(
          \ s:Action.new('s:cb_set_hl_specifing_string', [l:hl_name]))
        call l:sequence.add(
          \ s:Action.new('s:cb_player_generate_block',
          \ [a:help_window, a:help_window.player, l:ch]))
        call l:sequence.add(s:Wait.new(500))
        call l:sequence.add(
          \ s:Action.new('s:cb_reset_hl_specifing_string', [l:hl_name]))
        call l:sequence.add(s:Wait.new(5000))
      endif
    endif
  endfor
  call l:sequence.add(
    \ s:Action.new('s:cb_init_help_window',
    \ [a:help_window]))
  return l:sequence
endfunction
" }}}

let s:is_draw_hw = 0

function! s:cb_go_to_next_stage() abort " {{{
  %delete
  if (s:room.has_next())
    call s:room.next()
    let s:stage = s:room.get_stage()

    call s:SequenceManager.clear()

    call s:Drawer.draw_stage(s:stage)
    call s:Drawer.draw_information()

    call s:setup_events()

    call s:move_cursor_to_start()
    call s:set_player_to_cursor()
    let l:pos = getpos('.')
    let s:player = s:Player.new(l:pos[1], l:pos[2])
  else
    call s:EventDispatcher.clear()
    call s:Drawer.draw_appriciate()
    call getchar()
  endif
endfunction
" }}}

" function! s:cb_open_help_window(help_window, upper_left) abort {{{
" Draw a help window on upper_left position.
"   help_window: a drawing window
function! s:cb_open_help_window(help_window, upper_left) abort
  if !s:is_draw_hw
    let s:is_draw_hw = 1
    call s:Drawer.draw_help_window(a:help_window, a:upper_left[0], a:upper_left[1])
    let a:help_window.pos = copy(a:upper_left)

    " Register a window actions to SequenceManager
    let l:sequence = s:create_sequence_with_script(a:help_window)
    call s:SequenceManager.register(l:sequence)
  endif
endfunction
" }}}

function! s:cb_close_help_window(help_window, upper_left) abort " {{{
  if s:is_draw_hw
    let s:is_draw_hw = 0
    call s:Drawer.erase_help_window(a:help_window, a:upper_left[0], a:upper_left[1])

    " Erase a window actions to Sequencemanager
    call s:SequenceManager.clear()
  endif
endfunction
" }}}

function! s:cb_help_window_actions() abort " {{{
  " This function writes a behavior of player in help window
  " TODO: WRITE
  echo 'cb_help_window_actions'
endfunction
" }}}

" }}}

function! s:setup_events() abort " {{{
  " Note: This function assume that a stage already has been drawn.

  " Clear all listeners which have already been registered.
  call s:EventDispatcher.clear()

  " Register a help window to EventDispatcher
  if s:stage.has_help_window()
    let l:help_window = s:stage.help_window()
    let l:window      = s:HelpWindowManager.get_window(l:help_window.name)

    call s:EventDispatcher.register(s:EventListenerPlayerReaches.new(
      \ l:help_window.start,
      \ 's:cb_open_help_window',
      \ [ l:window, l:help_window.draw_position ]))

    call s:EventDispatcher.register(s:EventListenerPlayerReaches.new(
      \ l:help_window.end,
      \ 's:cb_close_help_window',
      \ [ l:window, l:help_window.draw_position ]))
  endif

  " Note: Do not process a stage which dont exist G(goal)
  execute 'normal! gg0'
  call search('G', 'w', s:stage_bottom_line)
  let l:goal_pos = getpos('.')
  call s:EventDispatcher.register(s:EventListenerPlayerReaches.new(
    \ l:goal_pos[1:2],
    \ 's:cb_go_to_next_stage',
    \ []))
endfunction
" }}}

function! s:update() abort " {{{
  " This function is kernel of this game.

  " process Player event
  let l:ch = getchar(0)
  if l:ch != 0
    if nr2char(l:ch) ==# 'Q'
      return 0
    endif
    call s:key_events(nr2char(l:ch))
  endif

  " Gravity
  " player mode is PLAYER MOVE MODE
  if s:player.mode == 0
    call s:set_cursor_to_player()
    call s:down()
    call s:genblocks_fall_if_possible()
  endif

  call s:SequenceManager.run()
  call s:EventDispatcher.check()

  return 1
endfunction
" }}}

function! s:open_gametab() abort " {{{
  tabnew boxboy
endfunction
" }}}

function! s:close_gametab() abort " {{{
  bdelete!
endfunction
" }}}

function! s:setup_view(stage) abort " {{{
  " This function set up a view which game player watches.
  call s:Drawer.draw_stage(s:stage)
  call s:Drawer.draw_information()
endfunction
" }}}

function! s:boxboy_main() abort " {{{
  call s:open_gametab()

  " syntax {{{
  syntax match boxboy_dir /[<^v>]/ contained
  syntax match boxboy_block /=/    contained
  syntax match boxboy_genblock /#/ contained
  syntax match boxboy_player /A/ contained
  syntax match boxboy_jump_key /\[space\]/ contained
  syntax match boxboy_right_key /l/ contained
  syntax match boxboy_left_key /h/ contained
  syntax match boxboy_toggle_key /t/ contained

  syntax region boxboy_stage start=/\%^/ end=/^$/
    \ contains=boxboy_dir,boxboy_block,boxboy_genblock,boxboy_space_key,boxboy_player,boxboy_right_key,boxboy_jump_key,boxboy_left_key,boxboy_toggle_key

  highlight boxboy_dir_hi guibg=blue ctermbg=blue
  highlight boxboy_block_hi guifg=gray guibg=lightgray ctermfg=gray ctermbg=lightgray
  highlight boxboy_genblock_hi guifg=gray guibg=darkgray ctermfg=gray ctermbg=darkgray
  highlight boxboy_jump_key_hi ctermfg=NONE
  highlight boxboy_right_key_hi ctermfg=NONE
  highlight boxboy_left_key_hi ctermfg=NONE
  highlight boxboy_toggle_key_hi ctermfg=NONE
  highlight boxboy_player_hi ctermfg=NONE

  highlight default link boxboy_dir boxboy_dir_hi
  highlight default link boxboy_block boxboy_block_hi
  highlight default link boxboy_genblock boxboy_genblock_hi
  highlight default link boxboy_space_key boxboy_space_key_hi
  highlight default link boxboy_right_key boxboy_right_key_hi
  highlight default link boxboy_left_key boxboy_left_key_hi
  highlight default link boxboy_jump_key boxboy_jump_key_hi
  highlight default link boxboy_toggle_key boxboy_toggle_key_hi
  highlight default link boxboy_player boxboy_player_hi
  " }}}

  let s:default_room_name = 'test_play'

  " s:room is the current room which player is in.
  let s:room  = s:RoomManager.get_room(s:default_room_name)

  " s:stage is the current stage which player is playing.
  let s:stage = s:room.get_stage()

  call s:setup_view(s:stage)

  call s:setup_events()

  " playable character
  call s:move_cursor_to_start()
  call s:set_player_to_cursor()
  let l:pos = getpos('.')
  let s:player = s:Player.new(l:pos[1], l:pos[2])

  while 1
    redraw
    let l:start = reltime()

    if !s:update()
      break
    endif
    nohlsearch

    let l:elapsed = reltime(l:start)
    let l:sec = l:elapsed[0] + l:elapsed[1] / 1000000.0
    let l:fps = 1.0 / l:sec
    call setline(s:stage_bottom_line+1, string(l:fps))
  endwhile
  call s:close_gametab()
endfunction
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
