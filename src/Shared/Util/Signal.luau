--!strict
local freeRunnerThread = nil

local function acquireRunnerThreadAndCall(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCall(...)
	while true do
		acquireRunnerThreadAndCall(coroutine.yield())
	end
end

local Connection = {}
Connection.__index = Connection

type Connection<T...> = {
	Connected: boolean,
	Disconnect: (self: Connection<T...>) -> (),
}

function Connection.new(signal: any, fn: (...any) -> ())
	return setmetatable({
		_signal = signal,
		_fn = fn,
		_next = nil,
		Connected = true,
	}, Connection)
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false
	
	local signal = self._signal
	if signal._head == self then
		signal._head = self._next
	else
		local prev = signal._head
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
	
	self._signal = nil
	self._fn = nil
	self._next = nil
end

local Signal = {}
Signal.__index = Signal

export type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection<T...>,
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> T...,
	Once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection<T...>,
	DisconnectAll: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

function Signal.new()
	return setmetatable({
		_head = nil,
	}, Signal)
end

function Signal:Connect(fn)
	local connection = Connection.new(self, fn)
	if self._head then
		connection._next = self._head
	end
	self._head = connection
	return connection
end

function Signal:Once(fn)
	local connection
	connection = self:Connect(function(...)
		if connection then
			connection:Disconnect()
		end
		fn(...)
	end)
	return connection
end

function Signal:Fire(...)
	local item = self._head
	while item do
		if item.Connected then
			if not freeRunnerThread then
				freeRunnerThread = task.spawn(runEventHandlerInFreeThread, item._fn, ...)
			else
				task.spawn(freeRunnerThread, item._fn, ...)
			end
		end
		item = item._next
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	local item = self._head
	while item do
		item.Connected = false
		item = item._next
	end
	self._head = nil
end

function Signal:Destroy()
	self:DisconnectAll()
	setmetatable(self :: any, nil)
end

return Signal
