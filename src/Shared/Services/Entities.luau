local RunService = game:GetService("RunService")

local Entities = {}

function Entities.Start()
	if RunService:IsClient() then
		return require(script.Parent.ClientEntityManager).Init()
	else
		return require(script.Parent.ServerEntityManager).Init()
	end
end

-- Expose the underlying manager for convenience
function Entities.GetManager()
	if RunService:IsClient() then
		return require(script.Parent.ClientEntityManager)
	else
		return require(script.Parent.ServerEntityManager)
	end
end

return Entities