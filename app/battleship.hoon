/-  *battleship, *sole
/+  sole-lib=sole
::
|%
+$  move  (pair bone card)
::
+$  card
  $%  [%poke wire dock poke-type]
      [%diff diff-type]
  ==
::
+$  poke-type
  $%  [%battleship-message message]
  ==
::
+$  diff-type
  $%  [%sole-effect sole-effect]
  ==
::
+$  cli-state
  $:  ::  cli connection identifier
      ::
      =bone
      ::  cli state
      ::
      state=sole-share
      ::  currently selected opponent
      ::
      opponent=ship
  ==
::
+$  cli-action
  $%  [%select who=ship]
      [%init (map coord plaintext-tile)]
      [%guess coord]
      [%show ~]
      [%help ~]
  ==
::
+$  app-state
  $:  ::  games: only one game with a person at a time
      ::
      games=(map ship session-state)
      ::  shell: current cli connection & state
      ::
      cli=cli-state
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
  %-  ~(rut by unencrypted-board)
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
  ^-  (quip move session-state)
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
      [ship.session %battleship]  ::TODO  dap.bowl ?
      [%battleship-message [%guess coord]]
  ==
::  +receive-guess-and-reply: receives a guess from above
::
++  receive-guess-and-reply
  |=  =coord
  ^-  (quip move session-state)
  ::
  ?:  (is-turn %ours)
    ~&  %received-guess-during-our-turn
    [~ session]
  ::
  ?~  at-coord=(~(get by (need local.session)) coord)
    ~&  %invalid-coordinate-from-foreign
    [~ session]
  ::
  :_  session(turn %ours)
  :_  ~
  :*  bone.session
      %poke
      /game/reply
      [ship.session %battleship]
      %battleship-message
      [%reveal coord (need precomit.u.at-coord)]
  ==
::  +receive-reply: receives a reply
::
++  receive-reply
  |=  [=coord =tile-precommit]
  ^-  (quip move session-state)
  ::  make sure the precomit matches the hash we already have
  ::
  =/  =tile-hash  (sham tile-precommit)
  ?.  =(tile-hash tile-hash:(~(got by (need remote.session)) coord))
    ~&  [%precommitment-failure tile-hash]
    [~ session]
  ::  TODO: Some sort of better printout about what happened.
  ::
  ~&  [%outcome coord value.tile-precommit]
  :-  ~
  %_    session
      remote
    %-  some
    %+  ~(jab by (need remote.session))  coord
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
::
++  prep
  |=  *
  ^-  (quip move _..prep)
  ~&  %prep
  [~ ..prep]
::
++  peer
  |=  =path
  ^-  (quip move _+>)
  ~&  %peer
  ?.  ?=([%sole *] path)
    ~!  %foreign-clients-unsupported
    !!
  =.  bone.cli  ost.bowl
  =.  state.cli  *sole-share
  sh-done:~(sh-prompt sh ~ cli)
::
++  poke-sole-action
  |=  action=sole-action
  ^-  (quip move _+>)
  sh-done:(~(sh-sole-action sh ~ cli) action)
