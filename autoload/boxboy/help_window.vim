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
  \ 'start'  : [3, 7],
  \ 'script' : '* * ',
  \})

call boxboy#add_help_window('move_right', {
  \ 'name'   : 'right_key',
  \ 'window' : [
  \   '+-----------+',
  \   '|           |',
  \   '|     A     |',
  \   '|===========|',
  \   '|     l     |',
  \   '+-----------+',
  \ ],
  \ 'start'  : [3, 7],
  \ 'script' : '*l*l',
  \})
