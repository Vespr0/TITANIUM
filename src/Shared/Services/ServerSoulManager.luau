local Players = game:GetService("Players")

local Maid = require(script.Parent.Maid)
local ServerSoul = require(script.Parent.Parent.Classes.ServerSoul)

local SoulManager = {}
SoulManager.Souls = {}

function SoulManager.Init()
	local maid = Maid.new()

	maid:Connect(Players.PlayerAdded, function(player)
		SoulManager.Souls[player.UserId] = ServerSoul.new(player)
	end)

	maid:Connect(Players.PlayerRemoving, function(player)
		if SoulManager.Souls[player.UserId] then
			SoulManager.Souls[player.UserId]:destroy()
			SoulManager.Souls[player.UserId] = nil
		end
	end)
end

return SoulManager
