/-  *battleship, *sole
/+  sole-lib=sole
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
+$  move  (pair bone card)
::
+$  card
  $%  [%diff diff-card]
  ==
::
+$  diff-card
  $%  [%sole-effect sole-effect]
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
  :_  session(local `board-state)
  ~


::  +send-guess: sends a guess to our counterparty
::
++  send-guess
  |=  =coord
  ^-  (quip move session)
  ::
  ?:  =(%theirs turn.session)
    ~&  %waiting-for-their-move
    [~ session]
  ::
  :_  session(turn %theirs)
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
  ?:  =(%ours turn.session)
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
    =-  +>(moves [- moves])
    :*  ost.bowl
        %poke
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
      %clr  ..sh-sole :: (sh-pact ~) :: XX clear to PM-to-self?
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
    =^  inv  say.she  (~(transceive sole-lib say.she) cal)
    =+  fix=(sh-sane inv buf.say.she)
    ?~  lit.fix
      +>.$
    :: just capital correction
    ?~  err.fix
      (sh-slug fix)
    :: allow interior edits and deletes
    ?.  &(?=($del -.inv) =(+(p.inv) (lent buf.say.she)))
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
      %+  knee  *cli-action  |.  ~+
      ;~  pose
      ::
        (stag %select ;~(pfix sig fed:ag))
      ::
        (stag %guess coord)
      ::
        ;~(plug (jest 'show') (easy ~))
      ::
        ;~(plug (jest 'help') (easy ~))
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
    =+  fix=(sh-sane [%nop ~] buf.say.she)
    ?^  lit.fix
      (sh-slug fix)
    =+  jub=(rust (tufa buf.say.she) sh-read)
    ?~  jub  (sh-fact %bel ~)
    %.  u.jub
    =<  sh-action
    =+  buf=buf.say.she
    =?  ..sh-obey  &(?=({$';' *} buf) !?=($reply -.u.jub))
      (sh-note (tufa `(list @)`buf))
    =^  cal  say.she  (~(transmit sole-lib say.she) [%set ~])
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
      ?-  -.job
        %select  (select +.job)
        %init    (init +.job)
        %guess   (guess +.job)
        %show    show
        %help    help
      ==
    ::
    ++  select
      |=  who=ship
      sh-prompt(opponent who)
    ::
    ++  init  !!
    ::
    ++  guess
      |=  =coord
      (sh-message %guess coord)
    ::
    ++  show
      =+  game=(~(got by games) opponent)
      =+  us=?=(%ours turn.game)
      =>  (sh-line "us vs {(scow %p opponent)}")
      =>  (sh-line "xx turn indicator xx") ::"waiting on {?:(us "us" "them")}")
      =>  sh-separator
      =>  (sh-board local.game)
      (sh-board remote.game)
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
  --
--
