local createSignal = require(script.Parent.createSignal)
local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)
local Flipper = require(game.ReplicatedFirst.Lib.Flipper)
local RoactTweenHandler = require(script.Parent.RoactTweenHandler)

local config = require(script.Parent.GlobalConfig).get()

local BindingImpl = Symbol.named("BindingImpl")

local BindingInternalApi = {}

local bindingPrototype = {}

function bindingPrototype:getValue()
	return BindingInternalApi.getValue(self)
end

function bindingPrototype:map(predicate)
	return BindingInternalApi.map(self, predicate)
end

function bindingPrototype:subscribe(callback)
	return BindingInternalApi.subscribe(self, callback)
end


local function tween(self)
	local impl = self[BindingImpl]
	
	local motor = Flipper.SingleMotor.new(impl.value, false)
	motor:onStep(impl.update)
		
	local newTween = {
		sequence = {},
		motor = motor,
		currentSequenceIndex = 1,
		AtEndOfSequence = false,
	}
	
	if not impl.tweens then
		impl.tweens = setmetatable({},{__mode = "v"})
	end
	
	table.insert(impl.tweens, newTween)
	
	setmetatable(newTween, {
		__index = self,
	})
	
	return newTween
end

function bindingPrototype:getTween()
	return tween(self)
end

function bindingPrototype:linear(target, speed)
	local new = false
	if not self.motor then
		self = tween(self)
		new = true
	end
	
	local goal = Flipper.Linear.new(target, {velocity = speed})
	self.sequence[#self.sequence + 1] = {
		Target = goal,
	}
	
	if new then
		if self[BindingImpl].isAttached then
			self.PlayID = RoactTweenHandler.playSequence(self)
		end
	end
	
	return self
end

function bindingPrototype:instant(target)
	local new = false
	if not self.motor then
		self = tween(self)
		new = true
	end
	
	local goal = Flipper.Instant.new(target)
	self.sequence[#self.sequence + 1] = {
		Target = goal,
	}
	
	if new then
		if self[BindingImpl].isAttached then
			self.PlayID = RoactTweenHandler.playSequence(self)
		end
	end
	
	return self
end

function bindingPrototype:spring(target, frequency, dampingRatio)
	local new = false
	if not self.motor then
		self = tween(self)
		new = true
	end
	
	local goal = Flipper.Spring.new(target, {frequency = frequency, dampingRatio = dampingRatio})
	self.sequence[#self.sequence + 1] = {
		Target = goal,
	}
	
	if new then
		if self[BindingImpl].isAttached then
			self.PlayID = RoactTweenHandler.playSequence(self)
		end
	end
	
	return self
end

function bindingPrototype:repeatAll(count)
	self.sequence[#self.sequence+1] = {
		RepeatAll = count,
		Counter = count,
	}
	return self
end

function bindingPrototype:repeatThis(count)
	self.sequence[#self.sequence+1] = {
		RepeatThis = count,
		Counter = count,
	}
	return self
end

function bindingPrototype:reset()
	for i = 1, #self.sequence do
		local key = self.sequence[i]
		if key.Counter then
			key.Counter = key.RepeatThis or key.RepeatAll
		end
		key.TickEnd = nil
	end
	self.motor:reset()
	self.currentSequenceIndex = 1
	
	return self
end

function bindingPrototype:pause(t)
	if not t then
		self.paused = tick()
		self.motor:stop()
	else
		self.sequence[#self.sequence+1] = {
			Pause = t,
			TickEnd = nil,
		}
	end
	
	return self
end

function bindingPrototype:resume()
	self.motor:start()
	self.paused = nil
	
	return self
end

function bindingPrototype:wipe()
	self.sequence = {}
	self.motor:reset()
	self.currentSequenceIndex = 1
	self.paused = nil
	self.holdPause = nil
	self.AtEndOfSequence = false
	
	return self
end

function bindingPrototype:skip()
	-- will pick up where the motor value is currently at
	
	if self.sequence[self.currentSequenceIndex] then
		self.motor:stop()
		table.remove(self.sequence, self.currentSequenceIndex)
	end
	
	return self
end

function bindingPrototype:jump()
	-- will pick up at the current target of the motor value
	
	local seqKey = self.sequence[self.currentSequenceIndex]
	if seqKey then
		if seqKey.Target and self.motor._goal then
			self.motor:jump()
		end
		table.remove(self.sequence, self.currentSequenceIndex)
		
		-- allows for the next step to start instantly incase we call jump again immediately after, it actually does something.
		RoactTweenHandler.updateSequence(self.PlayID)
	end
	
	return self
