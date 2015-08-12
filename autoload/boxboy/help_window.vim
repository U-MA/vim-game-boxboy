call boxboy#add_help_window('jump', {
  \ 'name'   : 'jump',
  \ 'window' : [
  \   '+-----------+',
  \   '|           |',
  \   '|     A     |',
  \   '|===========|',
  \   '|  [space]  |',
  \   '+-----------+',
  \ ],
  \ 'start'  : [2, 6],
  \ 'script' : '* * ',
  \})

call boxboy#add_help_window('move_right', {
  \ 'name'   : 'move_right',
  \ 'window' : [
  \   '+-----------+',
  \   '|           |',
  \   '|     A     |',
  \   '|===========|',
  \   '|     l     |',
  \   '+-----------+',
  \ ],
  \ 'start'  : [2, 6],
  \ 'script' : '*l*l',
  \})
