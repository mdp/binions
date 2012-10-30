module.exports = (name) ->
  name: name
  update: (game) ->
    # Only play the good hands
    return false if game.state == 'complete'
    me = game.me
    if game.state == 'pre-flop'
      # Paired
      if me.cards[0][0] == me.cards[1][0]
        if ['A','K','Q','J'].indexOf(me.cards[0][0]) >= 0
          game.betting.raise * 10
        else
          game.betting.call
      else if ['A','K'].indexOf(me.cards[0][0]) >= 0
        game.betting.call
      else
        0
    else
      game.betting.call
