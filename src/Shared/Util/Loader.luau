local Loading = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GLOBAL_TIMEOUT_LIMIT = 10

Loading.Initialized = {}

function Loading.Start(folder, blacklist)
	-- Load Assets
	require(ReplicatedStorage.Assets).Init()

	local descendants = folder:GetDescendants()
	local modules = {}

	-- Get all modules in the folder and its subfolders
	for _, d in descendants do
		if not d:IsA("ModuleScript") or (blacklist and table.find(blacklist, d)) then
			continue
		end
		table.insert(modules, d)
	end

	local loaded = false
	local currentModule = nil
	-- Global timeout system
	local globalTimeout = 0
	task.spawn(function()
		repeat
			task.wait(1)
			globalTimeout += 1
		until globalTimeout > GLOBAL_TIMEOUT_LIMIT or loaded

		if not loaded then
			error("❌ Loading timed out at " .. currentModule.Name .. " after " .. globalTimeout .. " seconds")
		end
	end)

	local timeoutScores = {}

	for _, module in modules do
		currentModule = module
		local required = require(module)

		-- Ignore modules that return other stuff, like a single function
		if typeof(required) ~= "table" then
			return
		end

		-- Check if the module depends on other modules, if so, put it at the bottom of the queue
		if required.Dependencies then
			for _, d in required.Dependencies do
				if not Loading.Initialized[d] then
					-- TODO: if the module in the dependencies doesnt exist this will lead to an endless loop
					print(`{module.Name} depends on {d}, putting it at the bottom of the queue`)

					-- Add timeout to prevent infinite loops
					if timeoutScores[module.Name] then
						timeoutScores[module.Name] += 1
					else
						timeoutScores[module.Name] = 1
					end

					if timeoutScores[module.Name] > 10 then
						error(`❌ Module "{module.Name}" depends on a module that will never initialize`)
					end

					task.wait(0.1)
					table.insert(modules, module)
					return
				end
			end
		end

		-- Make sure the module doesn't return other stuff, like a single function
		if typeof(required) ~= "table" then
			return
		end

		if required.Init then
			-- Initiliaze the module.
			required.Init()
			Loading.Initialized[module.Name] = true

			print(`✅ Initialized "{module.Name}" module`)
		end
	end

	loaded = true
end

return Loading
