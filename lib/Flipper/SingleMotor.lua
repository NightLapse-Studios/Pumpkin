local BaseMotor = require(script.Parent.BaseMotor)

local SingleMotor = setmetatable({}, BaseMotor)
SingleMotor.__index = SingleMotor

function SingleMotor.new(initialValue, useImplicitConnections)
	assert(initialValue, "Missing argument #1: initialValue")
	assert(typeof(initialValue) == "number", "initialValue must be a number!")

	local self = setmetatable(BaseMotor.new(), SingleMotor)

	if useImplicitConnections ~= nil then
		self._useImplicitConnections = useImplicitConnections
	else
		self._useImplicitConnections = true
	end
	
	self._initialValue = initialValue
	self._goal = nil
	self._state = {
		complete = true,
		value = initialValue,
	}

	return self
end


function SingleMotor:step(deltaTime)
	if self._state.complete then
		return true
	end
	
	if not self._goal then
		return false
	end
	
	local newState = self._goal:step(self._state, deltaTime)

	self._state = newState
	self._onStep:fire(newState.value)

	if newState.complete then
		if self._useImplicitConnections then
			self:stop()
		end

		self._onComplete:fire()
	end

	return newState.complete
end

function SingleMotor:getValue()
	return self._state.value
end

function SingleMotor:setGoal(goal)
	self._state.complete = false
	self._goal = goal

	self._onStart:fire()

	if self._useImplicitConnections then
		self:start()
	end
end

function SingleMotor:reset()
	self._onStep:fire(self._initialValue)
	
	self:stop()
	
	self._goal = nil
	self._state = {
		complete = false,
		value = self._initialValue,
	}
end

function SingleMotor:jump()
	local target = self:getGoal()
	self._onStep:fire(target)
	
	self:stop()
	
	self._goal = nil
	self._state = {
		complete = false,
		value = target,
	}
end

function SingleMotor:getGoal()
	return self._goal._targetValue
end

return SingleMotor
