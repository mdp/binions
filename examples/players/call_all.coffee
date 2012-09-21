module.exports = (name) ->
  name: name
  act: (me, status) ->
    if me.minToCall
      me.minToCall
    else
      0
