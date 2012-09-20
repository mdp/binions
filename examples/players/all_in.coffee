module.exports = (name) ->
  name: name
  act: (me, status) ->
    if status.canRaise
      me.chips
    else
      0
