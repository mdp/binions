module.exports = (name) ->
  name: name
  act: (me, status) ->
    # Only play the good hands
    if status.state == 'pre-flop'
      # Paired
      if me.cards[0][0] == me.cards[1][0]
        if ['A','K','Q','J'].indexOf(me.cards[0][0]) >= 0
          me.minToRaise * 10
        else
          me.minToCall
      else if ['A','K'].indexOf(me.cards[0][0]) >= 0
        me.minToCall
      else
        0
    else
      me.minToCall
