assert = require 'assert'
NoLimit = require('../src/betting/no_limit')(10,20)
{Player} = require '../src/player'
{Game} = require '../src/game'

describe "General betting expectations", ->
  beforeEach ->
    @players = []
    callsAll =
      update: (game) ->
        unless game.state == 'complete'
          if game.me.wagered < game.minToCall
            game.minToCall - game.me.wagered
          else
            0
    for n in [0..6]
      @players.push new Player(callsAll, 1000, n)
    @state = 'flop'
    @noLimit = new NoLimit(@players, @state)


  it "should take betting for a round", ->
    betOptions = @noLimit.analyze()
    assert.equal 10, betOptions['raise']
    assert.equal 0, betOptions['call']

