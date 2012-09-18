NoLimit = module.exports = (small, big) ->
  console.log "Creating game #{small}/#{big}"
  smallBlind = Math.floor(small/2)
  bigBlind = small

  return class Analysis
    constructor: (players, state) ->
      @state = state
      @players = players
      @nextToAct = null
      @canRaise = true
      @offset = 0
      @minToCall = 0
      @minToRaise = 0
      if @state == 'preFlop'
        @offset = 2
      else if players.length == 2 && @state == 'preFlop'
        @offset = 1

      if @state == 'turn' || @state == 'river'
        @roundMinimum = big
      else
        @roundMinimum = small
      @analyze()

    gameActive: ->
      actives = @players.filter (pos) ->
        pos.active()
      actives.length > 1

    actions: ->
      _actions = []
      maxActions = Math.max.apply Math, (@players.map (p) -> p.actions.length)
      for pos, i in @players
        for act, j in pos.actions(@state)
          _actions[i*maxActions + j] = act
          _actions[i*maxActions + j]['position'] = i
      _actions.filter -> return true

    currentWager: ->
      return _maxWagered if _maxWagered?
      wagers = @players.map (pos) ->
        pos.wagered || 0
      _maxWagered = Math.max.apply(Math, wagers)

    blinds: ->
      if @players.length > 2
        [smallBlind, bigBlind]
      # Heads up
      else
        [bigBlind, smallBlind]

    analyze: ->
      @nextToAct = null
      @minToRaise = minRaise = @roundMinimum
      @minToCall = @currentWager()
      @actionCount = Math.max.apply Math, (@players.map (p) -> p.actions.length)
      previousBet = 0
      lastPosition = null
      for act in @actions()
        currentBet = act['bet'] || 0
        raise = currentBet - previousBet
        #console.log "Raise #{raise} on bet of #{currentBet}, and previous bet of #{previousBet}"
        #console.log "MinimumRaise: #{minRaise}"
        if currentBet > @minToCall
          @minToCall = currentBet
        if raise >= minRaise # Legal raise
          #console.log "Legal Raise"
          minRaise = raise
          @lastRaisePosition = act['position']
        previousBet = currentBet
        lastPosition = act['position']
      @minToRaise = minRaise + @minToCall
      @setNextToAct(lastPosition)

    setNextToAct: (lastPos) ->
      if lastPos == null
        @nextToAct = @players[@offset]
      else
        nextPos = (lastPos + 1) % @players.length
        for player in @players
          if player.position >= nextPos && player.canBet()
            if player.wagered < @minToCall
              @nextToAct = player
              break
            if player.actions(@state).length == 0
              @nextToAct = player
              break
      if @lastRaisePosition && @players[@lastRaisePosition] == @nextToAct
        @canRaise = false

    # Enforce betting rules here
    # eg. I bet 7, call is 5, and raise is 10
    # Results in a call at 5
    bet: (pos, amount) ->
      if arguments.length == 2
        player = @players[pos]
      else
        player = @nextToAct
        amount = pos
      total = player.wagered + amount
      #console.log "Amount: #{amount} added to #{player.wagered} - minToCall #{@minToCall}"
      if player.chips == amount
        player.act(@state, 'allIn', amount)
      else if @minToCall - player.wagered == 0 && total < @minToRaise
        player.act(@state, 'check')
      else if total < @minToCall # Can be -1 to force a fold on check
        player.act(@state, 'fold')
      else if total >= @minToRaise
        player.act(@state, 'raise', amount)
      else if total >= @minToCall
        player.act(@state, 'call', @minToCall - player.wagered) # Prevent incomplete raise unless all-in
      @analyze()

    takeBets: (gameStatus, cb) ->
      cb?() unless @nextToAct
      @nextToAct.takeBet @status(), gameStatus, (err, bet) =>
        if err
          @bet(0) # Check/fold on error
        else
          @bet(bet)
        if @nextToAct
          @takeBets(gameStatus, cb)
        else
          cb?()

    status: ->
      minToCall: @minToCall
      minToRaise: @minToRaise
      canRaise: @canRaise
      wagered: @nextToAct.wagered
      cards: @nextToAct.cards

