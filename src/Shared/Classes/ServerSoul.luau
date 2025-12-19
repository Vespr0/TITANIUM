

local ServerSoul = {}
ServerSoul.__index = ServerSoul

-- Entities
local BaseSoul = require(script.Parent.BaseSoul)
setmetatable(ServerSoul, { __index = BaseSoul })
local ServerEntityManager = require(script.Parent.Parent.Services.ServerEntityManager)

function ServerSoul.new(player)
	local self = setmetatable(BaseSoul.new(player), ServerSoul)

	self.maid:Connect(player.CharacterAdded, function(character)
		character:SetAttribute("IsPlayerCharacter", true)
		self.entity = ServerEntityManager.Register(character)
	end)

	self.maid:Connect(player.CharacterRemoving, function(character)
		self.entity = nil
	end)

	if player.Character then
		player.Character:SetAttribute("IsPlayerCharacter", true)
		self.entity = ServerEntityManager.Register(player.Character, player.UserId)
	end

	return self
end

function ServerSoul:destroy()
	self:destroyBase()
end

return ServerSoul
