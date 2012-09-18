class exports.AllInSlim
  constructor: (@name) ->

  act: (status) ->
    console.log JSON.stringify status, null, 1
    status.player.chips
