|%
::  +ship-type: a definition of all ship types
::
+$  ship-type
  $?  ::  5-tile carrier
      ::
      %carrier
      ::  4-tile battleship
      ::
      %battleship
      ::  3-tile cruiser
      ::
      %cruiser
      ::  3-tile submarine
      ::
      %submarine
      ::  2-tile destroyer
      ::
      %destroyer
  ==
::  +plaintext-tile: a definition of all the tile states possible
::
+$  plaintext-tile
  $?  ::  a ship exists here
      ::
      ship-type
      ::  you missed
      ::
      %empty-tile
  ==
::  +tile-precommit: the real board state with salts
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
  [=tile-hash precommit=(unit tile-precommit)]
::
+$  board-state
  (map coord board-tile)
::
+$  message
  $%  [%invite ~]
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
  ==
::
+$  coord
  [x=@ud y=@ud]
--
