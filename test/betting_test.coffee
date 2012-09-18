assert = require 'assert'
NoLimit = require('../src/betting/no_limit')(10,20)
{Player} = require '../src/player'

describe "General betting expectations", ->
  beforeEach ->
    @players = []
    callsAll =
      act: (self, status) ->
        if self.wagered < status.minToCall
          status.minToCall - self.wagered
        else
          0
    for n in [0..6]
      @players.push new Player(callsAll, 1000, n)
    @state = 'flop'
    @noLimit = new NoLimit(@players, @state)
    @gameStatus = {}

  it "should take betting for a round", (done) ->
    @noLimit.takeBets @gameStatus, =>
      for player in @players
        assert.equal player.actions(@state).length, 1
      done()

