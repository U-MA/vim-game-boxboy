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
    if (l:position[0] == 0 || l:position[0] == s:player.position[0]) &&
     \ (l:position[1] == 0 || l:position[1] == s:player.position[1])

      let l:ret = call(l:listner.func_ref, l:listner.args)

      if (l:ret)
        return 1
      endif
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

" Library {{{

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

" class Vecter {{{

let s:Vector = { 'data' : [], 'size' : 0 }

function! s:Vector.new() abort
  return deepcopy(s:Vector)
endfunction

function! s:Vector.empty() abort
  return self.size == 0
endfunction

" return 0 if vector is empty
function! s:Vector.tail() abort
  if !self.empty()
    return self.data[self.size-1]
  endif
endfunction

function! s:Vector.push_back(elem) abort
  call add(self.data, a:elem)
  let self.size += 1
endfunction

" return 0 if vector is empty
function! s:Vector.pop_back() abort
  if !self.empty()
    let l:elem = self.data[self.size-1]
    call remove(self.data, self.size-1)
    let self.size -= 1
    return l:elem
  endif
endfunction

function! s:Vector.range() abort
  return self.data
endfunction

" }}}

" }}}


" Utility {{{

function! s:set_cursor_to_player() abort " {{{
  call cursor(s:player.position[0], s:player.position[1])
endfunction
" }}}

function! s:move_cursor_to_start() abort " {{{
  execute 'normal! gg0'
  call search('S', 'W')
endfunction
" }}}

function! s:replace(str) abort " {{{
  let l:pos = getpos('.')
  execute 'normal! ' . len(a:str) . 'x'
  execute 'normal! i' . a:str
  call cursor(l:pos[1], l:pos[2])
endfunction
" }}}

function! s:move_ch_on_cursor_to(dir) abort " {{{
  let l:ch  = s:getchar_on_cursor()
  let l:pos = getpos('.')
  execute 'normal! r ' . a:dir . 'r' . l:ch
  call cursor(l:pos[1], l:pos[2])
endfunction
" }}}

function! s:reverse_dir(dir) abort " {{{
  let l:reverse_dir = {'h' : 'l', 'j' : 'k', 'k' : 'j', 'l' : 'h'}
  return l:reverse_dir[a:dir]
endfunction
" }}}

function! s:setchar_on(dir, ch) abort " {{{
  execute 'normal! ' . a:dir . 'r' . a:ch
  execute 'normal! ' . s:reverse_dir(a:dir)
endfunction
" }}}

function! s:getchar_on_cursor() abort " {{{
  return getline('.')[col('.')-1]
endfunction
" }}}

function! s:set_player_to_cursor() abort " {{{
  execute 'normal! r' . s:PLAYER_CH
endfunction
" }}}

function! s:getchar_on(dir) abort " {{{
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
" }}}

function! s:is_block(ch) abort " {{{
  for l:i in s:blocks
    if l:i ==# a:ch
      return 1
    endif
  endfor
  return 0
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
  let s:genblock_in_stage = {}

" }}}


" class Hilighter {{{

let s:Highlighter = { 'save_ch' : [] }

function! s:Highlighter.new() abort
  return deepcopy(s:Highlighter)
endfunction

function! s:Highlighter.set() abort
  let l:arrows = {'h' : '<', 'j' : 'v', 'k' : '^', 'l' : '>'}
  for l:dir in ['h', 'j', 'k', 'l']
    let l:ch = s:getchar_on(l:dir)
    call add(self.save_ch, l:ch)
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

function! s:Highlighter.reset() abort
  if empty(self.save_ch)
    return
  endif

  call s:setchar_on('h', self.save_ch[0])
  call s:setchar_on('j', self.save_ch[1])
  call s:setchar_on('k', self.save_ch[2])
  call s:setchar_on('l', self.save_ch[3])
  let self.save_ch = []
endfunction

" }}}

" class GenBlock {{{

" Note: parent_position is read only

" generating start position is
"   curosr(self.parent_position[0] + self.position[0] - 1,
"     \    self.parent_position[1] + self.position[1] - 1)
let s:GenBlock = { 'position' : [1, 1], 'dirctions' : {}, 'head' : [0, 0],
                 \ 'length' : 0, 'parent_position' : [1, 1], 'is_check' : 1, 'highlighter' : {} }
