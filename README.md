# Hellmuth
## A javascript poker tournament/game engine

## Running a game

require 'hellmuth'

## Requirements

### JS Sandbox 

Figure out how to safely run JS code from contestants.

- Stop access to globals
- No require (No ability to require a file system module or network)
- Need a way to measure speed and stop slow bots(What's a good limit, 1000ms), fold/check on timeout
- Prevent errors, fold on error.
- Require certain attributes: Name
- Network layer provided, your bot simply has to respond to a game
  object
- Prevent setTimeout
- Run in seperate process, handle excess memory usage, process exceptions, timeouts

### Game

- No limit Texas Hold'em

### Frontend

- Need live updating scoreboard.
- Live stats, each player, hands folded, pots one, raises

### Bots

- Build a sample bot for testing

