assert = require 'assert'
{Card} = require 'binions'
{Player} = require '../src/player'

describe "Basic player", ->
  beforeEach ->
    bot =
      name: "Johnny Moss"
      act: (game) -> 200
    seat = 0
    chips = 1000
    @player = new Player(bot, chips, seat)

  it "should have a name", ->
    assert.equal @player.name, 'Johnny Moss'

  it "should be able to make a hand", ->
    @player.cards = [new Card('As'), new Card('Kh')]
    hand = @player.makeHand([new Card('Ah'), new Card('Ks'), new Card('Td')])
    assert.equal hand.name, "Two pair"