function! s:GenBlock.new(parent_position) abort
  let l:genblock                 = deepcopy(s:GenBlock)
  let l:genblock.directions      = s:Vector.new()
  let l:genblock.parent_position = a:parent_position
  let l:genblock.highlighter     = s:Highlighter.new()
  return l:genblock
endfunction

function! s:GenBlock.can_fall() abort
  if self.is_check == 0
    return 0
  endif

  call cursor(self.parent_position[0] + self.position[0] - 1,
        \         self.parent_position[1] + self.position[1] - 1)
  for l:block in self.directions.range()
    execute 'normal! ' . l:block
    let l:ch = s:getchar_on('j')
    if l:ch =~# '[=AOG]'
      if l:ch ==# 'A'
        let self.is_check = 1
      else
        let self.is_check = 0
      endif
      return 0
    endif
  endfor
  let self.is_check = 1
  return 1
endfunction

function! s:GenBlock.remove_self() abort
  call cursor(self.parent_position[0] + self.position[0] - 1,
    \         self.parent_position[1] + self.position[1] - 1)
  for l:dir in self.directions.range()
    execute 'normal! ' . l:dir
    execute 'normal! r '
  endfor
endfunction

function! s:GenBlock.fall_if_possible() abort
  if self.can_fall()
    call self.remove_self()
    let self.position[0] += 1
    call cursor(self.parent_position[0] + self.position[0] - 1,
      \         self.parent_position[1] + self.position[1] - 1)
    for l:dir in self.directions.range()
      execute 'normal! ' . l:dir . 'r#'
    endfor
  endif
endfunction

function! s:GenBlock.set_position(position) abort
  let self.position = copy(a:position)
endfunction

function! s:GenBlock.set_cursor_to_head() abort
  call cursor(self.parent_position[0] + self.position[0] + self.head[0] - 1,
    \         self.parent_position[1] + self.position[1] + self.head[1] - 1)
endfunction

function! s:GenBlock.is_shrink_dir(dir) abort
  if !self.directions.empty()
    return self.directions.tail() ==# s:reverse_dir(a:dir)
  endif
  return 0
endfunction

