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
      @noLimit.bet(1, 0)
      @noLimit.bet(2, 0)
      @noLimit.bet(3, 0)
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
      @noLimit.bet(0, 10)
      @noLimit.bet(1, 50)
      assert.equal @noLimit.minToRaise, 90, "Should raise by 40"
      assert.equal @noLimit.minToCall, 50
      @noLimit.bet(2, 90)
      assert.equal @noLimit.minToRaise, 130
      assert.equal @noLimit.minToCall, 90

    it "not count partial(all-in) raises", () ->
      @players[2].chips = 60
      @noLimit.bet(0, 10)
      @noLimit.bet(1, 50)
      @noLimit.bet(2, 60) # AllIn
      assert.equal @noLimit.minToRaise, 100
      assert.equal @noLimit.minToCall, 60
      assert.equal @noLimit.nextToAct, @players[3]

    it "count full(all-in) raises", () ->
      @players[2].chips = 60
      @players[3].chips = 110
      @noLimit.bet(0, 10)
      @noLimit.bet(1, 50)
      @noLimit.bet(2, 60) # AllIn
      @noLimit.bet(3, 110) # AllIn
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
      @noLimit.bet(0, 10)
      @noLimit.bet(1, 50) # Raise of 40
      @noLimit.bet(2, 50) # Call
      @noLimit.bet(3, 50) # Call
      @noLimit.bet(0, 40) # Call
      assert.equal @noLimit.player, null

    it "should only allow call of incomplete raise", () ->
      @players[3].chips = 80
      @noLimit.bet(0, 10)
      @noLimit.bet(1, 50) # Raise of 40
      @noLimit.bet(2, 50) # Call
      @noLimit.bet(3, 80) # AllIn incomplete raise of 30
      @noLimit.bet(0, 70) # Call
      assert.equal @noLimit.minToCall, 80
      assert.equal @noLimit.nextToAct, @players[1]
      assert.ok !@noLimit.canRaise
      @noLimit.bet(1, 30) # Call
      assert.equal @noLimit.nextToAct, @players[2]
      @noLimit.bet(2, 30) # Call
      assert.equal @noLimit.nextToAct, null

  describe "during the pre-flop", ->

    beforeEach ->
      @players= []
      for n in [0..3]
        @players.push new Player({}, 1000, n)
      @noLimit = new NoLimit(@players, 'pre-flop')
      @noLimit.takeBlinds()

    it "should start with players after blinds", () ->
      assert.equal @noLimit.nextToAct, @players[2]
      assert.equal @noLimit.minToCall, 10

    it "should handle blinds on option/check", () ->
      @noLimit.bet(2, 10)
      @noLimit.bet(3, 10)
      assert.equal @noLimit.nextToAct, @players[0]
      assert.equal @noLimit.minToCall, 10

    #it "should handle blinds raising", () ->
      #@positions[2].act 'preFlop', 'call', 10
      #@positions[3].act 'preFlop', 'call', 10
      #@positions[0].act 'preFlop', 'call', 5
      #@positions[1].act 'preFlop', 'raise', 10
      #next = @noLimit.next()
      #assert.equal next.minToCall, 10
      #assert.equal next.position, 2

    #it "should handle folds", () ->
      #@positions[2].act 'preFlop', 'fold'
      #@positions[3].act 'preFlop', 'call', 10
      #@positions[0].act 'preFlop', 'call', 5
      #@positions[1].act 'preFlop', 'raise', 10
      #next = @noLimit.next()
      #assert.equal next.minToCall, 10
      #assert.equal next.position, 3

    #it "should handle everyone folding", () ->
      #@positions[2].act 'preFlop', 'fold'
      #@positions[3].act 'preFlop', 'fold'
      #@positions[0].act 'preFlop', 'fold'
      #next = @noLimit.next()
      #assert.ok !next

  #describe "during the flop", ->

    #beforeEach ->
      #@positions = []
      #for n in [0..3]
        #@positions.push new Position({}, 1000, n)
      #@noLimit = new NoLimit(@positions, 'flop')

    #it "should start with the first position", () ->
      #next = @noLimit.next()
      #assert.equal next.position, 0
      #assert.equal next.minToCall, 0
      #assert.equal next.minToRaise, 10
      #assert.ok next.actions.indexOf('fold') >= 0
      #assert.ok next.actions.indexOf('check') >= 0
      #assert.ok next.actions.indexOf('raise') >= 0

    #it "should handle folds", () ->
      #@positions[0].act 'flop', 'check'
      #@positions[1].act 'flop', 'check'
      #@positions[2].act 'flop', 'fold'
      #next = @noLimit.next()
      #assert.equal next.position, 3
      #assert.equal next.minToCall, 0
      #assert.ok next.actions.indexOf('fold') >= 0
      #assert.ok next.actions.indexOf('check') >= 0
      #assert.ok next.actions.indexOf('raise') >= 0

    #it "should handle everyone folding", () ->
      #@positions[0].act 'flop', 'fold'
      #@positions[1].act 'flop', 'fold'
      #@positions[2].act 'flop', 'fold'
      #next = @noLimit.next()
      #assert.ok !next

    #it "should handle a late raise", () ->
      #@positions[0].act 'flop', 'fold'
      #@positions[1].act 'flop', 'check'
      #@positions[2].act 'flop', 'check'
      #@positions[3].act 'flop', 'raise', 10
      #next = @noLimit.next()
      #assert.equal next.position, 1
      #assert.equal next.minToCall, 10
      #assert.equal next.minToRaise, 20
      #assert.ok next.actions.indexOf('fold') >= 0
      #assert.ok next.actions.indexOf('call') >= 0
      #assert.ok next.actions.indexOf('raise') >= 0
      #assert.ok next.actions.indexOf('check') < 0

    #it "should handle a big raise", () ->
      #@positions[0].act 'flop', 'fold'
      #@positions[1].act 'flop', 'check'
      #@positions[2].act 'flop', 'check'
      #@positions[3].act 'flop', 'raise', 50
      #next = @noLimit.next()
      #assert.equal next.position, 1
      #assert.equal next.minToCall, 50
      #assert.equal next.minToRaise, 100
      #assert.ok next.actions.indexOf('fold') >= 0
      #assert.ok next.actions.indexOf('call') >= 0
      #assert.ok next.actions.indexOf('raise') >= 0
      #assert.ok next.actions.indexOf('check') < 0

    #it "should not allow a re-raise", () ->
      #@positions[0].act 'flop', 'check'
      #@positions[1].act 'flop', 'raise', 50
      #@positions[2].act 'flop', 'call', 50
      #@positions[3].act 'flop', 'call', 50

      #@positions[0].act 'flop', 'call', 50
      #next = @noLimit.next()
      #assert.ok !next

    #it "should enforce a raise minimum of the last bet (http://www.rgpfaq.com/no-limit.html)", ->
      #@positions[0].act 'flop', 10 # Raise
      #@positions[1].act 'flop', 50 # Raise
      #@noLimit.bet(0, 10) # Raise
      #@noLimit.bet(0, 50) # Raise
      #next = @noLimit.next()
      #assert.equal next.position, 2
      #assert.equal next.minToCall, 50
      #assert.equal next.minToRaise, 90 # Last raise was 40

    #it "should not allow a re-raise after a all-in that doesn't meet the minimum", () ->
      #@positions[0].chips = 15
      #@positions[0].act 'flop', 'check'
      #@positions[1].act 'flop', 'raise', 10
      #@positions[2].act 'flop', 'call', 10
      #@positions[3].act 'flop', 'call', 10

      #@positions[0].act 'flop', 'raise', 15 # This doesn't count as a real-raise because a raise is $20 or more
      #next = @noLimit.next()
      #console.log next
      #assert.equal next.position, 1
      #assert.equal next.minToCall, 5
      #assert.ok next.actions.indexOf('call') >= 0
      #assert.ok next.actions.indexOf('raise') < 0, "Should not be able to raise"

    #it "should not allow a raise after a all-in that doesn't meet the minimum", () ->
      #@positions[0].chips = 30
      #@positions[0].act 'flop', 'check'
      #@positions[1].act 'flop', 'raise', 20
      #@positions[2].act 'flop', 'call', 20
      #@positions[3].act 'flop', 'call', 20

      #@positions[0].act 'flop', 'allIn', 30 # This doesn't count as a real-raise because a raise is $20 or more
      #@positions[1].act 'flop', 'call', 10
      #next = @noLimit.next()
      #console.log next
      #assert.equal next.position, 2
      #assert.equal next.minToCall, 10
      #assert.ok next.actions.indexOf('call') >= 0
      #assert.ok next.actions.indexOf('raise') < 0, "Should not be able to raise"
      #@positions[2].act 'flop', 'call', 10
      #@positions[3].act 'flop', 'fold'
      #next = @noLimit.next()
      #assert.ok !next

    #it "should handle and allIn followed by raises", () ->
      #@positions[0].chips = 30
      #@positions[0].act 'flop', 'allIn', 30
      #@positions[1].act 'flop', 'raise', 60
      #@positions[2].act 'flop', 'call', 60
      #@positions[3].act 'flop', 'call', 60
      #next = @noLimit.next()
      #assert.ok !next

    #it "should handle and allIn followed by multiple raises", () ->
      #@positions[0].chips = 30
      #@positions[0].act 'flop', 'allIn', 30
      #@positions[1].act 'flop', 'raise', 60
      #@positions[2].act 'flop', 'raise', 120
      #@positions[3].act 'flop', 'raise', 240
      #next = @noLimit.next()
      #assert.equal next.position, 1
      #assert.equal next.minToCall, 180
      #assert.equal next.minToRaise, 480
      #assert.ok next.actions.indexOf('call') >= 0, "Should be able to call"
      #assert.ok next.actions.indexOf('raise') >= 0, "Should be able to raise"
