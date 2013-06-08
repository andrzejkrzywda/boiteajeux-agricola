boiteajeux-agricola
===================

A library that helps accessing the current state of games at the boiteajeux.net Agricola server
Note: The boiteajeux.net authors do a really good work for all of us, board game geeks. Please, don't use this code to
access the servers too often.

The html scrapping code is stolen from https://github.com/nthx/boiteajeux-email-notifier - thanks!

It's not ready to anything yet.

# The (planned) usage

game = Agricola::Boiteajeux::GameRetriever.new(ID)
game.nicks
game.moves
