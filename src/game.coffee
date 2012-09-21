{EventEmitter} = require 'events'
{Deck} = require 'hoyle'
{Hand} = require 'hoyle'
utils = require 'util'

class exports.Game extends EventEmitter
  constructor: (players, betting) ->
    @Betting = betting
    @players = players.filter (p) -> p.chips > 0
    if @players.length < 2
      throw "Not enough players"
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
    @deck.shuffle()
    @deck.on 'shuffled', =>
      @deal()
      @takeBets()
    @on 'roundComplete', =>
      if @deal()
        @takeBets()
      else
        @settle()

  deal: ->
    return false if @activePlayers().length == 1
    switch @state
      when null then @preFlop()
      when 'pre-flop' then @flop()
      when 'flop' then @turn()
      when 'turn' then @river()
      when 'river' then false

  takeBets: (cb) ->
    @betting = new @Betting(@players, @state)
    status = @status()
    @betting.takeBets (status), =>
      @emit("roundComplete", @state)
      cb?()

  takeBlinds: ->
    new @Betting(@players, @state).takeBlinds()

  preFlop: ->
    # Dealer acts before the flop
    @state = 'pre-flop'
    @takeBlinds()
    @burn.push @deck.deal()
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

  status: (final)->
    s = {}
    s.community = @community.map (c) -> c.toString()
    s.state = @state
    if final
      s.winners = @winners
    s.players = []
    for player in @players
      s.players.push player.status(final)
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
        player.wagered = 0
      else
        total = total + amount
        player.wagered = player.wagered - amount
    total

  payout: (winner, amount) ->
    @winners.push({position: winner.position, amount: amount})
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

  settle: ->
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
    @emit 'complete', @status(true)

