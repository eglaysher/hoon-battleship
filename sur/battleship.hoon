|%
::  +plaintext-tile: a definition of all the tile states possible
::
+$  plaintext-tile
  $%  ::  5-tile carrier
      ::
      %carrier-1
      %carrier-2
      %carrier-3
      %carrier-4
      %carrier-5
      ::  4-tile battleship
      ::
      %battleship-1
      %battleship-2
      %battleship-3
      %battleship-4
      ::  3-tile cruiser
      ::
      %cruiser-1
      %cruiser-2
      %cruiser-3
      ::  3-tile submarine
      ::
      %submarine-1
      %submarine-2
      %submarine-3
      ::  2-tile destroyer
      ::
      %destroyer-1
      %destroyer-2
      ::  you missed
      ::
      %empty-tile
  ==
::  +tile-precomit: the real board state with salts
::
+$  tile-precommit
  $:  ::  salt: a random number to make +tile-hash unguessable
      ::
      salt=@uvH
      ::  value: the actual tile value
      ::
      value=plaintext-tile
  ==
::  +tile-hash: the hashed, salted, precommit state.
::
+$  tile-hash
  @uvH
::
+$  board-tile
  [=tile-hash precomit=(unit tile-precommit)
::
+$  board-state
  (map coord board-tile)
::
+$  message
  $:  [%invite ~]
      [%init (map coord tile-hash)]
      [%guess coord]
      [%reveal coord tile-precommit]
  ==
::
+$  session-state
  $:  ::
      ::
      local=(unit board-state)
      ::
      ::
      remote=(unit board-state)
      ::
      ::
      turn=?(%ours %theirs)
      ::
      ::
      =ship
      ::
      ::
      =bone
  ==
::
+$  coord
  [x=@ud y=@ud]
--
