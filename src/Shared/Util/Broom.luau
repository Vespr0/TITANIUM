--!strict
local RunService = game:GetService("RunService")

local Broom = {}
Broom.__index = Broom

export type CleanupTask = Instance | RBXScriptConnection | { Destroy: (self: any) -> () } | (() -> ())

export type Broom = {
	_tasks: { [any]: any },
	Add: <T>(self: Broom, task: T, cleanupMethod: string?) -> T,
	Remove: (self: Broom, task: any) -> (),
	Clean: (self: Broom) -> (),
	Destroy: (self: Broom) -> (),
	Connect: (self: Broom, signal: any, fn: (...any) -> ()) -> RBXScriptConnection,
	BindToRenderStep: (self: Broom, name: string, priority: number, fn: (dt: number) -> ()) -> (),
	AttachToInstance: (self: Broom, instance: Instance) -> (),
	Construct: <T, A...>(self: Broom, class: { new: (A...) -> T }, A...) -> T,
}

function Broom.new(): Broom
	return setmetatable({
		_tasks = {},
	}, Broom) :: any
end

function Broom:Add<T>(task: T, method: string?): T
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

function Broom:Remove(task: any)
	local cleanup = self._tasks[task]
	if cleanup then
		cleanup()
		self._tasks[task] = nil
	end
end

function Broom:Clean()
	for task, cleanup in pairs(self._tasks) do
		cleanup()
	end
	table.clear(self._tasks)
end

function Broom:Destroy()
	self:Clean()
	-- setmetatable(self :: any, nil) -- Optional: prevent use after destroy
end

function Broom:Connect(signal: any, fn: (...any) -> ())
	local connection = signal:Connect(fn)
	self:Add(connection)
	return connection
end

function Broom:BindToRenderStep(name: string, priority: number, fn: (dt: number) -> ())
	RunService:BindToRenderStep(name, priority, fn)
	self:Add(function()
		RunService:UnbindFromRenderStep(name)
	end)
end

function Broom:AttachToInstance(instance: Instance)
	self:Add(instance.Destroying:Connect(function()
		self:Destroy()
	end))
end

function Broom:Construct(class, ...)
	local object = class.new(...)
	return self:Add(object)
end

return Broom
 