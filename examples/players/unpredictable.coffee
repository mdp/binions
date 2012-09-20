module.exports = (name) ->
  name: name
  act: (me, game) ->
    raise = Math.random() < 0.20
    if raise
      me.minToRaise - me.wagered
    else
      me.minToCall - me.wagered
