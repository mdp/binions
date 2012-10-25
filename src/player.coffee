# This handles the position at the table
# and enforces good bot behaviour
#
# Things like underbetting, chip counts,
# wagers, all happen here.
#
# The player is passed in and will be delt with according
# to the API
{Hand} = require "hoyle"
{EventEmitter} = require 'events'
class exports.Player extends EventEmitter
  constructor: (bot, chips, seat)->
    @bot = bot
    @position = seat
    @chips = chips
    @name = bot.name if bot
    @reset()

  reset: ->
    @wagered = 0
    @state = 'active'
    @hand = null
    @cards = []
    @_actions = {}

  active: ->
    @state == 'active' || @state == 'allIn'

  inPlay: ->
    @wagered > 0 && @active()

  canBet: ->
    @chips > 0 && @active()

  bet: (amount) ->
    if amount > @chips
      amount = @chips
    @wagered = @wagered + amount
    @chips = @chips - amount
    amount

  actions: (round) ->
    @_actions[round] || []

  act: (round, action, amount) ->
    amount ||= 0
    @emit 'bet',
      position: @position
      state: @state
      amount: amount
      type: action
    _action = {type: action}
    _action['bet'] = amount if amount
    @_actions[round] ||= []
    @_actions[round].push _action
    if action == 'fold'
      @state = 'folded'
    else if action == 'allIn'
      @state = 'allIn'
    else if amount == @chips
      @state = 'allIn'
    if amount
      @bet(amount)
    _action

  takeBet: (self, gameStatus, cb) ->
    # Returns the bet amount Integer
    if @bot.act.length > 2
      @bot.act self, gameStatus, (err, bet) ->
        cb(err, bet)
    else
      process.nextTick =>
        cb null, @bot.act(self, gameStatus)

  payout: (gameStatus, cb) ->
    # Notify the play of who won
    if !@bot.payout
      process.nextTick =>
        cb null
    else if @bot.payout.length > 1
      @bot.payout gameStatus, (err) ->
        cb(err)
    else
      process.nextTick =>
        cb null, @bot.payout(gameStatus)

  lastBet: (state) ->
    lastAct = @actions(state)[@actions(state).length - 1]
    if lastAct && lastAct['bet']
      lastAct['bet']
    else
      0

  makeHand: (community) ->
    c = []
    c = c.concat(community)
    c = c.concat(@cards)
    @hand = Hand.make(c)
    @hand

  status: (priviledged) ->
    s =
      position: @position
      seat: @seat
      wagered: @wagered
      state: @state
      chips: @chips
      actions: @_actions || []
    if priviledged
      s.name = @name
      s.cards = @cards.map (c) -> c.toString()
      if @hand
        s.hand = @hand.name
    s

