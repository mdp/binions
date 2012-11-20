{EventEmitter} = require 'events'
{Deck} = require 'hoyle'
{Hand} = require 'hoyle'
{Player} = require './player'
utils = require 'util'

Game = class exports.Game extends EventEmitter
  @STATUS =
    NORMAL: 0
    PRIVILEGED: 1

  constructor: (players, betting, hand) ->
    @hand = hand || 1
    @Betting = betting
    @players = players.filter (p) -> p.chips > 0
    if @players.length < 2
      throw "Not enough players"
    if @players.length > 22
      throw "You can't have more that 22 players. I don't have that many cards"
    for player,i in @players
      player.position = i
    @state = null
    @reset()

  reset: ->
    for player in @players
      player.reset()
    @deck = new Deck()
    @community = []
    @burn = []
    @winners = []

  run: ->
    @emit('roundStart')
    @deck.shuffle()
    @deck.once 'shuffled', =>
      @deal()
      @takeBets()
    @on 'roundComplete', =>
      if @deal()
        @takeBets()
      else
        @settle()

  # Take bets in order and call roundComplete when finished
  takeBets: (betting, cb) ->
    betting ||= new @Betting(@players, @state)
    betOptions = betting.analyze()
    if betOptions
      status = @status(Game.STATUS.NORMAL, betting.nextToAct, betOptions)
      betting.nextToAct.update status, (err, res) =>
        if err
          @emit("bettingError", err, betting.nextToAct)
        betting.bet(res || 0, null, err)
        @takeBets(betting)
    else
      @emit("roundComplete", @state)
      cb?()

  # Let the bet handler take the appropriate blinds/ante's
  takeBlinds: ->
    new @Betting(@players, @state).takeBlinds()

  deal: ->
    return false if @activePlayers().length <= 1 && @state != null
    retval = true
    switch @state
      when null then @preFlop()
      when 'pre-flop' then @flop()
      when 'flop' then @turn()
      when 'turn' then @river()
      when 'river', 'final'
        @state = 'final'
        retval = false
     
    @emit('stateChange', @state)
    return retval

  preFlop: ->
    # Dealer acts before the flop
    @takeBlinds()
    @state = 'pre-flop'
    for player in @players
      player.cards.push(@deck.deal())
    for player in @players
      player.cards.push(@deck.deal())

  flop: ->
    @state = 'flop'
    @burn.push @deck.deal()
    @community.push(@deck.deal(), @deck.deal(), @deck.deal())
    true

  turn: ->
    @state = 'turn'
    @burn.push @deck.deal()
    @community.push(@deck.deal())

  river: ->
    @state = 'river'
    @burn.push @deck.deal()
    @community.push(@deck.deal())

  status: (level, player, betOptions) ->
    s = {}
    s.community = @community.map (c) -> c.toString()
    s.state = @state
    s.hand = @hand
    s.betting = betOptions || null
    if @winners && @winners.length > 0
      s.winners = @winners
    if level == Game.STATUS.PRIVILEGED
      s.deck = @deck
      s.burn = @burn
    if player
      s.self = player.status(Player.STATUS.PRIVILEGED)
      s.self.position = @players.indexOf(player)
    s.players = []
    for player in @players
      playerLevel = if (@state == 'complete') then Player.STATUS.FINAL else Player.STATUS.PUBLIC
      if level == Game.STATUS.PRIVILEGED
          playerLevel = Player.STATUS.PRIVILEGED
      s.players.push player.status(playerLevel)
    s

  distributeWinnings: (winners) ->
    if winners.length > 1
      @splitPot(winners)
    else
      @payout winners[0], @take(winners[0].wagered)

  splitPot: (winners) ->
    lowest = Math.min.apply(Math, winners.map (w) -> w.wagered)
    total = @take(lowest)
    each = Math.floor(total/winners.length)
    leftover = total - each*winners.length
    for winner,i in winners
      if i == 0
        @payout(winner, each + leftover)
      else
        @payout(winner, each)

  # What we want to take from each of the players
  take: (amount) ->
    total = 0
    for player in @players
      if amount > player.wagered
        total = total + player.wagered
        player.payout = player.payout - player.wagered
        player.wagered = 0
      else
        total = total + amount
        player.payout = player.payout - amount
        player.wagered = player.wagered - amount
    total

  payout: (winner, amount) ->
    @winners.push({position: winner.position, amount: amount})
    winner.payout = winner.payout + amount
    winner.chips = amount + winner.chips

  pot: ->
    t = 0
    for player in @players
      t = t + player.wagered
    t

  activePlayers: ->
    calls = @players.filter (p) ->
      p.inPlay()
    calls

  notifyPlayers: (callback, index) ->
    index ||= 0
    player = @players[index]
    if player
      player.update @status(Game.STATUS.FINAL, player), =>
        @notifyPlayers(callback, index + 1)
    else
      callback()

  settle: ->
    @state = 'complete'
    inPlay = @activePlayers()
    while inPlay.length >= 1
      if inPlay.length == 1
        # Last one in the game
        @distributeWinnings(inPlay)
        break
      else
        hands = inPlay.map (p) =>
          p.makeHand(@community)
        winningHands = Hand.pickWinners(hands)
        winners = inPlay.filter (p) ->
          winningHands.indexOf(p.hand) >= 0
        @distributeWinnings winners
        inPlay = @activePlayers()

    @notifyPlayers =>
      @emit 'complete'

