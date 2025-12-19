
local Maid = require(script.Parent.Parent.Services.Maid)

local BaseEntity = {}
BaseEntity.__index = BaseEntity

function BaseEntity.new(rig)
	local self = setmetatable({}, BaseEntity)
	self.rig = rig
	self.maid = Maid.new()

	self.humanoid = rig:WaitForChild("Humanoid")

	self.isPlayerInstance = rig:GetAttribute("EntityUserId") ~= nil

	self.maid:Add(function()
		self.rig = nil
	end)

	return self
end

function BaseEntity:destroyBase()
	self.maid:Destroy()
end

return BaseEntity
