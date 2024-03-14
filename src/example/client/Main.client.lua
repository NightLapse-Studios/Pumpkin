local DebugMenu = require(game.ReplicatedFirst.DebugMenuEx)

DebugMenu.RegisterSlider("Some Slider", 50, 0, 100, 0.5, nil, function(v)
	print(v)
end)