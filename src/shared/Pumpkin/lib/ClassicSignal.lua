local Connection = {}
Connection.__index = Connection

function Connection.new(signal, handler)
	return setmetatable({
		signal = signal,
		connected = true,
		_handler = handler,
	}, Connection)
end

function Connection:Disconnect()
	if self.connected then
		self.connected = false

		for index, connection in pairs(self.signal._connections) do
			if connection == self then
				table.remove(self.signal._connections, index)
				return
			end
		end
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_connections = {},
		_threads = {},
		
		FireCount = 0,
	}, Signal)
end

function Signal:Fire(...)
	self.FireCount += 1
	
	for _, connection in pairs(self._connections) do
		task.spawn(connection._handler, ...)
	end

	for _, thread in pairs(self._threads) do
		coroutine.resume(thread, ...)
	end

	self._threads = {}
end

function Signal:Connect(handler)
	local connection = Connection.new(self, handler)
	table.insert(self._connections, connection)
	return connection
end

function Signal:Wait(timeout)
	if timeout then
		local signal = Signal.new()
		local conn = nil
		conn = self:Connect(function(...)
			conn:Disconnect()
			conn = nil
			signal:Fire(...)
		end)
	
		task.delay(timeout, function()
			if (conn ~= nil) then
				conn:Disconnect()
				conn = nil
				signal:Fire(nil)
			end
		end)
	
		return signal:Wait()
	else
		table.insert(self._threads, coroutine.running())
		return coroutine.yield()
	end
end

return Signal