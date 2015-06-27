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

function! s:init_mode() abort
  let s:mode = 0
endfunction

function! s:toggle_mode() abort
  if s:mode
    echo 'PLAYER MOVE MODE'
    let s:mode = 0
  else
    echo 'BLOCK GENERATE MODE'
    let s:mode = 1
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
  let s:blocks = [ '=', '#' ]
" }}}

"}}}

" util functions {{{

function! s:move_cursor_to_start() abort
  execute 'normal gg0'
  call search('S', 'W')
endfunction

function! s:search_goal() abort
  execute 'normal gg0'
  return search('G', 'W')
endfunction

function! s:is_clear() abort
  let p = getpos('.')
  if s:search_goal()
    call setpos('.', p)
    return 0
  else
    call setpos('.', p)
    echo 'Clear'
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

function! s:generate_block(dir) abort
  if a:dir ==# 'h'
    if s:is_movable(a:dir)
      execute 'normal! hr' . s:block_ch
      execute 'normal! l'
    endif
  elseif a:dir ==# 'j'
  elseif a:dir ==# 'k'
    if s:is_movable(a:dir)
      execute 'normal! kr' . s:block_ch
      execute 'normal! j'
    endif
  elseif a:dir ==# 'l'
    if s:is_movable(a:dir)
      execute 'normal! lr' . s:block_ch
      execute 'normal! h'
    endif
  endif
endfunction

" }}}

" key event {{{

function! s:right() abort
  if s:is_movable('l')
    execute 'normal! r lr' . s:player_ch
  endif
endfunction

function! s:left() abort
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
  call s:right()
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
    endif
  endif
endfunction
"}}}

" main {{{

function! s:restart() abort
  %delete " buffer clear
  for l:i in readfile('./autoload/stages/stage0.txt')
    call setline(line('$')+1, l:i)
  endfor
  call s:move_cursor_to_start()
  call s:set_player_to_cursor()
  call s:init_mode()
endfunction

function! s:main() abort
  tabnew boxboy
  %delete " buffer clear
  for l:i in readfile('./autoload/stages/stage0.txt')
    call setline(line('$')+1, l:i)
  endfor
  call s:move_cursor_to_start()
  call s:set_player_to_cursor()
  call s:init_mode()

  nnoremap <silent><buffer><nowait> h       :call <SID>key_events('h')<CR>
  nnoremap <silent><buffer><nowait> j       :call <SID>key_events('j')<CR>
  nnoremap <silent><buffer><nowait> k       :call <SID>key_events('k')<CR>
  nnoremap <silent><buffer><nowait> l       :call <SID>key_events('l')<CR>
  nnoremap <silent><buffer><nowait> <space> :call <SID>key_events(' ')<CR>
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

command! BoxBoy call s:main()

" vim: foldmethod=marker
