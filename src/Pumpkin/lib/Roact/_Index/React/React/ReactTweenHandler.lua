local RunService = game:GetService("RunService")
local mod = {}

local playingSequences = {}
setmetatable(playingSequences, {__mode = "v"})

local lastPlayId = 0

function mod.playSequence(binding)
	for i,v in pairs(playingSequences) do
		if v == binding then
			return
		end
	end
	
	lastPlayId += 1
	playingSequences[lastPlayId] = binding
	
	return lastPlayId
end

function mod.stopSequence(playID)
	if not playID then
		return
	end

	local binding = playingSequences[playID]
	binding:reset()

	assert(binding, "Attempt to stop tween sequence that isn't running")
	playingSequences[playID] = nil
	binding.PlayID = false
end

function mod.updateSequence(playId)
	local binding = playingSequences[playId]
	if not binding then
		return
	end
	
	local currentSequenceIndex = binding.currentSequenceIndex
	local sequence = binding.sequence
	local motor = binding.motor
	
	local key = sequence[currentSequenceIndex]
	-- print("KEY; ", key)
	if not key then
		binding.AtEndOfSequence = true
		return
	else
		binding.AtEndOfSequence = false
	end
	
	if binding.paused then
		binding.holdPause = tick() - binding.paused
		--print("Paused")
		return
	elseif binding.holdPause then
		if key.TickEnd then
			key.TickEnd += binding.holdPause
		end
		binding.holdPause = nil
	end
	
	if key.Target then
		--print("target")
		if motor._connection then
			--print("Connection")
			if motor._state.complete then
				--print("Complete")
				motor:stop()
				binding.currentSequenceIndex += 1
			end
		else
			--print("setting goals")
			motor:setGoal(key.Target)
			motor:start()
		end
	elseif key.RepeatAll then
		if key.Counter == 0 then
			binding.currentSequenceIndex += 1
		elseif key.Counter <= -1 or key.Counter > 0 then
			key.Counter -= 1
			for i = 1, currentSequenceIndex - 1 do
				local thiskey = sequence[i]
				if thiskey.Counter then
					thiskey.Counter = thiskey.RepeatThis or thiskey.RepeatAll
				end
				thiskey.TickEnd = nil
			end
			motor:reset()
			binding.currentSequenceIndex = 1
		end
	elseif key.RepeatThis then
		if key.Counter == 0 then
			binding.currentSequenceIndex += 1
		elseif key.Counter <= -1 or key.Counter > 0 then
			key.Counter -= 1
			
			sequence[currentSequenceIndex - 1].TickEnd = nil
			
			motor:reset()
			binding.currentSequenceIndex -= 1
		end
	elseif key.Pause then
		if key.TickEnd then
			if tick() > key.TickEnd then
				binding.currentSequenceIndex += 1
			end
		else
			key.TickEnd = tick() + key.Pause
		end
	end
end

if RunService:IsClient() then
	RunService.RenderStepped:Connect(function()
		for playId, binding in pairs(playingSequences) do
			mod.updateSequence(playId)
		end
	end)
end

return mod