#Refactoring

MatchViewController should drop the player:Int property for step:Int, which maps as such:
	- 0 ..< numPlayers -> sets active player
	- numPlayers -> presents final drawing
	- numPlayers+1 shows the save dialog and exits
