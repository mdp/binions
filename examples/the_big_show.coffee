{Game} = require '../src/game'
{Card} = require 'hoyle'
{Player} = require '../src/player'
NoLimit = require '../src/betting/no_limit'

callBot = require './players/call_all'
randBot = require './players/unpredictable'
smartBot = require './players/smart_bot'

noLimit = new NoLimit(10,20)
players = []
chips = 1000
for i in [1..6]
  players.push new Player(callBot("Steve #{i}"), chips, i)
players.push new Player(randBot("Jim"), chips, i + 3)
sam = new Player(smartBot("Sam"), chips, i + 3)
sam.on 'bet', (bet) ->
  console.log bet
players.push sam


rounds = 1000
i = 0
run = ->
  game = new Game(players, noLimit)
  game.run()
  game.on 'roundComplete', ->
    #console.log "round complete"
  game.on 'complete', (status) ->
    console.log "Round #{i}"
    i++
    numPlayer = (players.filter (p) -> p.chips > 0).length
    if i == rounds or numPlayer < 2
      console.log players.map (p) -> "Name: #{p.name} - $#{p.chips}"
    else
      players = players.concat(players.shift())
      run()

run()

