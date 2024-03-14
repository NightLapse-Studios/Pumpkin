local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)

local noop = function() end

local BaseMotor = {}
BaseMotor.__index = BaseMotor

local motors = {}
local lastid = 0

function BaseMotor.new()
	lastid += 1
	return setmetatable({
		_onStep = Signal.new(),
		_onStart = Signal.new(),
		_onComplete = Signal.new(),
		id = lastid,
	}, BaseMotor)
end

function BaseMotor:onStep(handler)
	return self._onStep:connect(handler)
end

function BaseMotor:onStart(handler)
	return self._onStart:connect(handler)
end

function BaseMotor:onComplete(handler)
	return self._onComplete:connect(handler)
end

function BaseMotor:start()
	if not self._connection then
		motors[self.id] = self
		self._connection = true
	end
end

function BaseMotor:stop()
	self._connection = false
	motors[self.id] = nil
end

BaseMotor.destroy = BaseMotor.stop

BaseMotor.step = noop
BaseMotor.getValue = noop
BaseMotor.setGoal = noop

function BaseMotor:__tostring()
	return "Motor"
end

if RunService:IsClient() then
	RunService.RenderStepped:Connect(function(deltaTime)
		for i, self in pairs(motors) do
			if self._connection then
				self:step(deltaTime)
			end
		end
	end)
end

return BaseMotor
