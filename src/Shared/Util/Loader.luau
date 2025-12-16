local Loading = {}

-- Services

local RunService = game:GetService("RunService")

local GLOBAL_TIMEOUT_LIMIT = 10

Loading.Initialized = {}

function Loading.Start(folder: Folder, blacklist: { ModuleScript }?)
	if not folder then
		warn("❌ No folder provided to Loading.Start")
		return
	end

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

		if not loaded and currentModule then
			warn("❌ Loading timed out at " .. currentModule.Name .. " after " .. globalTimeout .. " seconds")
		end
	end)

	local timeoutScores = {}

	-- Using a while loop to handle re-queueing more naturally
	local i = 1
	while i <= #modules do
		local module = modules[i]
		currentModule = module

		-- Use pcall to safely require modules
		local success, required = pcall(require, module)
		if not success then
			warn(`❌ Failed to require module "{module.Name}": {required}`)
			i += 1
			continue
		end

		-- Ignore modules that return other stuff, like a single function
		if typeof(required) ~= "table" then
			i += 1
			continue
		end

		-- Check if the module depends on other modules, if so, put it at the bottom of the queue
		if required.Dependencies then
			local dependenciesMet = true
			for _, d in required.Dependencies do
				if not Loading.Initialized[d] then
					print(`{module.Name} depends on {d}, putting it at the bottom of the queue`)
					dependenciesMet = false

					-- Add timeout to prevent infinite loops
					timeoutScores[module.Name] = (timeoutScores[module.Name] or 0) + 1

					if timeoutScores[module.Name] > 10 then
						warn(`❌ Module "{module.Name}" depends on a module that will never initialize`)
						dependenciesMet = true -- Force skip to avoid infinite loop
					else
						-- Move to end of list
						table.remove(modules, i)
						table.insert(modules, module)
						-- Don't increment i, as we removed the current element and the next one is now at i
					end
					break
				end
			end

			if not dependenciesMet then
				task.wait(0.1) -- Small yield to let other things process
				continue
			end
		end

		if required.Init then
			-- Initialize the module.
			local initSuccess, initError = pcall(required.Init)
			if initSuccess then
				Loading.Initialized[module.Name] = true
				print(`✅ Initialized "{module.Name}" module`)
			else
				warn(`❌ Failed to initialize "{module.Name}": {initError}`)
			end
		else
			-- If no Init, consider it initialized (or just loaded)
			Loading.Initialized[module.Name] = true
		end

		i += 1
	end

	loaded = true
end

return Loading
