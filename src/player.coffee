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
Player = class exports.Player extends EventEmitter
  @STATUS =
    PUBLIC: 0
    FINAL: 1
    PRIVILEGED: 2

  constructor: (bot, chips, name)->
    @bot = bot
    @chips = chips
    @name = name
    @reset()

  reset: ->
    @wagered = 0
    @payout = 0
    @ante = 0
    @blind = 0
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

  takeBlind: (amount) ->
    @blind = @bet(amount)
    @blind

  actions: (round) ->
    @_actions[round] || []

  act: (round, action, amount, err) ->
    amount ||= 0
    @emit 'bet',
      state: @state
      amount: amount
      type: action
    _action = {type: action}
    if err
      _action.error = err
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
    @emit('betAction', action, amount, err)
    _action

  update: (gameStatus, cb) ->
    # Returns the bet amount Integer
    if @bot.update.length > 1
      @bot.update gameStatus, (err, res) ->
        cb(err, res)
    else
      process.nextTick =>
        cb null, @bot.update(gameStatus)

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

  status: (level) ->
    s =
      name: @name
      blind: @blind
      ante: @ante
      wagered: @wagered
      state: @state
      chips: @chips
      actions: @_actions || []
    if @payout
      s.payout = @payout
    # Only show the cards in the final round if the player has not folded
    # or if we are asking for the PRIVILEGED/Logging view
    if (level == Player.STATUS.FINAL && @active()) || level == Player.STATUS.PRIVILEGED
      s.cards = @cards.map (c) -> c.toString()
      if @hand
        s.handName = @hand.name
        s.hand = @hand.cards.map (c) -> c.toString()
    s

