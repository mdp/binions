assert = require 'assert'
util = require 'util'
{Game} = require '../src/game'
{Card} = require 'hoyle'
{Player} = require '../src/player'
NoLimit = require '../src/betting/no_limit'

BLIND = 10
MINIMUM = 20

callsAll =
  update: (game) ->
    unless game.state == 'complete'
      return game.betting.call

raisesOnceEachRound =
  update: (game) ->
    unless game.state == 'complete'
      if game.state != @lastState
        @lastState = game.state
        return game.betting.raise
      return game.betting.call

raisesAlways =
  update: (game) ->
    #console.log("raisebot: " + JSON.stringify(game, null, ' '))
    unless game.state == 'complete'
      return game.betting.raise
      
folder =
  update: (game) ->
    return 0

describe "Basic game", ->
  beforeEach () ->
    @noLimit = new NoLimit(BLIND,MINIMUM)
    @players = []
    chips = 1000
    for n in [0..6]
      @players.push new Player(callsAll, chips, n)

  it "should play the game to completion", (done) ->
    game = new Game(@players, @noLimit)
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
    game.deck.shuffle()

  it "should play the game to completion with run()", (done) ->
    game = new Game(@players, @noLimit)
    game.run()
    game.on 'complete', ->
      assert.ok game.winners.length > 0
      done()
  
  it "should give the big blind an option", (done) ->
    blindPlayers = []
    blindPlayers.push new Player(callsAll, 1000, 0)
    blindPlayers.push new Player(raisesOnceEachRound, 1000, 'dickblind')
    @players[0..1] = blindPlayers
    game = new Game(@players, @noLimit)
    game.on 'roundComplete', (state) ->
      status = game.status()
      assert @players[1].wagered == MINIMUM
      done()
    game.deck.on 'shuffled', ->
      game.deal()
      game.takeBets()
    game.deck.shuffle()
  
  it "should prevent a player from raising twice in a round", (done) ->
    blindPlayers = []
    @players.push new Player(raisesAlways, 1000, 'raisebot')
    game = new Game(@players, @noLimit)
    game.on 'roundComplete', (state) ->
      status = game.status()
      assert @players[@players.length - 1].wagered == MINIMUM
      done()
    game.deck.on 'shuffled', ->
      game.deal()
      game.takeBets()
    game.deck.shuffle()
    
  it "should take bets from all players after a raise when the next player in position has folded", (done) ->
    @players.push new Player(folder, 1000, 'foldbot')
    @players.push new Player(raisesAlways, 1000, 'raisebot')
    @players.push new Player(folder, 1000, 'foldbot')
    game = new Game(@players, @noLimit)
    game.on 'roundComplete', (state) ->
      #console.log(game.status())
      for player in @players
        continue if player.name == 'foldbot'
        assert player.wagered == @players[0].wagered, "Wager for player " + player.name + " is not what was expected: " + player.wagered
      if game.state == 'turn'
        done()
      else
        game.deal()
        game.takeBets()
    game.deck.on 'shuffled', ->
      game.deal()
      game.takeBets()
    game.deck.shuffle()

  describe "settling the game", ->

    it "should payout the right amounts", ->
      game = new Game(@players, @noLimit)
      @players[0].bet 5
      @players[1].bet 10
      @players[2].bet 0
      game.distributeWinnings([@players[1]])
      assert.equal @players[2].payout, 0
      assert.equal @players[2].chips, 1000
      assert.equal @players[1].payout, 5
      assert.equal @players[1].chips, 1005
      assert.equal @players[0].payout, -5
      assert.equal @players[0].chips, 995

  describe "splitting the pot", ->

    it "should handle a tie", ->
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

    it "should handle the dreaded three way uneven split", ->
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

  describe "with side pots", ->

    it "should handle side pots", ->
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

    it "should handle side pots with a single winner(side pot loses)", ->
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

    it "should side pots, along with a split pot", ->
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

  describe "telling players what they won", ->

    it "should call payout", (done) ->
      players = []
      for n in [0..2]
        players.push new Player({update: (() -> 0)}, 100, n)
      players.push new Player({
        update: (game) ->
          if game.state == 'complete'
            assert.ok
            done()
          else
            0
      }, 100, 3)
      game = new Game(players, @noLimit)
      game.settle()

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
