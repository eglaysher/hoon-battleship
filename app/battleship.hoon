/-  *battleship
::
|%
+$  move  (pair bone card)
::
+$  card
  $%  [%poke wire dock poke-type]
  ==
::
+$  poke-type
  $%  [%battleship-message message]
  ==
::
+$  app-state
  $:  ::  games: only one game with a person at a time
      ::
      games=(map ship session-state)
  ==
::
--
::
::
::  ~ponnys engine stuff
|_  session=session-state
::  +encrypt-initial-state
::
++  encrypt-initial-state
  |=  $:  unencrypted-board=(map coord plaintext-tile)
          eny=@
      ==
  ^-  board-state
  ::
  %+  ~(rut in unencrypted-board)
  |=  [=coord =plaintext-tile]
  ^-  board-tile
  ::
  =/  salt  (sham [coord eny])
  =/  =tile-precommit  [salt plaintext-tile]
  ::
  [(sham tile-precommit) `tile-precommit]
::  +set-and-send-initial-state: records and sends our starting state
::
::    Both our ship and our opponent have a session now, but neither
::    has our board state filled in.
::
++  set-and-send-initial-state
  |=  =board-state
  ^-  (quip move session)
  ::
  =/  tile-hashes
    %-  ~(run by board-state)
    |=  =board-tile
    tile-hash.board-tile
  ::
  :_  session(local `board-state)
  :_  ~
  :*  bone.session
      %poke
      /game/init
      ship.session
      [%battleship-message [%init tile-hashes]]
  ==
::  +receive-init: receives an init message
::
++  receive-init
  |=  encrypted-remote=(map coord tile-hash)
  ^-  session
  ::
  %_    session
      remote
    %-  ~(run by encrypted-remote)
    |=  =tile-hash
    [tile=hash ~]
  ==
::  +send-guess: sends a guess to our counterparty
::
++  send-guess
  |=  =coord
  ^-  (quip move session)
  ::
  ?:  (is-turn %theirs)
    ~&  %waiting-for-their-move
    [~ session]
  ::
  :_  session(turn %theirs)
  :_  ~
  :*  bone.session
      %poke
      /game/guess
      ship.session
      [%battleship-message [%guess coord]]
  ==
::  +receive-guess-and-reply: receives a guess from above
::
++  receive-guess-and-reply
  |=  =coord
  ^-  (quip move session)
  ::
  ?:  (is-turn %ours)
    ~&  %received-guess-during-our-turn
    [~ session]
  ::
  ?~  at-coord=(~(get by (need local.state)) coord)
    ~&  %invalid-coordinate-from-foreign
    [~ session]
  ::
  :_  session(turn %ours)
  :*  bone.session
      %poke
      /game/reply
      ship.session
      %battleship-message
      [%reveal coord (need precomit.u.at-coord)]
  ==
::  +receive-reply: receives a reply
::
++  receive-reply
  |=  [=coord =tile-precommit]
  ^-  (quip move session)
  ::  make sure the precomit matches the hash we already have
  ::
  =/  =tile-hash  (sham tile-precommit)
  ?.  =(tile-hash tile-hash:(~(got by (need remote.session)) coord))
    ~&  [%precommitment-failure tile-hash]
    [~ state]
  ::  TODO: Some sort of better printout about what happened.
  ::
  ~&  [%outcome coord value.tile-precommit]
  :-  ~
  %_    session
      remote
    %-  ~(jab by (need remote.session))  coord
    |=  =board-tile
    board-tile(precomit `tile-precommit)
  ==
::
++  is-turn
  |=  wanted=?(%ours %theirs)
  ^-  ?
  ::
  ?~  local.session
    %.n
  ?~  remote.session
    %.n
  ::
  =(wanted turn.session)
--
::
::
::  ~palfun integration stuff
|_  [=bowl:gall app-state]
++  poke

--
