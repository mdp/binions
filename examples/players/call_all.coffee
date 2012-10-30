module.exports = (name) ->
  name: name
  update: (game) ->
    return false if game.state == 'complete'
    game.betting.call
