module.exports = (name) ->
  name: name
  update: (game) ->
    raise = Math.random() < 0.25
    return false if game.state == 'complete'
    if raise
      game.betting.raise
    else
      game.betting.call
