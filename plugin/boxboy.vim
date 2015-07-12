" A game like boxboy(hacoboy)
" Version: 0.80
" Author: U-MA
" Lisence: VIM LICENSE

if exists('g:loaded_boxboy')
  finish
endif
let g:loaded_boxboy = 1

let s:save_cpo = &cpo
set cpo&vim

command! BoxBoy call boxboy#main()

let &cpo = s:save_cpo
unlet s:save_cpo
