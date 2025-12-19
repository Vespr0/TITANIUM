local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientEntity = require(script.Parent.Parent.Classes.ClientEntity)
local Signal = require(script.Parent.Signal)

local EntityManager = {}
EntityManager.EntityAdded = Signal.new()

local entities = {}

function EntityManager.Get(entityId)
	if typeof(entityId) == "Instance" then
		entityId = entityId:GetAttribute("EntityId")
	end
	return entities[entityId]
end

function EntityManager.GetAll()
	return entities
end

local function onInstanceAdded(instance)
	local entityId = instance:GetAttribute("EntityId")
	if not entityId or entities[entityId] then
		return
	end
	local entity = ClientEntity.new(instance)
	entities[entityId] = entity
	EntityManager.EntityAdded:Fire(entity)
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
	CollectionService:GetInstanceAddedSignal("Entity"):Connect(onInstanceAdded)
	CollectionService:GetInstanceRemovedSignal("Entity"):Connect(onInstanceRemoved)

	for _, instance in ipairs(CollectionService:GetTagged("Entity")) do
		onInstanceAdded(instance)
	end
end

return EntityManager
