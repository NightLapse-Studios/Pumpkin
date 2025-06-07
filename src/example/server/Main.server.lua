local DebugMenu = require(game.ReplicatedFirst.DebugMenu)

DebugMenu.RegisterButton("Press", "Server", function(a)
	print("Server", a)
end)
