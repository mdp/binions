[![Build
Status](https://secure.travis-ci.org/mdp/hellmuth.png)](http://travis-ci.org/mdp/hellmuth)
# Hellmuth
## A javascript poker tournament/game engine for bots

## Running a game

    {Game} = require 'hellmuth'
    {Player} = require 'hellmuth'
    {NoLimit} = require 'hellmuth'

    describe "Basic game", ->
      beforeEach () ->
        @noLimit = new NoLimit(10,20)
        @players = []
        chips = 1000
        misterCallsAll =
          act: (self, status) ->
            if self.wagered < self.minToCall
              self.minToCall - self.wagered
            else
              0
        for n in [0..6]
          @players.push new Player(misterCallsAll, chips, n)

      it "should play the game to completion with run()", (done) ->
        game = new Game(@players, @noLimit)
        game.run()
        game.on 'complete', ->
          assert.ok game.winners.length > 0
          done()

## Requirements

### JS Sandbox

Figure out how to safely run JS code from contestants.

- Stop access to globals
- No require (No ability to require a file system module or network)
- Need a way to measure speed and stop slow bots(What's a good limit, 1000ms), fold/check on timeout
- Prevent errors, fold on error.
- Require certain attributes: Name
- Network layer provided, your bot simply has to respond to a game
  object
- Prevent setTimeout
- Run in seperate process, handle excess memory usage, process exceptions, timeouts

### Game

- No limit Texas Hold'em

### Frontend

- Need live updating scoreboard.
- Live stats, each player, hands folded, pots one, raises

### Bots

- Build a sample bot for testing

