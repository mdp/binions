assert = require 'assert'
{Game} = require '../src/game'
{Card} = require 'hoyle'
{Player} = require '../src/player'
NoLimit = require '../src/betting/no_limit'

describe "Basic game", ->
  beforeEach () ->
    @noLimit = new NoLimit(10,20)
    @players = []
    chips = 1000
    callsAll =
      act: (self, status) ->
        if self.wagered < self.minToCall
          self.minToCall - self.wagered
        else
          0
    for n in [0..6]
      @players.push new Player(callsAll, chips, n)

  it "should play the game to completion", (done) ->
    game = new Game(@players, @noLimit)
    game.deck.shuffle()
    game.on 'complete', ->
      assert.ok game.winners.length > 0
      done()
    game.on 'roundComplete', (state) ->
      if game.deal()
        game.takeBets()
      else
        game.settle()
    game.deck.on 'shuffled', ->
      game.deal()
      game.takeBets()

  it "should play the game to completion with run()", (done) ->
    game = new Game(@players, @noLimit)
    game.run()
    game.on 'complete', ->
      assert.ok game.winners.length > 0
      done()

  describe "splitting the pot", ->

    it "should handle a tie", (done) ->
      game = new Game(@players, @noLimit)
      game.community = ['As','Ah','9c'].map (c) -> new Card(c)
      @players[0].cards = ['Ac','Kh'].map (c) -> new Card(c)
      @players[1].cards = ['Ad','Kh'].map (c) -> new Card(c)
      for player in @players
        player.bet 50
      assert.equal game.pot(), 350
      game.settle()
      assert.equal game.winners.length, 2
      assert.equal @players[0].chips, 1125
      assert.equal @players[1].chips, 1125
      assert.equal @players[2].chips, 950
      done()

    it "should handle the dreaded three way uneven split", (done) ->
      game = new Game(@players, @noLimit)
      game.community = ['As','8c','9c'].map (c) -> new Card(c)
      @players[0].cards = ['Ac','Kh'].map (c) -> new Card(c)
      @players[1].cards = ['Ad','Kd'].map (c) -> new Card(c)
      @players[2].cards = ['Ah','Ks'].map (c) -> new Card(c)
      for player in @players
        player.bet 10
      assert.equal game.pot(), 70
      game.settle()
      assert.equal game.winners.length, 3
      assert.equal @players[3].chips, 990
      assert.equal @players[0].chips, 1014
      assert.equal @players[1].chips, 1013
      assert.equal @players[2].chips, 1013
      done()

  describe "with side pots", ->

    it "should handle side pots", (done) ->
      game = new Game(@players, @noLimit)
      game.community = ['As','8c','9c'].map (c) -> new Card(c)
      @players[0].cards = ['Ac','9d'].map (c) -> new Card(c)
      @players[0].bet 40
      @players[1].cards = ['Ad','8d'].map (c) -> new Card(c)
      @players[1].bet 50
      @players[2].cards = ['Ah','7s'].map (c) -> new Card(c)
      @players[2].bet 50
      assert.equal game.pot(), 140
      game.settle()
      assert.equal @players[0].chips, 960 + (40*3)
      assert.equal @players[1].chips, 950 + (10*2)
      assert.equal @players[2].chips, 950
      done()

    it "should handle side pots with a single winner(side pot loses)", (done) ->
      game = new Game(@players, @noLimit)
      game.community = ['As','8c','9c'].map (c) -> new Card(c)
      @players[0].cards = ['Ac','9d'].map (c) -> new Card(c)
      @players[0].bet 50
      @players[1].cards = ['Ad','8d'].map (c) -> new Card(c)
      @players[1].bet 50
      @players[2].cards = ['Ah','7s'].map (c) -> new Card(c)
      @players[2].bet 40
      assert.equal game.pot(), 140
      game.settle()
      assert.equal @players[0].chips, 950 + (50*2) + 40
      assert.equal @players[1].chips, 950
      assert.equal @players[2].chips, 960
      done()

    it "should side pots, along with a split pot", (done) ->
      game = new Game(@players, @noLimit)
      game.community = ['As','8c','9c'].map (c) -> new Card(c)
      @players[0].cards = ['Ac','9d'].map (c) -> new Card(c)
      @players[0].bet 40
      @players[1].cards = ['Ad','8d'].map (c) -> new Card(c)
      @players[1].bet 50
      @players[2].cards = ['Ah','8s'].map (c) -> new Card(c)
      @players[2].bet 50
      assert.equal game.pot(), 140
      game.settle()
      assert.equal @players[0].chips, 960 + (40*3)
      assert.equal @players[1].chips, 950 + 10
      assert.equal @players[2].chips, 950 + 10
      done()

  describe "with broke players", ->

    it "should safely eject them", ->
      players = []
      for n in [0..2]
        players.push new Player({}, 100, n)
      for n in [0..2]
        players.push new Player({}, 0, n)
      game = new Game(players, @noLimit)
      assert.equal game.players.length, 3

    it "should refuse to play games with less than two moneyed players", ->
      players = [
        new Player({}, 100)
        new Player({}, 0)
      ]
      test = -> new Game(players, @noLimit)
      assert.throws(test, /Not enough players/)
