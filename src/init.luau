--!strict
local Titanium = {}

-- Private Types
type ModuleMap = { [string]: ModuleScript }

-- State
local loadedModules: { [string]: any } = {}
local moduleMap: ModuleMap = {}

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

-- Initialize mapping from Shared, Client, and Server folders
-- We only map Shared by default to ensure client/server agnostic API unless requested otherwise.
-- However, typically a framework exposes its Shared tools.
local Shared = script:WaitForChild("Shared", 5)
if Shared then
	mapModules(Shared)
end

--// Public API

--[[
	Retrieves a framework module by name.
	Loads the module if it hasn't been loaded yet (Lazy Loading).
]]
function Titanium.Get(moduleName: string): any
	-- 1. Check if already loaded
	if loadedModules[moduleName] then
		return loadedModules[moduleName]
	end

	-- 2. Check if it exists in the map
	local targetModule = moduleMap[moduleName]
	if not targetModule then
		warn(`Titanium: Could not find module "{moduleName}"`)
		return nil
	end

	-- 3. Require and cache
	local success, result = pcall(require, targetModule)
	if not success then
		warn(`Titanium: Failed to require module "{moduleName}": {result}`)
		return nil
	end

	loadedModules[moduleName] = result
	return result
end

-- Alias for Get
Titanium.GetService = Titanium.Get

--[[
	Starts the Titanium Framework.
	This initializes the TitaniumEngine and Asset system.
	@param folder Optional folder containing Game Modules to load via TitaniumEngine.
	@param blacklist Optional blacklist of modules to ignore.
]]
function Titanium.Start(folder: Folder?, blacklist: { ModuleScript }?)
	local Engine = Titanium.Get("Engine")
	if Engine then
		Engine.Start(folder, blacklist)
	else
		warn("Titanium: Failed to load Engine during Start.")
	end
end

return Titanium
