--!strict
local RunService = game:GetService("RunService")

local Maid = {}
Maid.__index = Maid

export type CleanupTask = Instance | RBXScriptConnection | { Destroy: (self: any) -> () } | (() -> ())

export type Maid = {
	_tasks: { [any]: any },
	Add: <T>(self: Maid, task: T, cleanupMethod: string?) -> T,
	Remove: (self: Maid, task: any) -> (),
	Clean: (self: Maid) -> (),
	Destroy: (self: Maid) -> (),
	Connect: (self: Maid, signal: any, fn: (...any) -> ()) -> RBXScriptConnection,
	BindToRenderStep: (self: Maid, name: string, priority: number, fn: (dt: number) -> ()) -> (),
	AttachToInstance: (self: Maid, instance: Instance) -> (),
	Construct: <T, A...>(self: Maid, class: { new: (A...) -> T }, A...) -> T,
}

function Maid.new(): Maid
	return setmetatable({
		_tasks = {},
	}, Maid) :: any
end

function Maid:Add<T>(task: T, method: string?): T
	if task == nil then
		error("Task cannot be nil", 2)
	end

	local cleanup
	
	if method then
		cleanup = function()
			(task :: any)[method](task)
		end
	elseif typeof(task) == "function" then
		cleanup = task
	elseif typeof(task) == "RBXScriptConnection" then
		cleanup = function()
			task:Disconnect()
		end
	elseif typeof(task) == "Instance" then
		cleanup = function()
			task:Destroy()
		end
	elseif type(task) == "table" then
		if typeof(task.Destroy) == "function" then
			cleanup = function()
				(task :: { Destroy: (any) -> () }):Destroy()
			end
		elseif typeof(task.Disconnect) == "function" then
			cleanup = function()
				(task :: { Disconnect: (any) -> () }):Disconnect()
			end
		end
	end
	
	if not cleanup then
		error("Could not determine cleanup for task", 2)
	end
	
	-- Overwrite existing cleanup if the same task is added again
	self._tasks[task] = cleanup
	
	return task
end

function Maid:Remove(task: any)
	local cleanup = self._tasks[task]
	if cleanup then
		cleanup()
		self._tasks[task] = nil
	end
end

function Maid:Clean()
	for task, cleanup in pairs(self._tasks) do
		cleanup()
	end
	table.clear(self._tasks)
end

function Maid:Destroy()
	self:Clean()
	-- setmetatable(self :: any, nil) -- Optional: prevent use after destroy
end

function Maid:Connect(signal: any, fn: (...any) -> ())
	local connection = signal:Connect(fn)
	self:Add(connection)
	return connection
end

function Maid:BindToRenderStep(name: string, priority: number, fn: (dt: number) -> ())
	RunService:BindToRenderStep(name, priority, fn)
	self:Add(function()
		RunService:UnbindFromRenderStep(name)
	end)
end

function Maid:AttachToInstance(instance: Instance)
	self:Add(instance.Destroying:Connect(function()
		self:Destroy()
	end))
end

function Maid:Construct(class, ...)
	local object = class.new(...)
	return self:Add(object)
end

return Maid
 