local Boid = {
	AddedRadiusInfluence = 0,
	AlignInfluence = 1,
	CohesInfluence = 1,
	SepInfluence = 1,
	
	Radius = 20,
	Align = 2,
	Cohes = 5,
	Sep = 0.02,
	Speed = 40,
	Acceleration = 50,
	Deceleration = 0.01,
	Noise = 0.1,
	NoiseFrequency = 0.5,
	SteerLength = 12,
	Steer = 20,
}
Boid.__index = Boid

local SunFlowerPoints = require(game.ReplicatedFirst:WaitForChild("Shared"):WaitForChild("SunFlowerPoints"))

function Boid.new(position)
	local self = setmetatable({
		Running = true,-- whether or not to have its velocity changed via :Update
		
		Position = position,
		Velocity = Vector3.zero,
		CFrame = CFrame.new(position),
		
		_destroyed = false,
		
		_follow = {},
		_following = 0,
		_factoryId = 0,
	}, Boid)
	
	return self
end

function Boid:_setFactoryId(id)
	self._factoryId = id
end

function Boid:GetFactoryId()
	return self._factoryId
end

function Boid:IsDestroyed()
	return self._destroyed
end

function Boid:Destroy()
	self._destroyed = true
	if self.Part then
		self.Part:Destroy()
	end
end

function Boid:SetInfluence(radius, align, cohes, sep)
	self.AddedRadiusInfluence = radius
	self.AlignInfluence = align
	self.CohesInfluence = cohes
	self.SepInfluence = sep
end

function Boid:SetRayParams(params)
	self._rayParams = params
end

function Boid:SetParams(radius, align, cohes, sep, speed, accel, decel, noise, noiseFreq, steerL, steer)
	self.Radius = radius
	self.Align = align
	self.Cohes = cohes
	self.Sep = sep
	self.Speed = speed
	self.Acceleration = accel
	self.Deceleration = decel
	self.Noise = noise
	self.NoiseFrequency = noiseFreq
	self.SteerLength = steerL
	self.Steer = steer
end

-- all boids will run this, #1
function Boid:_preUpdate(deltaTime)
	self._follow = {}
	self._following = 0
end

-- then all boids will run this, #2
function Boid:_storeNearby(others)
	local position = self.Position
	
	for _, otherBoid in others do
		if otherBoid == self then
			continue
		end
		
		local otherPosition = otherBoid.Position
		local offset = position - otherPosition
		local dist = math.max(offset.Magnitude - otherBoid.AddedRadiusInfluence, 0.1)
		
		if dist <= self.Radius then
			self._follow[otherBoid] = dist
			self._following += 1
		end
	end
end

function Boid:GetRulesAffect(hash)
	local avgVelocity = Vector3.zero
	local centerOfMass = Vector3.zero
	local alignWeight = 0
	local cohesiveWeight = 0
	local sep = Vector3.zero
	
	local position, velocity = self.Position, self.Velocity
	
	-- influence on self
	for otherBoid, distance in hash do
		-- alignment
		avgVelocity += otherBoid.Velocity * otherBoid.AlignInfluence
		alignWeight += otherBoid.AlignInfluence
		
		-- cohesion
		centerOfMass += otherBoid.Position * otherBoid.CohesInfluence
		cohesiveWeight += otherBoid.CohesInfluence
		
		-- separation
		local matchVector = position - otherBoid.Position
		local matchMagnitude = distance / self.Radius
		if matchMagnitude > 0 then
			local directionVector = matchVector / matchMagnitude^2
			sep += directionVector * otherBoid.SepInfluence
		end
	end
	
	local alignment = Vector3.zero
	if alignWeight > 0 then
		avgVelocity /= alignWeight
		
		if avgVelocity.Magnitude > 0 then
			local matchVector = avgVelocity - velocity
			local directionVector = matchVector.Unit
			if directionVector == directionVector then
				alignment = directionVector * self.Align
			end
		end
	end
	
	local cohesion = Vector3.zero
	if cohesiveWeight > 0 then
		centerOfMass /= cohesiveWeight

		local matchVector = centerOfMass - position
		local directionVector = matchVector.Unit
		if directionVector == directionVector then
			cohesion = directionVector * self.Cohes
		end
	end
	
	local separation = sep * self.Sep
	
	local totalRules = alignment + cohesion + separation
	
	return totalRules
