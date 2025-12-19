--!strict
local Assets = {}

Assets.Mode = {
	CLONE = "Clone",
	REQUIRE = "Require",
}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Types
export type AssetsGetMode = typeof(Assets.Mode.CLONE) | typeof(Assets.Mode.REQUIRE) | nil

-- Private State
local isInitialized = false
local assetsFolder: Folder? = nil
local rawAssets: { [string]: { Instance } } = {}

-- Constants
local ASSETS_FOLDER_NAME = "Assets"
local WAIT_TIMEOUT = 3

--[[
	Initializes the Assets service.
	Should only be called by TitaniumEngine.
]]
function Assets.Init()
	if isInitialized then
		warn(`Assets was already initialized on the {RunService:IsServer() and "server" or "client"}`)
		return
	end

	if RunService:IsServer() then
		-- On Server, we expect Assets in workspace and move them to ReplicatedStorage
		local workspaceAssets = workspace:WaitForChild(ASSETS_FOLDER_NAME, WAIT_TIMEOUT)

		if not workspaceAssets then
			warn(`No "Assets" folder found in workspace. Creating empty folder.`)
			workspaceAssets = Instance.new("Folder")
			workspaceAssets.Name = ASSETS_FOLDER_NAME
			workspaceAssets.Parent = ReplicatedStorage -- Actually parent to RS directly
		else
			workspaceAssets.Parent = ReplicatedStorage
		end

		if workspaceAssets and workspaceAssets:IsA("Folder") then
			assetsFolder = workspaceAssets
		else
			warn("❌ Assets object is not a Folder or is nil!")
		end
	else
		-- On Client, wait for Assets in ReplicatedStorage
		local rsAssets = ReplicatedStorage:WaitForChild(ASSETS_FOLDER_NAME, 10)
		if not rsAssets then
			error("❌ Assets timed out waiting for Assets in ReplicatedStorage")
		end

		if rsAssets and rsAssets:IsA("Folder") then
			assetsFolder = rsAssets
		end
	end

	-- Cache descendants for quick lookup
	if assetsFolder then
		for _, category in assetsFolder:GetChildren() do
			rawAssets[category.Name] = category:GetDescendants()
		end
	end



	isInitialized = true
	print(`✅ Assets Initialized ({RunService:IsServer() and "Server" or "Client"})`)
end

local function checkInitialized()
	if not isInitialized then
		error("❌ Assets cannot be used before it is initialized by TitaniumEngine.")
	end
end

--[[
	Retrieves an asset or directory instance.
	@param category The category name (top-level folder in Assets).
	@param path The path to the asset within the category (e.g. "Weapon/Sword").
	@param mode Optional mode: "Clone", "Require", or nil (return Instance).
]]
function Assets.GetDir(category: string, path: string, mode: AssetsGetMode): any
	checkInitialized()

	if not assetsFolder then
		return nil
	end

	local categoryFolder = assetsFolder:FindFirstChild(category)
	if not categoryFolder then
		warn(`Assets: Category "{category}" not found.`)
		return nil
	end

	local current: Instance? = categoryFolder
	for _, segment in string.split(path, "/") do
		if current then
			current = current:FindFirstChild(segment)
		end
		if not current then
			warn(`Assets: Path "{path}" not found in category "{category}". Failed at "{segment}".`)
			return nil
		end
	end

	if not current then
		return nil
	end

	if mode == Assets.Mode.CLONE then
		return current:Clone()
	elseif mode == Assets.Mode.REQUIRE and current:IsA("ModuleScript") then
		return require(current :: ModuleScript)
	end

	return current
end

--[[
	Finds an asset by name within a category (deep search).
	@param category The category to search in.
	@param name The name of the asset.
	@param mode Optional mode: "Clone", "Require", or nil.
]]
function Assets.Get(category: string, name: string, mode: AssetsGetMode): any
	checkInitialized()

	local assetsList = rawAssets[category]
	if not assetsList then
		warn(`Assets: Category "{category}" not found or empty.`)
		return nil
	end

	for _, asset in assetsList do
		if asset.Name == name then
			if mode == Assets.Mode.CLONE then
				return asset:Clone()
			elseif mode == Assets.Mode.REQUIRE and asset:IsA("ModuleScript") then
				return require(asset :: ModuleScript)
			end
			return asset
		end
	end

	warn(`Assets: Asset "{name}" not found in category "{category}".`)
	return nil
end

return Assets
