local Assets = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Types
export type assetsGetMode = "Clone" | "Require" | nil

-- Variables
Assets.Initialized = false
Assets.Assets = ReplicatedStorage:WaitForChild("Assets", 3)
Assets.RawAssets = {} :: { [string]: { Instance } }

local function validateAssets()
	for category, assets in Assets.RawAssets do
		local validator = script.Validators:FindFirstChild(category .. "Validator")
		if validator then
			validator = require(validator)
		else
			warn(`No validator for "{category}" category`)
			continue
		end

		for _, asset in assets do
			validator(asset)
		end
	end
end

function Assets.Init()
	if Assets.Initialized then
		warn("Assets was already inizialized on the " .. RunService:IsServer() and "server" or "client")
		return
	end

	if RunService:IsServer() then
		Assets.Assets = workspace:WaitForChild("Assets", 3)

		if not Assets.Assets then
			error("❌ No assets folder in workspace")
		else
			Assets.Assets.Parent = ReplicatedStorage
		end
	else
		repeat
			task.wait()
		until ReplicatedStorage:FindFirstChild("Assets")
	end

	for _, category in Assets.Assets:GetChildren() do
		Assets.RawAssets[category.Name] = category:GetDescendants()
	end

	if RunService:IsServer() then
		validateAssets()
	end

	Assets.Initialized = true
end

function Assets.GetDir(category: string, directory: string, mode: assetsGetMode)
	if not directory or typeof(directory) ~= "string" then
		warn(
			`Invalid directory "{tostring(directory)}" has type: "{typeof(directory) or "nil"}" raw directory: `,
			directory
		)
	end
	-- Split the directory string into components
	local components = string.split(directory, "/")

	-- Start from the category folder
	local currentFolder = Assets.Assets:FindFirstChild(category)
	if not currentFolder then
		warn(`No category "{category}"`)
		return nil
	end

	-- Navigate through the hierarchy based on the remaining path
	for _, folderName in ipairs(components) do
		currentFolder = currentFolder:FindFirstChild(folderName)
		if not currentFolder then
			warn(`Invalid directory, couldn't find folder "{folderName}" in category "{category}"`)
			return nil
		end
	end

	-- If the final result is not an instance, return nil
	if not currentFolder:IsA("Instance") then
		warn("Invalid directory, final target is not an instance")
		return nil
	end

	if mode == "Clone" then
		return currentFolder:Clone()
	elseif mode == "Require" and currentFolder:IsA("ModuleScript") then
		return require(currentFolder)
	end
	return currentFolder
end

function Assets.Get(category: string, name: string, mode: assetsGetMode)
	local categoryFolder = Assets.Assets:FindFirstChild(category)
	if not categoryFolder then
		warn("No category", category)
		return nil
	end

	for _, d in Assets.RawAssets[category] do
		if d.Name == name then
			-- Immediately clone or require without caching
			if mode == "Clone" then
				return d:Clone()
			elseif mode == "Require" and d:IsA("ModuleScript") then
				return require(d)
			end
			return d
		end
	end

	warn(`Couldn't find asset of category "{category}" with name "{name}"`)
	return nil
end

return Assets
