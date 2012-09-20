module.exports = (name) ->
  name: name
  act: (me, status) ->
    if me.wagered < me.minToCall
      status.minToCall - me.wagered
    else
      0
