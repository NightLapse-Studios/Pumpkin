local Pumpkin = require(game.ReplicatedFirst.Pumpkin)
local I, P, Roact = Pumpkin, Pumpkin.P, Pumpkin.Roact

local DebugMenu = require(game.ReplicatedFirst.DebugMenu)

DebugMenu.RegisterSlider("Slider", 50, 0, 100, 0.5, nil, function(v)
	print(v)
end)
 
DebugMenu.RegisterButton("Press", nil, function(a)
	print("Client", a)
end)

DebugMenu.RegisterToggle("Toggle", true, nil, function(a)
	print(a)
end)

DebugMenu.RegisterColor("Color", Color3.new(1,0,0), nil, function(a)
	print(a)
end)

DebugMenu.RegisterText("Text", "ababa", nil, function(a)
	print(a)
end)

local TestTween = I:Tween(0)

local tween_test_tree = I:Frame(P()
	:Size(1, 0, 1, 0)
	:Invisible()
	:Children(
		I:TextButton(P()
			:Size(0, 100, 0, 30)
			:Text("Tween test")
			:JustifyRight(0.25, 0)
			:Rotation(TestTween:map(function(v)
				return v * 360 * .05
			end))
			:Activated(function()
				TestTween:wipe():spring(1, 3, 1):spring(0, 3, 3)
			end)
		)
	)
)

local sgui = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
sgui.Name = "OtherTests"

I:Mount(tween_test_tree, sgui)
