module.exports = (name) ->
  name: name
  update: (game) ->
    return false if game.state == 'complete'
    if game.betting.canRaise
      me.chips
    else
      game.betting.call
