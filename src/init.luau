--!strict
local Titanium = {}

-- Private Types
type ModuleMap = { [string]: ModuleScript }

-- State
local loadedModules: { [string]: any } = {}
local moduleMap: ModuleMap = {}
local allowedServices: { [string]: boolean }? = nil

--// Module Mapping Logic
local function mapModules(folder: Instance)
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			-- Warn if duplicate name
			if moduleMap[child.Name] then
				warn(`Titanium: Duplicate module name found: {child.Name}. Overwriting previous entry.`)
			end
			moduleMap[child.Name] = child
		elseif child:IsA("Folder") then
			mapModules(child)
		end
	end
end

-- Map services
local Shared = script:WaitForChild("Shared", 5)
if Shared then
	local Services = Shared:FindFirstChild("Services")
	if Services then
		mapModules(Services)
	end
	-- Also map Engine.
	local Engine = Shared:FindFirstChild("Engine")
	if Engine and Engine:IsA("ModuleScript") then
		moduleMap["Engine"] = Engine
	end
end

--// Public API

--[[
	Retrieves a framework module by name.
	Loads the module if it hasn't been loaded yet (Lazy Loading).
]]
function Titanium.GetService(moduleName: string): any
	-- Check if titanium was started
	if not allowedServices then
		warn(`Titanium: Engine was never started. Please call Titanium.Start() before getting a service.`)
		return nil
	end
	
	-- Check allowed services
	if allowedServices and not allowedServices[moduleName] then
		warn(`Titanium: Service "{moduleName}" was not requested in Start options.`)
		return nil
	end

	-- Check if already loaded
	if loadedModules[moduleName] then
		return loadedModules[moduleName]
	end

	-- Check if it exists in the map
	local targetModule = moduleMap[moduleName]
	if not targetModule then
		warn(`Titanium: Could not find service "{moduleName}"`)
		return nil
	end

	-- Require and cache
	local success, result = pcall(require, targetModule)
	if not success then
		warn(`Titanium: Failed to require service "{moduleName}": {result}`)
		return nil
	end

	loadedModules[moduleName] = result
	return result
end

-- Alias for GetService
Titanium.Get = Titanium.GetService

--[[
	Starts the Titanium Framework.
	This initializes the TitaniumEngine and Asset system.
	@param folder Optional folder containing Game Modules to load via TitaniumEngine.
	@param services Optional list of services to whitelist.
	@param blacklist Optional blacklist of modules to ignore.
]]
function Titanium.Start(folder: Folder?, services: { string }?, blacklist: { ModuleScript }?)
	if services then
		allowedServices = {
			["Engine"] = true
		}
		for _, serviceName in services do
			allowedServices[serviceName] = true
		end
	end

	local Engine = Titanium.Get("Engine")
	if Engine then
		Engine.Start(folder, blacklist)
	else
		warn("Titanium: Failed to load Engine during Start.")
	end
end

-- Test
function Titanium.Test()
	local Maid = Titanium.Get("Maid")
	local Spring = Titanium.Get("Spring")

	local Maid = Maid.new() 

	-- Connecting an event
	Maid:Connect(game:GetService("Players").PlayerAdded, function(player)
		print(player.Name)
	end)

	-- Adding an object
	local brick = Instance.new("Part")
	Maid:Add(brick)

	-- Adding a function
	Maid:Add(function()
		print("Hello World")
	end)

	-- Cleaning up
	Maid:Clean()


	-- Spring
	local spring = Spring.new(0)
	spring:SetTarget(1)
	
	print(spring:Update(0.1))

	-- Entities
	local Entities = Titanium.Get("Entities")
	
end

return Titanium
