module.exports = (name) ->
  name: name
  act: (me, game) ->
    raise = Math.random() < 0.25
    if raise
      me.minToRaise
    else
      me.minToCall
