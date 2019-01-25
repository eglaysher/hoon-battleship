/-  sole
/+  sole-lib=sole
=,  sole
::
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
+$  tile-precomit
  $:  ::  salt: a random number to make +tile-hash unguessable
      ::
      salt=@uvJ
      ::  value: the actual tile value
      ::
      value=plaintext-tile
  ==
::  +tile-hash: the hashed, salted, precommit state.
::
::    This is the 
::
+$  tile-hash
  @uvJ
::
+$  board-state
  (list [tile-hash (unit tile-precommit)])
::
+$  message
  $:  [%init (map coord tile-hash)]
      [%guess coord]
      [%reveal coord tile-precommit]
  ==
::
+$  session-state
  $:  ::
      ::
      local=board-state
      ::
      ::
      remote=board-state
      ::
      ::
      turn=?(%ours %theirs)
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
|%
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
