module.exports = (name) ->
  name: name
  act: (me, status) ->
    if me.canRaise
      me.chips
    else
      me.minToCall
