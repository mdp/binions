assert = require 'assert'
NoLimit = require('../src/betting/no_limit')(10,20)
{Player} = require '../src/player'
{Game} = require '../src/game'

kPlayerStartingChips = 1000

describe "General betting expectations", ->
  beforeEach ->
    @players = []
    callsAll =
      update: (game) ->
        unless game.state == 'complete'
          if game.self.wagered < game.minToCall
            game.minToCall - game.self.wagered
          else
            0
    for n in [0..3]
      @players.push new Player(callsAll, kPlayerStartingChips, n)
    @state = 'flop'
    @noLimit = new NoLimit(@players, @state)


  it "should calculate the correct minimum raise and call amounts at the start of a round", ->
    betOptions = @noLimit.analyze()
    assert.equal 10, betOptions['raise']
    assert.equal 0, betOptions['call']
    
  it "should allow a check", ->
    betOptions = @noLimit.analyze()
    @noLimit.bet(0, 0, null)
    betAction = @players[0].actions(@state)[0]
    assert betAction['type'] == 'check'

  it "should allow a player to raise", ->
    betOptions = @noLimit.analyze()
    actingPlayer = @noLimit.nextToAct
    raiseAmount = betOptions['call'] + betOptions['raise']
    @noLimit.bet(raiseAmount, 0, null)
    betAction = @players[0].actions(@state)[0]
    assert betAction['type'] == 'raise'
    assert betAction['bet'] == raiseAmount
    assert @noLimit.options()['call'] == raiseAmount
  
  it "should allow a player to go all-in", ->
    @noLimit.analyze()
    allInBet = @players[0].chips
    @noLimit.bet(allInBet, 0, null)
    betAction = @players[0].actions(@state)[0]
    assert betAction['type'] == 'allIn'
    assert betAction['bet'] == allInBet
  
  it "should allow a player to raise all-in", ->
    @noLimit.analyze()
    @noLimit.bet(@noLimit.options()['call'] + @noLimit.options()['raise'], 0, null)
    @noLimit.bet(@noLimit.options()['call'] + @noLimit.options()['raise'], 1, null)
    @noLimit.bet(kPlayerStartingChips, 2, null)
    betAction = @players[2].actions(@state)[0]
    assert betAction['type'] == 'allIn'
    assert betAction['bet'] == kPlayerStartingChips
    
  it "should not allow a player to bet more chips than they have", ->
    @noLimit.analyze()
    @noLimit.bet(kPlayerStartingChips * 2, 0, null)
    betAction = @players[0].actions(@state)[0]
    assert betAction['type'] == 'allIn'
    assert betAction['bet'] == kPlayerStartingChips
    
  it "should allow a player to fold", ->
    betOptions = @noLimit.analyze()
    raiseAmount = betOptions['call'] + betOptions['raise']
    @noLimit.bet(raiseAmount, 0, null)
    @noLimit.bet(0, 1, null)
    betAction = @players[1].actions(@state)[0]
    assert betAction['type'] == 'fold'
    
  it "should allow a re-raise", ->
    betOptions = @noLimit.analyze()
    raiseAmount = betOptions['call'] + betOptions['raise']
    @noLimit.bet(raiseAmount, 0, null)
    
    reRaiseAmount = @noLimit.options()['call'] + @noLimit.options()['raise']
    assert reRaiseAmount > raiseAmount
    @noLimit.bet(reRaiseAmount, 1, null)
    betAction = @players[1].actions(@state)[0]
    assert betAction['type'] == 'raise'
    
  it "should prevent a player from calling less than the call amount", ->
    betOptions = @noLimit.analyze()
    actingPlayer = @noLimit.nextToAct
    raiseAmount = betOptions['call'] + betOptions['raise']
    @noLimit.bet(raiseAmount, null, null)
    
    @noLimit.bet(@noLimit.options()['call'] - 1, null, null)
    betAction = @players[1].actions(@state)[0]
    assert betAction['type'] == 'fold'    
    
  it "should prevent a player from raising less than the minimum amount", ->
    betOptions = @noLimit.analyze()
    actingPlayer = @noLimit.nextToAct
    @noLimit.bet(betOptions['call'] + betOptions['raise'] - 1, 0, null)
    assert (@players[0].actions(@state)[0])['type'] == 'check'