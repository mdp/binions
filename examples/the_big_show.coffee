{Game} = require '../src/game'
{Card} = require 'hoyle'
{Player} = require '../src/player'
NoLimit = require '../src/betting/no_limit'

callBot = require './players/call_all'
randBot = require './players/unpredictable'

noLimit = new NoLimit(10,20)
players = []
chips = 10000
for i in [0..3]
  players.push new Player(callBot("steve #{i}"), chips, i)
for i in [0..2]
  players.push new Player(randBot("Jim #{i}"), chips, i + 3)


rounds = 100
i = 0
run = ->
  game = new Game(players, noLimit)
  game.run()
  game.on 'roundComplete', ->
    #console.log "round complete"
  game.on 'complete', (status) ->
    console.log "Round #{i}"
    i++
    if i == rounds
      console.log JSON.stringify(status.players[status.winners[0].position], null, 2)
    if i < rounds
      players = players.concat(players.shift())
      run()

run()

