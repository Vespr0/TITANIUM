local Players = game:GetService("Players")

local BaseSoul = require(script.Parent.BaseSoul)
local ClientEntityManager = require(script.Parent.Parent.Services.ClientEntityManager)

local Player = Players.LocalPlayer

local ClientSoul = {}
ClientSoul.__index = ClientSoul

function ClientSoul.new()
	local self = setmetatable(BaseSoul.new(Player), ClientSoul)

	local function checkEntity(entity)
		-- Check if this entity's rig matches the local player's character
		if entity.rig == Player.Character then
			self.entity = entity
			self.EntityAdded:Fire(entity)
		end
	end

	self.maid:Connect(ClientEntityManager.EntityAdded, checkEntity)
	
	-- also check existing entities
	for _, entity in pairs(ClientEntityManager.GetAll()) do
		checkEntity(entity)
	end
	
	-- Handle character added/removing for better sync
	self.maid:Connect(Player.CharacterAdded, function(char)
		-- Wait for entity to be created by manager
		local entity = ClientEntityManager.Get(char)
		if entity then
			checkEntity(entity)
		end
	end)
	
	self.maid:Connect(Player.CharacterRemoving, function()
		self.entity = nil
	end)

	return self
end

function ClientSoul:destroy()
	self:destroyBase()
end

return ClientSoul
