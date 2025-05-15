
What programming patterns did I use, how did I use them, and why?

I’m really happy with how the game turned out: I used the Flyweight pattern to load all 52 card images just once into a cards[suit][value] table so drawing is a quick lookup, the Prototype pattern in CardClass:new() to give every card the same setup while letting each one keep its own state, and a simple State pattern to run the right code during dealing, playing, and win-checking. I lean on LÖVE’s built-in love.load, love.update, and love.draw for sequencing, call updateCardPositions() as an update-method to slide cards into place after every move, keep RANK_VALUES, RED_SUITS, and BLACK_SUITS in Type-Object tables instead of hard-coding rules, and split everything into card.lua, pile.lua, deck.lua, and grabber.lua as components so each file handles just one job.

Who gave me feedback, what feedback did they give, and how did I adjust my code?

Koushik Vasa suggested adding header comments to functions like drawCardsFromStock and splitting long functions into smaller parts. I added a comment block at the top of main.lua, added comments above key functions, and broke love.mousepressed into helper functions.Varsana Illango pointed out that asset loading might be better in its own module and that docstrings would help. I moved loadCardImages() into a new assets.lua file and added simple LuaDoc-style comments above updateCardPositions(). Varun reported that the game crashed when shuffling cards. I added a check in DeckClass:shuffle() to only shuffle a full deck, and I wrapped shuffle calls in a pcall guard so missing cards won’t crash the game.

Postmortem: what were the key pain points, how did I plan to fix them, and how did that go?

My main pain points were a very long main.lua, missing error checks for shuffling, and inefficient position updates. I planned to split code into modules—like moving asset and state logic out of main.lua—and to add guards around shuffle and position functions. After refactoring, main.lua is now under 400 lines and focuses on flow, asset loading lives in assets.lua, and I only recalc card positions when piles change instead of every frame. The game no longer crashes on shuffle, and performance feels smoother on large piles.I made two buttons with a reset and undo button.

Assets:
For art I used Kenney’s Playing Cards Pack (https://kenney.nl/assets/playing-cards-pack) and stuck with the built-in 14 pt font—no sounds or extra effects

 