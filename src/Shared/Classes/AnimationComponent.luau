
local Maid = require(script.Parent.Parent.Services.Maid)

local AnimationComponent = {}
AnimationComponent.__index = AnimationComponent

function AnimationComponent.new(rig)
	local self = setmetatable({}, AnimationComponent)
	
	self.rig = rig
	self.humanoid = rig:WaitForChild("Humanoid", 10)
	if not self.humanoid then
		warn("AnimationComponent: No Humanoid found for rig", rig)
		return self
	end

	self.animator = self.humanoid:WaitForChild("Animator", 10)
	if not self.animator then
		self.animator = Instance.new("Animator")
		self.animator.Parent = self.humanoid
	end
	
	self.tracks = {}
	self.maid = Maid.new()
	
	self.maid:Add(function()
		for _, track in pairs(self.tracks) do
			track:Stop()
		end
		table.clear(self.tracks)
	end)
	
	return self
end

function AnimationComponent:Load(name, animation)
	if self.tracks[name] then
		return self.tracks[name]
	end

	if not self.animator then return end
	
	if typeof(animation) ~= "Instance" or not animation:IsA("Animation") then
		warn("AnimationComponent:Load expected an Animation Instance, got:", typeof(animation))
		return
	end

	local success, track = pcall(function()
		return self.animator:LoadAnimation(animation)
	end)
	
	if success and track then
		self.tracks[name] = track
		return track
	else
		warn("Failed to load animation:", name, animation)
		return nil
	end
end

function AnimationComponent:Play(name, ...)
	local track = self.tracks[name]
	if track then
		track:Play(...)
	end
end

function AnimationComponent:Stop(name, ...)
	local track = self.tracks[name]
	if track then
		track:Stop(...)
	end
end

function AnimationComponent:GetTrack(name)
	return self.tracks[name]
end

function AnimationComponent:Destroy()
	self.maid:Destroy()
end

return AnimationComponent