function! s:GenBlock.is_extendable(dir) abort
  let l:ch = s:getchar_on(a:dir)
  return !s:is_block(l:ch) && (l:ch !=# 'G' && l:ch !=# 'A')
endfunction

function! s:GenBlock.extend(dir) abort
  call cursor(self.parent_position[0] + self.position[0] + self.head[0] - 1,
    \         self.parent_position[1] + self.position[1] + self.head[1] - 1)

  call self.highlighter.reset()
  if self.is_extendable(a:dir)
    execute 'normal! ' . a:dir . 'r' . s:gen_block_ch
    call self.move_head(a:dir)
    call self.directions.push_back(a:dir)
    let self.length += 1
  endif
  call self.highlighter.set()
endfunction

function! s:GenBlock.shrink() abort
  call cursor(self.parent_position[0] + self.position[0] + self.head[0] - 1,
    \         self.parent_position[1] + self.position[1] + self.head[1] - 1)
  call self.highlighter.reset()
  let l:ch = s:reverse_dir(self.directions.pop_back())
  execute 'normal! r ' . l:ch
  call self.move_head(l:ch)
  let self.length -= 1
  call self.highlighter.set()
endfunction

" class GenBlock private functions {{{

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

" }}}

" }}}

" class Player {{{

" Note: player do not detect any collisions.
" Note: player repaint gamebuffer.

" mode is 0 or 1.
"   mode 0 is PLAYER MOVE MODE
"   mode 1 is BLOCK GENERATE MODE
" prev_dir is a direction which player move to previously
" genblock is GenBlock class
" parent is an owner of this player. if empty(parent) is true,
" the owner of this player is game. parent is read only.
" TODO: FIX
let s:Player = { 'position' : [1, 1] , 'mode' : 0, 'prev_dir' : 'l',
  \              'genblock' : {}, 'parent_position' : [1, 1], 'parent' : {} }

function! s:Player.new(position) abort " {{{
  let l:player          = deepcopy(s:Player)
  let l:player.position = copy(a:position)
  return l:player
endfunction
" }}}

function! s:Player.set_parent(parent) abort
  let self.parent = a:parent
endfunction

function! s:Player.set_parent_position(parent_position) abort " {{{
  let self.parent_position = copy(a:parent_position)
endfunction
" }}}

function! s:Player.key_event(key) abort " {{{
  if a:key ==# 't'
    call self.toggle_mode()
    return
  endif

  if self.mode
    " PROCESS GENERATE BLOCK MODE
    call self.process_genblock_mode(a:key)
  else
    " PROCESS PLAYER MOVE MODE
    call self.process_move_mode(a:key)
  endif
endfunction
" }}}

function! s:Player.fall_if_possible() abort " {{{
  call cursor(self.position[0] + self.parent_position[0] - 1,
    \         self.position[1] + self.parent_position[1] - 1)
  while !s:is_block(s:getchar_on('j'))
    call self.fall()
  endwhile
endfunction
" }}}

function! s:Player.process_genblock_mode(key) abort " {{{
  if self.genblock.is_shrink_dir(a:key)
    call self.shrink_block()
  else
    if self.genblock.length < s:stage.get_gen_length_max() 
      call self.extend_block(a:key)
    endif
  endif
endfunction
" }}}

function! s:Player.can_hook() abort " {{{
  let l:line = getline('.')
  if self.prev_dir ==# 'l'
    return match(line[col('.')-1:], 'A\s*O') != -1
  else
    return match(line[:col('.')-1], 'O\s*A') != -1
  endif
endfunction
" }}}

function! s:Player.process_move_mode(key) abort " {{{
  call cursor(self.position[0] + self.parent_position[0] - 1,
    \         self.position[1] + self.parent_position[1] - 1)
  if a:key ==# 'f'
    if self.can_hook()
      call self.hook_shot()
    endif
  elseif a:key ==# ' '
    if self.is_movable('k')
      call self.jump_up()
      call self.move_if_possible(self.prev_dir)
    endif
  elseif a:key =~# '[hl]'
    let self.prev_dir = a:key
    call self.move_if_possible(a:key)
  endif
endfunction
" }}}

function! s:Player.ready_to_generate() abort " {{{
  if empty(self.parent)
    call s:game_erase_genblock()
  else
    if has_key(self.parent, 'genblock')
      call self.parent.genblock.remove_self()
    endif
  endif
  call self.fall_if_possible()
  call cursor(self.position[0] + self.parent_position[0] - 1,
    \         self.position[1] + self.parent_position[1] - 1)

  let self.genblock = s:GenBlock.new(getpos('.')[1:2])
endfunction
" }}}

function! s:Player.toggle_mode() abort " {{{
  if self.mode == 0
    " TOGGLE TO GENERATE BLOCK MODE
    call self.ready_to_generate()
    let self.mode = 1
    call self.genblock.highlighter.set()
  else
    " TOGGLE TO PLAYER MOVE MODE
    call self.genblock.set_cursor_to_head()
    call self.genblock.highlighter.reset()

    if empty(self.parent)
      " transfer genblock to game
      call s:transfer_to_game(self.genblock)
    else
      " transfer genblock to parent object
      let self.parent.genblock = self.genblock
    endif
    let self.genblock = {}

    let self.mode = 0
  endif
endfunction
" }}}

function! s:Player.move_if_possible(key) abort " {{{
  if self.is_movable(a:key)
    call self.move(a:key)
  endif
endfunction
" }}}

function! s:Player.is_movable(key) abort " {{{
  let l:ch = s:getchar_on(a:key)
  return !s:is_block(l:ch)
endfunction
" }}}

function! s:Player.move(dir) abort " {{{
  " Player moves to a specifiing direction.

  if a:dir ==# 'h'
    execute 'normal! r hr' . s:PLAYER_CH
    let self.position[1] -= 1
    let self.prev_dir = a:dir
  elseif a:dir ==# 'l'
    execute 'normal! r lr' . s:PLAYER_CH
    let self.position[1] += 1
    let self.prev_dir = a:dir
  endif
endfunction
" }}}

function! s:Player.jump_up() abort " {{{
  " Player jumps up.
  execute 'normal! r kr' . s:PLAYER_CH
  let self.position[0] -= 1
endfunction
" }}}

function! s:Player.fall() abort " {{{
  execute 'normal! r jr' . s:PLAYER_CH
  let self.position[0] += 1
  if !empty(self.genblock) && self.genblock.length
    call self.genblock.set_position(self.position)
  endif
endfunction
" }}}

function! s:Player.hook_shot() abort " {{{
  " Player hookshots before 'O'
  if self.prev_dir ==# 'l'
    execute 'normal! r '
    execute 'normal! tOr' . s:PLAYER_CH
  else
    execute 'normal! r '
    execute 'normal! TOr' . s:PLAYER_CH
  endif
  let self.position[1] = col('.')
endfunction
" }}}

"function! s:Player.init_block() abort " {{{
"  let self.genblock = s:GenBlock.new(self.position)
"endfunction
" }}}

function! s:Player.extend_block(dir) abort " {{{
  if self.genblock.length == 0 && a:dir =~# '[hl]'
    let self.prev_dir = a:dir
  endif
  call self.genblock.extend(a:dir)
endfunction
" }}}

function! s:Player.shrink_block() abort " {{{
  call self.genblock.shrink()
endfunction
" }}}

" }}}


" class HelpWindow {{{

let s:HelpWindow = { 'name' : '', 'window' : [], 'pos' : [0, 0], 'start' : [0, 0], 'script' : '', 'turn' : 0, 'player' : {} }
function! s:HelpWindow.new(name, window, start, script) abort
  let l:ret = deepcopy(s:HelpWindow)
  let l:ret.name   = a:name
  let l:ret.window = a:window
  let l:ret.start  = a:start
  let l:ret.script = a:script

  " player position is a relative position from upper-left of window
  let l:ret.player = s:Player.new(copy(a:start))

  return l:ret
endfunction

function! s:HelpWindow.set_pos(row, col) abort
  let self.pos = [a:row, a:col]
  call self.player.set_parent_position([a:row, a:col])
  call self.player.set_parent(self)
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


function! s:game_has_genblock() abort " {{{
  return !empty(s:genblock_in_stage)
endfunction
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
  call s:cb_close_help_window(a:help_window, a:help_window.pos)
  call s:cb_open_help_window(a:help_window, a:help_window.pos)
  let a:help_window.player.position = copy(a:help_window.start)
endfunction
" }}}

function! s:cb_player_in_window_moves(help_window, player, key) abort " {{{
  call a:player.process_move_mode(a:key)
endfunction
" }}}

function! s:cb_player_generate_block(help_window, player, key) abort " {{{
  echo a:player.genblock.position
  echo a:player.genblock.parent_position
  call a:player.process_genblock_mode(a:key)
endfunction
" }}}

function! s:cb_player_toggle_mode(help_window, player) abort " {{{
  call a:player.toggle_mode()
endfunction
" }}}

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
  call l:sequence.add(s:Wait.new(2000))
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
      call l:sequence.add(s:Wait.new(1000))
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
        call l:sequence.add(s:Wait.new(1000))
      else
        call l:sequence.add(
          \ s:Action.new('s:cb_set_hl_specifing_string', [l:hl_name]))
        call l:sequence.add(
          \ s:Action.new('s:cb_player_generate_block',
          \ [a:help_window, a:help_window.player, l:ch]))
        call l:sequence.add(s:Wait.new(500))
        call l:sequence.add(
          \ s:Action.new('s:cb_reset_hl_specifing_string', [l:hl_name]))
        call l:sequence.add(s:Wait.new(2000))
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
    let s:player = s:Player.new(copy(l:pos[1:2]))

    let s:genblock_in_stage = {}
  else
    call s:EventDispatcher.clear()
    call s:Drawer.draw_appriciate()
    call getchar()
    return 1
    finish
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
    call a:help_window.set_pos(a:upper_left[0], a:upper_left[1])

    " Register a window actions to SequenceManager
    let l:sequence = s:create_sequence_with_script(a:help_window)
    call s:SequenceManager.register(l:sequence)

    let a:help_window.player.y = a:help_window.start[0]
    let a:help_window.player.x = a:help_window.start[1]
    let a:help_window.player.mode = 0
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

" }}}

function! s:transfer_to_game(genblock) abort " {{{
  let s:genblock_in_stage = a:genblock
  let s:genblock_in_stage.position = copy(a:genblock.parent_position)
  let s:genblock_in_stage.parent_position = [ 1, 1 ]
endfunction
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

function! s:genblock_fall_in_stage() abort " {{{
  if s:game_has_genblock()
    call s:genblock_in_stage.fall_if_possible()
  endif
endfunction
" }}}

function! s:ready_to_start() abort " {{{
  %delete
  call s:setup_view(s:stage)
  call s:setup_events()
  call s:move_cursor_to_start()
  call s:set_player_to_cursor()

  let s:genblock_in_stage = {}

  let l:pos = getpos('.')
  let s:player = s:Player.new(copy(l:pos[1:2]))
endfunction
" }}}

function! s:game_erase_genblock() abort " {{{
  if s:game_has_genblock()
    call s:genblock_in_stage.remove_self()
    let s:genblock_in_stage = {}
  endif
endfunction
" }}}

function! s:setup_view(stage) abort " {{{
  " This function set up a view which game player watches.
  call s:Drawer.draw_stage(s:stage)
  call s:Drawer.draw_information()
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

function! s:update() abort " {{{
  " This function is kernel of this game.

  " process Player event
  let l:ch = getchar(0)
  if l:ch != 0
    if nr2char(l:ch) ==# 'Q'
      return 0
    elseif nr2char(l:ch) ==# 'r'
      call s:ready_to_start()
      return 1
    elseif nr2char(l:ch) ==# 'x'
      call s:game_erase_genblock()
      let s:player.genblock = s:GenBlock.new(copy(s:player.position))
      return 1
    endif
    call s:player.key_event(nr2char(l:ch))
  endif

  " Gravity
  call s:player.fall_if_possible()
  call s:genblock_fall_in_stage()

  call s:SequenceManager.run()
  if s:EventDispatcher.check() == 1
    return 0
  endif

  return 1
endfunction
" }}}

function! s:boxboy_main() abort " {{{
  call s:open_gametab()

  " syntax {{{
  syntax match boxboy_dir        /[<^v>]/    contained
  syntax match boxboy_block      /=/         contained
  syntax match boxboy_genblock   /#/         contained
  syntax match boxboy_player     /A/         contained
  syntax match boxboy_jump_key   /\[space\]/ contained
  syntax match boxboy_right_key  /l/         contained
  syntax match boxboy_left_key   /h/         contained
  syntax match boxboy_toggle_key /t/         contained

  syntax region boxboy_stage start=/\%^/ end=/^$/
    \ contains=boxboy_dir,boxboy_block,boxboy_genblock,boxboy_space_key,boxboy_player,boxboy_right_key,boxboy_jump_key,boxboy_left_key,boxboy_toggle_key

  highlight boxboy_dir_hi        guibg=blue ctermbg=blue
  highlight boxboy_block_hi      guifg=gray guibg=lightgray ctermfg=gray ctermbg=lightgray
  highlight boxboy_genblock_hi   guifg=gray guibg=darkgray ctermfg=gray ctermbg=darkgray
  highlight boxboy_jump_key_hi   ctermfg=NONE
  highlight boxboy_right_key_hi  ctermfg=NONE
  highlight boxboy_left_key_hi   ctermfg=NONE
  highlight boxboy_toggle_key_hi ctermfg=NONE
  highlight boxboy_player_hi     ctermfg=NONE

  highlight default link boxboy_dir        boxboy_dir_hi
  highlight default link boxboy_block      boxboy_block_hi
  highlight default link boxboy_genblock   boxboy_genblock_hi
  highlight default link boxboy_space_key  boxboy_space_key_hi
  highlight default link boxboy_right_key  boxboy_right_key_hi
  highlight default link boxboy_left_key   boxboy_left_key_hi
  highlight default link boxboy_jump_key   boxboy_jump_key_hi
  highlight default link boxboy_toggle_key boxboy_toggle_key_hi
  highlight default link boxboy_player     boxboy_player_hi
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
  let s:player = s:Player.new(copy(l:pos[1:2]))

  let l:min_fps = 10000000000000000
  let l:sum_fps = 0
  let l:ave_fps = 0
  let l:count   = 1
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
    let l:sum_fps += l:fps
    let l:ave_fps = l:sum_fps / l:count
    let l:count += 1
    if l:fps < l:min_fps
      let l:min_fps = l:fps
    endif
    " call setline(s:stage_bottom_line+1, string(l:fps))
    " call setline(s:stage_bottom_line+2, string(l:ave_fps))
    " call setline(line('$'), string(l:min_fps))
  endwhile
  call s:close_gametab()
endfunction
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
