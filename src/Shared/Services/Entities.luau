local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local Maid = require(script.Parent.Maid)
local Signal = require(script.Parent.Signal)

-- Types
export type Entity = {
	Id: string,
	Model: Model,
	Maid: any, -- Maid
	Destroy: (self: Entity) -> (),
}

export type EntitiesService = {
	Folder: Folder?,
	_entities: { [string]: Entity },
	
	EntityAdded: any, -- Signal
	EntityRemoved: any, -- Signal
	
	Init: (self: EntitiesService) -> (),
	Start: (self: EntitiesService) -> (),
	
	Register: (self: EntitiesService, model: Model) -> Entity?,
	Get: (self: EntitiesService, id: string) -> Entity?,
	GetAll: (self: EntitiesService) -> { [string]: Entity },
}

--// Entity Class
local Entity = {}
Entity.__index = Entity

function Entity.new(id: string, model: Model): Entity
	local self = setmetatable({
		Id = id,
		Model = model,
		Maid = Maid.new(),
	}, Entity)
	
	return self :: any
end

function Entity:Destroy()
	self.Maid:Destroy()
	-- We don't necessarily destroy the model here, as this class wraps it. 
	-- But if the class is destroyed manually, maybe we should?
	-- For now, we assume this class tracks the model. 
	-- If the model dies, we destroy this class.
	setmetatable(self, nil)
end


--// Service
local Entities: EntitiesService = {
	Folder = nil,
	_entities = {},
	EntityAdded = Signal.new(),
	EntityRemoved = Signal.new(),
} :: any

local TAG_NAME = "Entity"
local FOLDER_NAME = "Entities"

function Entities:Init()
	if RunService:IsServer() then
		-- Server: Create Folder
		local folder = workspace:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = workspace
		end
		self.Folder = folder
	else
		-- Client: Wait for Folder
		self.Folder = workspace:WaitForChild(FOLDER_NAME)
	end
end

function Entities:Start()
	local function onEntityAdded(model: Instance)
		if not model:IsA("Model") then return end
		
		local id = model:GetAttribute("EntityId")
		if not id then
			-- Wait for attribute if it doesn't exist yet (client replication)
			if RunService:IsClient() then
				task.delay(0.1, function()
					if not model.Parent then return end
					id = model:GetAttribute("EntityId")
					if id then
						self:_CreateEntityClass(id :: string, model :: Model)
					end
				end)
			end
			return 
		end
		
		self:_CreateEntityClass(id :: string, model :: Model)
	end
	
	local function onEntityRemoved(model: Instance)
		-- We can rely on the model's Destroying event or finding it in our list
		for id, entity in pairs(self._entities) do
			if entity.Model == model then
				self:_RemoveEntity(id)
				break
			end
		end
	end

	CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(onEntityAdded)
	CollectionService:GetInstanceRemovedSignal(TAG_NAME):Connect(onEntityRemoved)
	
	for _, model in CollectionService:GetTagged(TAG_NAME) do
		onEntityAdded(model)
	end
end

function Entities:_CreateEntityClass(id: string, model: Model)
	if self._entities[id] then return end
	
	local entity = Entity.new(id, model)
	self._entities[id] = entity
	
	-- Cleanup when model is destroyed is handled by CollectionService Removed signal mostly,
	-- but keeping a Destroying listener is a good fallback.
	entity.Maid:Add(model.Destroying:Connect(function()
		self:_RemoveEntity(id)
	end))
	
	-- Cleanup when Humanoid dies (if present)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		entity.Maid:Add(humanoid.Died:Connect(function()
			self:_RemoveEntity(id)
		end))
	end
	
	self.EntityAdded:Fire(entity)
	return entity
end

function Entities:_RemoveEntity(id: string)
	local entity = self._entities[id]
	if entity then
		entity:Destroy()
		self._entities[id] = nil
		self.EntityRemoved:Fire(id)
	end
end

function Entities:Register(model: Model): Entity?
	if not RunService:IsServer() then
		warn("Entities:Register can only be called on Server")
		return nil
	end
	
	if not self.Folder then return nil end
	
	-- Generate ID
	local id = HttpService:GenerateGUID(false)
	
	-- Setup Model
	model:SetAttribute("EntityId", id)
	CollectionService:AddTag(model, TAG_NAME)
	model.Parent = self.Folder
	
	-- Create Wrapper
	return self:_CreateEntityClass(id, model)
end

function Entities:Get(id: string): Entity?
	return self._entities[id]
end

function Entities:GetAll()
	return self._entities
end

return Entities