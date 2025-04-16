local Boid = require(script:WaitForChild("Boid"))

local BoidGroup = {}
BoidGroup.__index = BoidGroup

function BoidGroup.new()
	local self = setmetatable({
		_numBoids = 0,
		_numBoidsMade = 0,
		
		_boids = {},
	}, BoidGroup)
	
	return self
end

-- Returns a new boid
function BoidGroup:AddBoid(position, boidParams)
	local boid = Boid.new(position, boidParams)

	self._numBoids += 1
	self._numBoidsMade += 1
	
	self._boids[self._numBoidsMade] = boid
	boid:_setFactoryId(self._numBoidsMade)
	
	return boid
end

function BoidGroup:_removedBoid(id)
	self._numBoids -= 1
	self._boids[id] = nil
end

function BoidGroup:Destroy()
	for id, boid in self._boids do
		boid:Destroy()
		self:_removedBoid(id)
	end
end

function BoidGroup:Update(deltaTime)
	for id, boid in self._boids do
		if boid:IsDestroyed() then
			self:_removedBoid(id)
		else
			boid:_preUpdate(deltaTime)
		end
	end
	
	for id, boid in self._boids do
		boid:_storeNearby(self._boids)
	end
	
	for id, boid in self._boids do
		boid:Update(deltaTime)
	end
end

return BoidGroup