local BoidGroup = require(script:WaitForChild("BoidGroup"))

local BoidService = {}
BoidService.__index = BoidService

function BoidService.new()
	local self = setmetatable({
		_groupings = {}
	}, BoidService)
	
	return self
end

-- Groupings cannot interact with each other.
function BoidService:RegisterGrouping(name)
	if self._groupings[name] then
		error("Double register of Boid Group: " .. name)
	end
	
	self._groupings[name] = BoidGroup.new()
end

function BoidService:DeregisterGrouping(name)
	local group = self._groupings[name]
	if group then
		group:Destroy()
	end
end

-- Returns a new boid
function BoidService:AddBoid(groupName, position, boidParams)
	if not self._groupings[groupName] then
		self:RegisterGrouping(groupName)
	end
	
	local boid = self._groupings[groupName]:AddBoid(position, boidParams)
	return boid
end

function BoidService:GetBoidFromId(groupName, id)
	return self._groupings[groupName]._boids[id]
end

function BoidService:GetBoids(groupName)
	return self._groupings[groupName]._boids
end

function BoidService:GetGroups()
	return self._groupings
end

function BoidService:Update(deltaTime)
	for _, group in self._groupings do
		group:Update(deltaTime)
	end
end

return BoidService.new()