NoLimit = module.exports = (small, big) ->
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
      if players.length == 2 && @state == 'pre-flop'
        @offset = 1
      else if @state == 'pre-flop'
        @offset = 2

      if @state == 'turn' || @state == 'river'
        @roundMinimum = big
      else
        @roundMinimum = small
      @analyze()

    gameActive: ->
      actives = @players.filter (pos) ->
        pos.active()
      actives.length > 1

    # Returns a list of actions taken in order
    actions: ->
      actions = []
      # Bucket the actions
      for i in [0..(@players.length-1)]
        i = (i + @offset) % @players.length
        player = @players[i]
        for act, j in player.actions(@state)
          actions[j] ||= []
          actions[j].push {bet: act.bet, type: act.type, position: i}
      # Flatten the results
      if actions.length > 0
        actions = actions.reduce (a,b) ->
          a.concat(b)
      actions

    currentWager: ->
      wagers = @players.map (pos) ->
        pos.wagered || 0
      Math.max.apply(Math, wagers)

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
      previousBet = 0
      lastPosition = null
      for act in @actions()
        currentBet = act['bet'] || 0
        raise = currentBet - previousBet
        if currentBet > @minToCall
          @minToCall = currentBet
        if raise >= minRaise # Legal raise
          minRaise = raise
          @lastRaisePosition = act['position']
        previousBet = currentBet
        lastPosition = act['position']
      @minToRaise = minRaise + @minToCall
      if @gameActive()
        @setNextToAct(lastPosition)
      if @nextToAct
        @options()
      else
        false

    setNextToAct: (lastPos) ->
      lastPos ?= @offset - 1
      nextPos = (lastPos + 1) % @players.length
      for i in [nextPos..nextPos + @players.length]
        player = @players[i % @players.length]
        if player.canBet()
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
    bet: (amount, position, err) ->
      if position == null
        player = @nextToAct
      else
        player = @players[position]
      amount = parseInt(amount, 10) || 0
      total = player.wagered + amount
      amount = Math.min(amount, player.chips)
      if player.chips == amount
        player.act(@state, 'allIn', amount)
      else if @minToCall - player.wagered == 0 && total < @minToRaise
        player.act(@state, 'check', 0, err)
      else if total < @minToCall # Can be -1 to force a fold on check
        player.act(@state, 'fold', 0, err)
      else if total >= @minToRaise
        player.act(@state, 'raise', amount)
      else if total >= @minToCall
        player.act(@state, 'call', @minToCall - player.wagered) # Prevent incomplete raise unless all-in
      @analyze()

    takeBlinds: ->
      for blind, i in @blinds()
        @players[i].takeBlind blind
      @analyze()

    options: ->
      o = {}
      o.call = @minToCall - @nextToAct.wagered
      o.raise = @minToRaise - @nextToAct.wagered
      o.canRaise = @canRaise
      o
