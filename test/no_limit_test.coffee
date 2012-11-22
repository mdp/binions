assert = require 'assert'
NoLimit = require('../src/betting/no_limit')(10,20)
{Player} = require '../src/player'

describe "No limit betting", ->
  describe "Handle checks", ->
    beforeEach ->
      @players = []
      for n in [0..3]
        @players.push new Player({}, 1000, n)
      @noLimit = new NoLimit(@players, 'flop')

    it "should advance the nextPlayer after a check", () ->
      @noLimit.bet(0, 0)
      assert.equal @noLimit.nextToAct, @players[1]
      assert.equal @noLimit.minToRaise, 10
      assert.equal @noLimit.minToCall, 0

    it "end a checked round", () ->
      @noLimit.bet(0, 0)
      @noLimit.bet(0, 1)
      @noLimit.bet(0, 2)
      @noLimit.bet(0, 3)
      assert.equal @noLimit.nextToAct, null
      assert.equal @noLimit.minToRaise, 10
      assert.equal @noLimit.minToCall, 0

  describe "Determining minimum raise", ->
    beforeEach ->
      @players = []
      for n in [0..3]
        @players.push new Player({}, 1000, n)
      @noLimit = new NoLimit(@players, 'flop')

    it "should start betting with the right call amount", () ->
      assert.equal @noLimit.minToRaise, 10
      assert.equal @noLimit.minToCall, 0

    it "should include the previous call in calc", () ->
      @noLimit.bet(10,0)
      @noLimit.bet(50,1)
      assert.equal @noLimit.minToRaise, 90, "Should raise by 40"
      assert.equal @noLimit.minToCall, 50
      @noLimit.bet(90,2)
      assert.equal @noLimit.minToRaise, 130
      assert.equal @noLimit.minToCall, 90

    it "not count partial(all-in) raises", () ->
      @players[2].chips = 60
      @noLimit.bet(10,0)
      @noLimit.bet(50,1)
      @noLimit.bet(60,2) # AllIn
      assert.equal @noLimit.minToRaise, 100
      assert.equal @noLimit.minToCall, 60
      assert.equal @noLimit.nextToAct, @players[3]

    it "count full(all-in) raises", () ->
      @players[2].chips = 60
      @players[3].chips = 110
      @noLimit.bet(10,0)
      @noLimit.bet(50,1)
      @noLimit.bet(60,2) # AllIn
      @noLimit.bet(110,3) # AllIn
      assert.equal @noLimit.nextToAct, @players[0]
      assert.equal @noLimit.minToRaise, 160
      assert.equal @noLimit.minToCall, 110

  describe "Re-raises", ->
    beforeEach ->
      @players = []
      for n in [0..3]
        @players.push new Player({}, 1000, n)
      @noLimit = new NoLimit(@players, 'flop')

    it "should not happen normally", () ->
      @noLimit.bet(10,0)
      @noLimit.bet(50,1) # Raise of 40
      @noLimit.bet(50,2) # Call
      @noLimit.bet(50,3) # Call
      @noLimit.bet(40,0) # Call
      assert.equal @noLimit.player, null

    it "should only allow call of incomplete raise", () ->
      @players[3].chips = 80
      @noLimit.bet(10,0)
      @noLimit.bet(50,1) # Raise of 40
      @noLimit.bet(50,2) # Call
      @noLimit.bet(80,3) # AllIn incomplete raise of 30
      @noLimit.bet(70,0) # Call
      assert.equal @noLimit.minToCall, 80
      assert.equal @noLimit.nextToAct, @players[1]
      assert.ok !@noLimit.canRaise
      @noLimit.bet(30,1) # Call
      assert.equal @noLimit.nextToAct, @players[2]
      @noLimit.bet(30,2) # Call
      assert.equal @noLimit.nextToAct, null

  describe "during the pre-flop", ->

    beforeEach ->
      @players= []
      for n in [0..3]
        @players.push new Player({}, 1000, n)
      @noLimit = new NoLimit(@players, 'pre-flop')
      @noLimit.takeBlinds()

    it "should start with players after blinds", ->
      assert.equal @noLimit.nextToAct, @players[2]
      assert.equal @noLimit.minToCall, 10

    it "should handle blinds on option/check", ->
      @noLimit.bet(10,2)
      @noLimit.bet(10,3)
      assert.equal @noLimit.nextToAct, @players[0]
      assert.equal @noLimit.minToCall, 10

    it "should handle blinds raising", ->
      @noLimit.bet(10,2)
      @noLimit.bet(10,3)
      @noLimit.bet(5,0)
      @noLimit.bet(10,1) # Raise to 20
      assert.equal @noLimit.minToCall, 20
      assert.equal @noLimit.nextToAct, @players[2]
      @noLimit.bet(10,2)
      assert.equal @noLimit.minToCall, 20
      assert.equal @noLimit.nextToAct, @players[3]
      @noLimit.bet(10,3)
      assert.equal @noLimit.minToCall, 20
      assert.equal @noLimit.nextToAct, @players[0]
      @noLimit.bet(10,0)
      assert.equal @noLimit.nextToAct, null

    it "should handle folds", ->
      @noLimit.bet(0,2)
      @noLimit.bet(10,3)
      @noLimit.bet(5,0)
      @noLimit.bet(10,1) # Raise to 20
      assert.equal @noLimit.minToCall, 20
      assert.equal @noLimit.nextToAct, @players[3]

    it "should handle everyone folding", () ->
      @noLimit.bet(0,2)
      @noLimit.bet(0,3)
      @noLimit.bet(0,0)
      assert.equal @noLimit.nextToAct, null

  describe "after the pre-flop", ->

    beforeEach ->
      @players= []
      for n in [0..3]
        @players.push new Player({}, 1000, n)
      new NoLimit(@players, 'pre-flop').takeBlinds()
      @noLimit = new NoLimit(@players, 'flop')

    it "should handle folds", ->
      @players[0].state = 'folded'
      @noLimit.analyze()
      assert.equal @noLimit.nextToAct, @players[1]

  describe "heads up", ->

    describe "during the pre-flop", ->

      beforeEach ->
        @players= []
        for n in [0..1]
          @players.push new Player({}, 1000, n)
        @noLimit = new NoLimit(@players, 'pre-flop')
        @noLimit.takeBlinds()

      it "should take small blind from the button", () ->
        assert.equal @players[1].blind, 5

      it "should start with the button/dealer", () ->
        assert.equal @noLimit.nextToAct, @players[1]
        assert.equal @noLimit.minToCall, 10

    describe "outside the pre-flop", ->

      beforeEach ->
        @players= []
        for n in [0..1]
          @players.push new Player({}, 1000, n)
        @noLimit = new NoLimit(@players, 'flop')

      it "should start with the first player", () ->
        assert.equal @noLimit.nextToAct, @players[0]
        assert.equal @noLimit.minToCall, 0

  describe "handling errors", ->

    beforeEach ->
      @players= []
      for n in [0..1]
        @players.push new Player({}, 1000, n)
      @noLimit = new NoLimit(@players, 'pre-flop')

    it "should record the error on the action", () ->
      @noLimit.bet(0, 0, "Syntax error")
      assert.equal 'Syntax error', @players[0].actions('pre-flop')[0].error
