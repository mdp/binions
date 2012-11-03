[![Build
Status](https://secure.travis-ci.org/mdp/binions.png)](http://travis-ci.org/mdp/binions)

![Binions](http://s3.amazonaws.com/img.mdp.im/binions_cut-20120918-200256.jpg)

# Binions
## A javascript poker tournament/game engine for bots

## Running a game

    {Game} = require 'binions'
    {Player} = require 'binions'
    {NoLimit} = require 'binions'

    describe "Basic game", ->
      beforeEach () ->
        @noLimit = new NoLimit(10,20)
        @players = []
        chips = 1000
        misterCallsAll =
          update: (game) ->
            game.betting.call
        for n in [0..6]
          @players.push new Player(misterCallsAll, chips, n)

      it "should play the game to completion with run()", (done) ->
        game = new Game(@players, @noLimit)
        game.run()
        game.on 'complete', ->
          assert.ok game.winners.length > 0
          done()

## Todo

### Tests

- More tests on bet handlers(NoLimit)

### Build more example players

- Players that only play certain pocket cards (eg, Kings or higer)
- Tight players
- Players that occasionally go all in