end

local points = SunFlowerPoints.getPoints(10, nil, function(x, y)
	return CFrame.Angles(x*math.pi/4, y*math.pi/4, 0)
end)

function Boid:SteerAffect()
	local vel = self.Velocity
	if vel.Magnitude == 0 then
		return Vector3.zero
	end
	
	local steer = self.Steer
	local rr = workspace:Raycast(self.Position, vel.Unit * self.SteerLength, self._rayParams)
	
	if rr then
		steer /= (rr.Distance/self.SteerLength) ^ 2
		
		local cf = CFrame.new(self.Position, self.Position + vel)
		local sum = Vector3.zero
		local sumWeight = 0
		
		for _, point in points do
			local look = (cf * point).LookVector
			local rr2 = workspace:Raycast(self.Position, look * self.SteerLength, self._rayParams)
			local weight = (not rr2) and self.SteerLength or rr2.Distance
			sum += look * weight
			sumWeight += weight
		end
		
		return sum / sumWeight * steer
	end
	
	return Vector3.zero
end

function isPointInVolume(point: Vector3, volumeCenter: CFrame, volumeSize: Vector3): boolean
    local volumeSpacePoint = volumeCenter:PointToObjectSpace(point)
    return volumeSpacePoint.X >= -volumeSize.X/2
        and volumeSpacePoint.X <= volumeSize.X/2
        and volumeSpacePoint.Y >= -volumeSize.Y/2
        and volumeSpacePoint.Y <= volumeSize.Y/2
        and volumeSpacePoint.Z >= -volumeSize.Z/2
        and volumeSpacePoint.Z <= volumeSize.Z/2
end

function isPointInPart(point: Vector3, part: BasePart): boolean
    return isPointInVolume(point, part.CFrame, part.Size)
end

-- finally all boids will run this, #3
function Boid:Update(deltaTime)
	if not self.Running then
		return
	end
	
	-- followList boids will influence us via Influence Params and we will respond to it via Follow Params
	local affect = self:GetRulesAffect(self._follow)
	
	local nx = math.noise(tick() % 1000000 * self.NoiseFrequency, 100, self._factoryId * 10)
	local ny = math.noise(tick() % 1000000 * self.NoiseFrequency, 200, self._factoryId * 10)
	local nz = math.noise(tick() % 1000000 * self.NoiseFrequency, 300, self._factoryId * 10)
	local noiseAffect = Vector3.new(nx, ny, nz).Unit * math.min(self.Speed, affect.Magnitude)
	
	if noiseAffect == noiseAffect then
		affect = affect:Lerp(noiseAffect, self.Noise)
	end
	
	affect += self:SteerAffect()
	
	local curVelocity = self.Velocity
	affect = (affect - self.Velocity * self.Deceleration) * (deltaTime * self.Acceleration)
	local newVelocity = curVelocity + affect
	
	newVelocity = newVelocity.Unit * self.Speed
	
	if newVelocity ~= newVelocity then
		newVelocity = Vector3.zero
	end
	
	self.Velocity = newVelocity
	self.Position += self.Velocity * deltaTime
	
	local look = newVelocity
	if look.Magnitude == 0 then
		look = self.CFrame.LookVector
	end
	self.CFrame = self.CFrame:Lerp(CFrame.new(self.Position, self.Position + look), deltaTime * 20)
	
	if self.Part then
		local freq, scale = 50/self.Part.Size.Z, math.pi/13
		local cycle = math.sin(tick()*freq) * scale
		self.Part.CFrame = self.CFrame * CFrame.Angles(0, cycle, 0) * CFrame.new(0, 0, self.Part.Size.Z/2) 
	end
	
	if not isPointInPart(self.Position, workspace:WaitForChild("BoidRegion")) then
		self:Destroy()
	end
end

function Boid:AssignPart(part)
	self.Part = part
end

return Boid