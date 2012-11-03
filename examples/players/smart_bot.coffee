module.exports = (name) ->
  name: name
  update: (game) ->
    # Only play the good hands
    return false if game.state == 'complete'
    self = game.self
    if game.state == 'pre-flop'
      # Paired
      if self.cards[0][0] == self.cards[1][0]
        if ['A','K','Q','J'].indexOf(self.cards[0][0]) >= 0
          game.betting.raise * 10
        else
          game.betting.call
      else if ['A','K'].indexOf(self.cards[0][0]) >= 0
        game.betting.call
      else
        0
    else
      game.betting.call
