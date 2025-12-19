

local Maid = require(script.Parent.Parent.Services.Maid)
local Signal = require(script.Parent.Parent.Services.Signal)

local BaseSoul = {}
BaseSoul.__index = BaseSoul

function BaseSoul.new(player)
    local self = setmetatable({}, BaseSoul)
    self.player = player
    self.entity = nil
    self.EntityAdded = Signal.new()

    self.maid = Maid.new()
    return self
end

function BaseSoul:destroyBase()
    self.maid:Destroy()
end

return BaseSoul
