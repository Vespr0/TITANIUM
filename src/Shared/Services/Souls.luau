local RunService = game:GetService("RunService")

local Souls = {}

function Souls.Start()
	if RunService:IsClient() then
		local ClientSoul = require(script.Parent.Parent.Classes.ClientSoul)
		Souls.ClientSoul = ClientSoul.new()
	else
		require(script.Parent.ServerSoulManager).Init()
	end
end

function Souls.GetClientSoul()
	if RunService:IsClient() then
		if not Souls.ClientSoul then
			Souls.Start()
			warn("Souls.GetClientSoul was called before Souls.Start(). Souls.Start() has been called automatically.")
		end
		return Souls.ClientSoul
	else
		warn("Souls.GetClientSoul was called on the server. This function is client-only.")
		return nil
	end
end

-- Expose manager
function Souls.GetManager()
	if RunService:IsClient() then
		return require(script.Parent.ClientSoulManager)
	else
		return require(script.Parent.ServerSoulManager)
	end
end

return Souls
