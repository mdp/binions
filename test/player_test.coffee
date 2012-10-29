assert = require 'assert'
{Card} = require 'hoyle'
{Player} = require '../src/player'

describe "Basic player", ->
  beforeEach ->
    bot =
      update: (game) -> 200
    name = "Johnny Moss"
    chips = 1000
    @player = new Player(bot, chips, name)

  it "should have a name", ->
    assert.equal @player.name, 'Johnny Moss'

  it "should be able to make a hand", ->
    @player.cards = [new Card('As'), new Card('Kh')]
    hand = @player.makeHand([new Card('Ah'), new Card('Ks'), new Card('Td')])
    assert.equal hand.name, "Two pair"

  describe "status", ->

    it "should hide their cards during game play", ->
      @player.cards = [new Card('As'), new Card('Kh')]
      status = @player.status(Player.STATUS.PUBLIC)
      assert.equal undefined, status.cards

    it "should show their cards at the end", ->
      @player.cards = [new Card('As'), new Card('Kh')]
      status = @player.status(Player.STATUS.FINAL)
      assert.equal 2,status.cards.length

    it "should show their cards at the end unless they folded", ->
      @player.cards = [new Card('As'), new Card('Kh')]
      @player.state = 'folded'
      status = @player.status(Player.STATUS.FINAL)
      assert.equal undefined, status.cards