end


local BindingPublicMeta = {
	__index = bindingPrototype,
	__tostring = function(self)
		return string.format("RoactBinding(%s)", tostring(self:getValue()))
	end,
}

function BindingInternalApi.update(binding, newValue)
	return binding[BindingImpl].update(newValue)
end

function BindingInternalApi.subscribe(binding, callback)
	return binding[BindingImpl].subscribe(callback)
end

function BindingInternalApi.getValue(binding)
	return binding[BindingImpl].getValue()
end

function BindingInternalApi.create(initialValue)
	local impl = {
		value = initialValue,
		changeSignal = createSignal(),
		isAttached = false
	}
	
	local self
	
	function impl.attached(value)
		impl.isAttached = value
		
		if impl.tweens then
			for i,v in pairs(impl.tweens) do
				if value then
					v.PlayID = RoactTweenHandler.playSequence(v)
				else
					RoactTweenHandler.stopSequence(v)
				end
			end
		end
	end

	function impl.subscribe(callback)
		return impl.changeSignal:subscribe(callback)
	end

	function impl.update(newValue)
		impl.value = newValue
		impl.changeSignal:fire(newValue)
	end

	function impl.getValue()
		return impl.value
	end
	
	self = setmetatable({
		[Type] = Type.Binding,
		[BindingImpl] = impl,
		update = impl.update,
	}, BindingPublicMeta)
	
	return self, impl.update
end

function BindingInternalApi.map(upstreamBinding, predicate)
	if config.typeChecks then
		assert(Type.of(upstreamBinding) == Type.Binding, "Expected arg #1 to be a binding")
		assert(typeof(predicate) == "function", "Expected arg #1 to be a function")
	end

	local impl = {
		isAttached = false
	}

	function impl.attached(value)
		impl.isAttached = value
		upstreamBinding[BindingImpl].attached(value)
	end

	function impl.subscribe(callback)
		return BindingInternalApi.subscribe(upstreamBinding, function(newValue)
			callback(predicate(newValue))
		end)
	end

	function impl.update(newValue)
		error("Bindings created by Binding:map(fn) cannot be updated directly", 2)
	end

	function impl.getValue()
		return predicate(upstreamBinding:getValue())
	end

	return setmetatable({
		[Type] = Type.Binding,
		[BindingImpl] = impl,
	}, {
		__index = upstreamBinding,
	})
end

function BindingInternalApi.join(upstreamValues)
	if config.typeChecks then
		assert(typeof(upstreamValues) == "table", "Expected arg #1 to be of type table")

		for key, value in pairs(upstreamValues) do
			if Type.of(value) ~= Type.Binding then
				local message = (
					"Expected arg #1 to contain only bindings, but key %q had a non-binding value"
				):format(
					tostring(key)
				)
				error(message, 2)
			end
		end
	end
	
	local upstreamBindings = {}
	local thisUpstreamValues = {}
	
	for i,v in upstreamValues do
		if Type.of(v) == Type.Binding then
			upstreamBindings[i] = v
		else
			thisUpstreamValues[i] = v
		end
	end
	
	local impl = {
		isAttached = false
	}
	
	function impl.attached(value)
		impl.isAttached = value
		for key, upstream in pairs(upstreamBindings) do
			upstream[BindingImpl].attached(value)
		end
	end

	local function getValue()
		local value = {}

		for key, upstream in pairs(upstreamBindings) do
			value[key] = upstream:getValue()
		end
		
		for key, v in pairs(thisUpstreamValues) do
			value[key] = v
		end

		return value
	end

	function impl.subscribe(callback)
		local disconnects = {}

		for key, upstream in pairs(upstreamBindings) do
			disconnects[key] = BindingInternalApi.subscribe(upstream, function(newValue)
				callback(getValue())
			end)
		end

		return function()
			if disconnects == nil then
				return
			end

			for _, disconnect in pairs(disconnects) do
				disconnect()
			end

			disconnects = nil
		end
	end

	function impl.update(newValue)
		error("Bindings created by joinBindings(...) cannot be updated directly", 2)
	end

	function impl.getValue()
		return getValue()
	end

	return setmetatable({
		[Type] = Type.Binding,
		[BindingImpl] = impl,
	}, BindingPublicMeta)
end

BindingInternalApi.BindingImpl = BindingImpl

return BindingInternalApi