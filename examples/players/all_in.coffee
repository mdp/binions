module.exports = (name) ->
  name: name
  update: (game) ->
    if me.canRaise
      me.chips
    else
      me.minToCall
