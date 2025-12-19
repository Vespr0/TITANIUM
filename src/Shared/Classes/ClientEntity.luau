local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local BaseEntity = require(script.Parent.BaseEntity)

local ClientEntity = {}
ClientEntity.__index = ClientEntity
setmetatable(ClientEntity, BaseEntity)

local Debugger = require(script.Parent.Parent.Util.Debugger)

-- Components
local AnimationComponent = require(script.Parent.AnimationComponent)

function ClientEntity.new(rig)
	local self = setmetatable(BaseEntity.new(rig), ClientEntity)

	self.isLocalPlayerInstance = self.isPlayerInstance and rig:GetAttribute("EntityUserId") == Player.UserId

	self.entityId = rig:GetAttribute("EntityId")
	self.isPlayerCharacter = rig:GetAttribute("IsPlayerCharacter")

	self.animationComponent = AnimationComponent.new(rig)

	Debugger.sphere(rig:WaitForChild("HumanoidRootPart"), { Color3 = Color3.fromRGB(0, 140, 255) })

	return self
end

function ClientEntity:destroy()
	if self.animationComponent then
		self.animationComponent:Destroy()
	end
	self:destroyBase()
end

return ClientEntity
