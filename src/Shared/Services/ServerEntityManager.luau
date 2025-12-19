local CollectionService = game:GetService("CollectionService")
local ServerEntity = require(script.Parent.Parent.Classes.ServerEntity)

local EntityManager = {}
local entities = {}
local nextEntityId = 0

local entitiesFolder = workspace:FindFirstChild("Entities")
if not entitiesFolder then
	entitiesFolder = Instance.new("Folder")
	entitiesFolder.Name = "Entities"
	entitiesFolder.Parent = workspace
end

function EntityManager.GenerateId()
	nextEntityId += 1
	return nextEntityId
end

function EntityManager.Register(rig, userID: number)
	if not rig then
		return
	end

	local entityId = EntityManager.GenerateId()
	rig:SetAttribute("EntityId", entityId)
	if userID then
		rig:SetAttribute("EntityUserId", userID)
	end

	rig.Parent = entitiesFolder

	entities[entityId] = ServerEntity.new(rig)

	CollectionService:AddTag(rig, "Entity")

	return entities[entityId], entityId
end

function EntityManager.Get(entityId)
	return entities[entityId]
end

local function onInstanceRemoved(instance)
	local entityId = instance:GetAttribute("EntityId")
	if not entityId or not entities[entityId] then
		return
	end
	entities[entityId]:destroy()
	entities[entityId] = nil
end

function EntityManager.Init()
	CollectionService:GetInstanceRemovedSignal("Entity"):Connect(onInstanceRemoved)
end

return EntityManager
