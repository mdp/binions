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
    @cards = []
    @_actions = {}
    @chips = chips
    @wagered = 0
    @state = 'active'
    @name = bot.name if bot
    @hand = null

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
    if @bot.async #Remote bot
      @bot.act self, gameStatus, (err, bet) ->
        cb(err, bet)
    else
      cb null, @bot.act(self, gameStatus)

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

  status: (final) ->
    s =
      position: @position
      wagered: @wagered
      state: @state
      chips: @chips
      name: @name
      actions: @_actions || []
    if final
      s.cards = @cards.map (c) -> c.toString()
      s.hand = @hand.toString()
    s

