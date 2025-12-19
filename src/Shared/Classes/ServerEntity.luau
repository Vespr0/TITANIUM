
local BaseEntity = require(script.Parent.BaseEntity)

local ServerEntity = {}
ServerEntity.__index = ServerEntity
setmetatable(ServerEntity, BaseEntity)

function ServerEntity.new(rig)
	local self = setmetatable(BaseEntity.new(rig), ServerEntity)

	self.maid:Connect(rig.AncestryChanged, function(_, parent)
		if not parent then
			self:destroy()
		end
	end)

	return self
end

function ServerEntity:destroy()
	self:destroyBase()
end

return ServerEntity
