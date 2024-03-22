local Pumpkin = require(game.ReplicatedFirst.Pumpkin)
local I, P, Roact = Pumpkin, Pumpkin.P, Pumpkin.Roact

local DebugMenu = require(game.ReplicatedFirst.DebugMenu)

DebugMenu.RegisterSlider("Some Slider", 50, 0, 100, 0.5, nil, function(v)
	print(v)
end)



local TestTween = I:Tween(0)

local tween_test_tree = I:TextButton(P()
	:Size(0, 100, 0, 30)
	:Text("Tween test")
	:JustifyLeft(0, 10)
	:Rotation(TestTween:map(function(v)
		return v * 360 * .05
	end))
	:Activated(function()
		TestTween:spring(1, 1, 2):spring(0, 3, 3)
	end)
)




local sgui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))

I:Mount(tween_test_tree, sgui)
