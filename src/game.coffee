{EventEmitter} = require 'events'
{Deck} = require 'hoyle'
{Hand} = require 'hoyle'

class exports.Game extends EventEmitter
  constructor: (players, betting) ->
    @deck = new Deck()
    @Betting = betting
    @community = []
    @burn = []
    @winners = []
    @players = players
    for player,i in @players
      player.position = i
      player.on "bet", (bet) =>
        @emit "bet", bet
    @state = null

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
    blinds = new @Betting(@players, @state).blinds()
    @players[0].bet(blinds[0])
    @players[1].bet(blinds[1])

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
    s.community = []
    for card in @community
      s.community.push card.toString()
    s.state = @state
    s.players = []
    for player in @players
      s.players.push player.status(final)
    s

  distributeWinnings: (winners) ->
    if winners.length > 1
      @splitPot(winners)
    else
      @payout winners[0]

  splitPot: (winners) ->
    lowest = Math.min.apply(Math, winners.map (w) -> w.wagered)
    total = 0
    for player in @players
      if lowest > player.wagered
        total = total + player.wagered
        player.wagered = 0
      else
        total = total + lowest
        player.wagered = player.wagered - lowest
    each = Math.floor(total/winners.length)
    leftover = total - each*winners.length
    for winner in winners
      winner.chips = winner.chips + each
    winners[0].chips = winner.chips + leftover

  payout: (winner) ->
    amount = winner.wagered
    for player in @players
      if player.wagered < amount
        total = player.wagered
      else
        total = amount
      winner.chips = total + winner.chips
      player.wagered = player.wagered - total

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
        @distributeWinnings(inPlay[0])
      else
        hands = inPlay.map (p) =>
          p.makeHand(@community)
        winningHands = Hand.pickWinners(hands)
        winners = inPlay.filter (p) ->
          winningHands.indexOf(p.hand) >= 0
        @distributeWinnings winners
        for winner in winners
          @winners.push winner
        inPlay = @activePlayers()
    @emit 'complete'

