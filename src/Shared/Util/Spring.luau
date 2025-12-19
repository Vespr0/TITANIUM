--!strict

--[[
	Spring.lua
	Generic Spring module for strict Luau.
	Supports numbers, Vector2, Vector3, etc.
]]

local Spring = {}
Spring.__index = Spring

export type Spring<T> = {
	Target: T,
	Position: T,
	Velocity: T,
	
	Mass: number,
	Force: number,
	Damping: number,
	Speed: number,
	
	Update: (self: Spring<T>, dt: number) -> T,
	Impulse: (self: Spring<T>, velocity: T) -> (),
	SetTarget: (self: Spring<T>, target: T) -> (),
	Set: (self: Spring<T>, position: T) -> (),
}

function Spring.new<T>(initial: T): Spring<T>
	return setmetatable({
		Target = initial,
		Position = initial,
		Velocity = (if typeof(initial) == "number" then 0 else initial * 0) :: T,
		
		Mass = 5,
		Force = 50,
		Damping = 20,
		Speed = 4,
	}, Spring) :: any
end

function Spring.Update(self: any, dt: number)
	local scaledDeltaTime = math.min(dt, 0.1) * self.Speed / 0.1
	local force = self.Target - self.Position
	local acceleration = force * (self.Force / self.Mass)
	
	acceleration = acceleration - self.Velocity * self.Damping
	
	self.Velocity = self.Velocity + acceleration * scaledDeltaTime
	self.Position = self.Position + self.Velocity * scaledDeltaTime
	
	return self.Position
end

function Spring.Impulse(self: any, velocity: any)
	self.Velocity = self.Velocity + velocity
end

function Spring.SetTarget(self: any, target: any)
	self.Target = target
end

function Spring.Set(self: any, position: any)
	self.Position = position
	self.Target = position
	self.Velocity = self.Velocity * 0
end

return Spring
