local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local currentCamera = workspace.CurrentCamera

local Boids = require(ReplicatedFirst.Shared.BoidsService)

local boidSteerParams = RaycastParams.new()
boidSteerParams.FilterType = Enum.RaycastFilterType.Include
boidSteerParams.FilterDescendantsInstances = {workspace:WaitForChild("Include")}

local spawnParams = RaycastParams.new()
spawnParams.FilterType = Enum.RaycastFilterType.Include
spawnParams.FilterDescendantsInstances = {workspace:WaitForChild("Include")}

local mouseRayResult = nil

local boidsFolder = Instance.new("Folder", workspace)
boidsFolder.Name = "Boids"

local function makePart(pos, size, color)
	local vis = Instance.new("Part")
	vis.Size = size
	vis.Color = Color3.fromHSV(math.random(), 1, 1)
	vis.Anchored = true
	vis.CanCollide = false
	vis.Material = Enum.Material.SmoothPlastic
	vis.Position = pos
	vis.Parent = boidsFolder
	return vis
end

local function map(value, oldMin, oldMax, newMin, newMax)
    local oldSpan = oldMax - oldMin
    local newSpan = newMax - newMin

    local valueScaled = (value - oldMin) / (oldSpan)

    return newMin + (valueScaled * newSpan)
end

local function spawnBoid(position, size, color)
	local boid = Boids:AddBoid("Boids_1", position)
	boid:SetRayParams(boidSteerParams)
	boid:AssignPart(makePart(boid.Position, size, color))
	
	local mult = size.Y * size.Z - size.X
	boid:SetInfluence(map(mult, 0.2, 23, 0, 9), nil, nil, nil)
	boid:SetParams(nil, nil, nil, nil, map(mult, 0.2, 23, 40, 30), nil)
end

local function getBoidData(pos)
	local rp = Vector3.new(math.random() * 0.5, math.random() * 0.5, math.random() * 0.5)
	local rs = Vector3.new(math.random() * (1 - 0.2) + 0.2, math.random() * (3 - 0.2) + 0.2, math.random() * (8 - 2) + 2)
	local rc = Color3.fromHSV(math.random(), 1, 1)
	return pos + Vector3.yAxis * 3 + rp, rs, rc
end

RunService.RenderStepped:Connect(function(dt)
	local mousePosition = UserInputService:GetMouseLocation()
	local ray = currentCamera:ScreenPointToRay(mousePosition.X, mousePosition.Y)
	
	mouseRayResult = workspace:Raycast(ray.Origin, ray.Direction * 150, spawnParams)
	
	Boids:Update(dt)
	
	local char = game.Players.LocalPlayer.Character
	if char then
		local headPos = char:WaitForChild("Head").Position
		
		for _, v in workspace:WaitForChild("Lookers"):GetChildren() do
			local neck = v:WaitForChild("Torso"):WaitForChild("Neck")
			local ogNeckC1 = neck:FindFirstChild("OG")
			if not ogNeckC1 then
				ogNeckC1 = Instance.new("CFrameValue", neck)
				ogNeckC1.Name = "OG"
				ogNeckC1.Value = neck.C1
			end
			ogNeckC1 = ogNeckC1.Value
			
			local delta = headPos - (neck.Part1.CFrame * neck.C1).Position
			local x, y = CFrame.lookAt(Vector3.zero, delta):ToEulerAnglesYXZ()
			neck.C1 = ogNeckC1 * CFrame.Angles(x, 0, -y + math.pi)
		end
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and mouseRayResult then
		for i = 1, 10 do
			spawnBoid(getBoidData(mouseRayResult.Position))
		end
	end
end)

task.delay(3, function()
	local r = workspace:WaitForChild("BoidRegion")
	for i = 1, 20 do
		local rp = r.Position - r.Size/2 + (r.Size * Vector3.new(math.random(), math.random(), math.random()))
		spawnBoid(getBoidData(rp))
		spawnBoid(getBoidData(rp))
	end
end)
