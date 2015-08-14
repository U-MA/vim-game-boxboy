call boxboy#add_help_window('jump', {
  \ 'name'   : 'jump_key',
  \ 'window' : [
  \   '+-----------+',
  \   '|           |',
  \   '|   A =     |',
  \   '|===========|',
  \   '|  [space]  |',
  \   '+-----------+',
  \ ],
  \ 'start'  : [3, 5],
  \ 'script' : 'l ',
  \})

call boxboy#add_help_window('move_right', {
  \ 'name'   : 'right_key',
  \ 'window' : [
  \   '+-----------+',
  \   '|           |',
  \   '|    A      |',
  \   '|===========|',
  \   '|     l     |',
  \   '+-----------+',
  \ ],
  \ 'start'  : [3, 6],
  \ 'script' : 'll',
  \})

call boxboy#add_help_window('move_left', {
  \ 'name'   : 'left_key',
  \ 'window' : [
  \   '+-----------+',
  \   '|           |',
  \   '|      A    |',
  \   '|===========|',
  \   '|     h     |',
  \   '+-----------+',
  \ ],
  \ 'start'  : [3, 8],
  \ 'script' : 'hh',
  \})

call boxboy#add_help_window('move_horizontally', {
  \ 'name'   : 'right_and_left',
  \ 'window' : [
  \   '+-----------+',
  \   '|           |',
  \   '|   A       |',
  \   '|===========|',
  \   '|   h   l   |',
  \   '+-----------+',
  \ ],
  \ 'start'  : [3, 5],
  \ 'script' : 'llllhhhh',
  \})

