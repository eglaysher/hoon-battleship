/-  battleship
::
|%
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
++  guess
  |=  =coord
  ^-  (quip move session)
  ::
  ?:  =(%theirs turn.session)
    ~&  %waiting-for-their-move
    [~ session]
  ::
  :_  session
  :*  bone.session
      %poke
      /game/turn
      ship.session
      [%battleship-message [%guess coord]]
  ==
--
::
::
::  ~palfun integration stuff
|_  [=bowl:gall app-state]
++  poke

--
