local DebugMenu = script.Parent:WaitForChild("DebugMenuEx")

while #DebugMenu:GetChildren() < 6 do
	task.wait()
end

DebugMenu = require(DebugMenu)
DebugMenu.RegisterSlider("Some Slider", 50, 0, 100, 0.5, nil, function(v)
	print(v)
end)