module.exports = (name) ->
  name: name
  update: (game) ->
    return false if game.state == 'complete'
    if game.betting.canRaise
      game.self.chips
    else
      game.betting.call
