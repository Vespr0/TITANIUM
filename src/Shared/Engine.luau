--!strict
local Engine = {}

-- Services

local RunService = game:GetService("RunService")

-- Modules
local Loader = require(script.Parent.Services.Loader)
local Assets = require(script.Parent.Services.Assets)

-- State
Engine.Started = false

--[[
	Starts the Engine.
	Intializes Assets and loads modules in the provided folder.
	@param folder The folder containing modules to load.
	@param blacklist Optional list of modules to ignore.
]]
function Engine.Start(folder: Folder, blacklist: { ModuleScript }?)
	if Engine.Started then
		warn("Engine has already been started! Execution prevented.")
		return
	end

	print("Starting Engine on " .. (RunService:IsServer() and "Server" or "Client") .. "...")

	-- 1. Initialize Assets
	-- Assets must be initialized before any other module might try to use them.
	Assets.Init()

	-- 2. Load Modules using the Loader utility
	if folder then
		Loader.Start(folder, blacklist)
	else
		warn("Engine.Start called without a folder. No modules will be loaded.")
	end

	Engine.Started = true
	print("Engine Started Successfully " .. (RunService:IsServer() and "on Server" or "on Client"))
end

return Engine