::
++  sh
  |_  [moves=(list move) cli-state]
  ::
  ++  sh-done
    ^-  (quip move _..sh)
    :-  (flop moves)
    +>(cli [bone state opponent])  ::TODO  lark
  ::
  ::  #
  ::  #  %emitters
  ::  #
  ::    arms that create outward changes.
  ::
  ++  sh-fact
    ::  adds a console effect to ++ta's moves.
    ::
    |=  fec=sole-effect
    ^+  +>
    +>(moves [[bone %diff %sole-effect fec] moves])
  ::
  ++  sh-message
    ::  sends message to opponent
    ::
    |=  =message
    ^+  +>
    =-  +>.$(moves [- moves])
    ^-  move
    :*  ost.bowl
        %poke
        /tmp/wire  ::TODO  probably call into main engine instead
        [~zod dap.bowl]  ::TODO
        %battleship-message
        message
    ==
  ::
  ::  #
  ::  #  %cli-interaction
  ::  #
  ::    processing user input as it happens.
  ::
  ++  sh-sole-action
    ::  applies sole action
    ::
    |=  act=sole-action
    ^+  +>
    ?-  -.act
      %det  (sh-edit +.act)
      %clr  ..sh-sole-action :: (sh-pact ~) :: XX clear to PM-to-self?
      %ret  sh-obey
    ==
  ::
  ++  sh-edit
    ::    apply sole edit
    ::
    ::  called when typing into the cli prompt.
    ::  applies the change and does sanitizing.
    ::
    |=  cal/sole-change
    ^+  +>
    =^  inv  state  (~(transceive sole-lib state) cal)
    =+  fix=(sh-sane inv buf.state)
    ?~  lit.fix
      +>.$
    :: just capital correction
    ?~  err.fix
      (sh-slug fix)
    :: allow interior edits and deletes
    ?.  &(?=($del -.inv) =(+(p.inv) (lent buf.state)))
      +>.$
    (sh-slug fix)
  ::
  ++  sh-read
    ::    command parser
    ::
    ::  parses the command line buffer. produces work
    ::  items which can be executed by ++sh-action.
    ::
    =<  work
    ::  #  %parsers
    ::    various parsers for command line input.
    |%
    ++  coord
      ;~((glue com) dem dem)
    ::
    ++  direction
      ;~  pose
        (just 'n')
        (just 'e')
        (just 's')
        (just 'w')
      ==
    ::
    ++  work
      ;~  pose
      ::
        (stag %select ;~(pfix sig fed:ag))
      ::
        (stag %guess coord)
      ::
        ;~(plug (perk %show ~) (easy ~))
      ::
        ;~(plug (perk %help ~) (easy ~))
      ==
    --
  ::
  ++  sh-sane
    ::    sanitize input
    ::
    ::  parses cli prompt input using ++sh-read and
    ::  sanitizes when invalid.
    ::
    |=  [inv=sole-edit buf=(list @c)]
    ^-  [lit=(list sole-edit) err=(unit @u)]
    =+  res=(rose (tufa buf) sh-read)
    ?:  ?=(%| -.res)  [[inv]~ `p.res]
    :_  ~
    ?~  p.res  ~
    =+  wok=u.p.res
    ~
  ::
  ++  sh-slug
    ::  corrects invalid prompt input.
    ::
    |=  {lit/(list sole-edit) err/(unit @u)}
    ^+  +>
    ?~  lit  +>
    =^  lic  state
      %-  ~(transmit sole-lib state)
      ^-  sole-edit
      ?~(t.lit i.lit [%mor lit])
    (sh-fact [%mor [%det lic] ?~(err ~ [%err u.err]~)])
  ::
  ++  sh-obey
    ::    apply result
    ::
    ::  called upon hitting return in the prompt. if
    ::  input is invalid, ++sh-slug is called.
    ::  otherwise, the appropriate work is done and
    ::  the entered command (if any) gets displayed
    ::  to the user.
    ::
    =+  fix=(sh-sane [%nop ~] buf.state)
    ?^  lit.fix
      (sh-slug fix)
    =+  user-action=(rust (tufa buf.state) sh-read)
    ?~  user-action  (sh-fact %bel ~)
    ~!  u.user-action
    %.  u.user-action
    =<  sh-action
    =+  buf=buf.state
    :: =?  ..sh-obey  &(?=({$';' *} buf) !?=($reply -.u.user-action))
    ::   (sh-note (tufa `(list @)`buf))
    =^  cal  state  (~(transmit sole-lib state) [%set ~])
    %+  sh-fact  %mor
    :~  [%nex ~]
        [%det cal]
    ==
  ::
  ::  #
  ::  #  %user-action
  ::  #
  ::    processing user actions.
  ::
  ++  sh-action
    ::    do work
    ::
    ::  implements worker arms for different talk
    ::  commands.
    ::  worker arms must produce updated state.
    ::
    |=  action=cli-action
    ^+  +>
    =<  perform
    |%
    ++  perform
      ::  call correct worker
      ?-  -.action
        %select  (select +.action)
        %init    (init +.action)
        %guess   (guess +.action)
        %show    show
        %help    help
      ==
    ::
    ++  select
      |=  who=ship
      sh-prompt(opponent who)
    ::
    ++  init
      |=  setup=(map coord plaintext-tile)
      !!
    ::
    ++  guess
      |=  =coord
      (sh-message %guess coord)
    ::
    ++  show
      =>  (sh-line "us vs {(scow %p opponent)}")
      =>  (sh-line "xx turn indicator xx") ::"waiting on {?:(us "us" "them")}")
      =>  sh-separator
      =>  (sh-board (need local:(~(got by games) opponent)))
      (sh-board (need remote:(~(got by games) opponent)))
    ::
    ++  help  !!
    --
  ::
  ::  #
  ::  #  %printers
  ::  #
  ::    arms for printing data to the cli.
  ::
  ++  sh-line
    ::  just puts some text into the cli as-is.
    ::
    |=  txt=tape
    (sh-fact [%txt txt])
  ::
  ++  sh-prompt
    ::  show opponent in prompt
    ::
    ^+  .
    %+  sh-fact  %pro
    :+  &  dap.bowl
    ;:  weld
      "vs "
      (scow %p opponent)
      ": "
    ==
  ::
  ++  sh-separator  (sh-line (reap 80 '-'))
  ::
  ++  sh-board
    |=  board=board-state
    ^+  +>
    !!
  --
--
