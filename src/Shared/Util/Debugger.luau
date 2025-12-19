--[=[
	A module for creating debug visualizations using HandleAdornments.
	This can be used to draw shapes like boxes, cones, cylinders, and spheres
	to visualize things like hitboxes, trigger areas, or other game logic.
]=]
local Debugger = {}

--[=[
	Draws a box in the world.
	If the object is a Model, it creates a world-space bounding box.
	If the object is a BasePart, it creates a box with the same CFrame and Size.
	@param object BasePart | Model
	@param properties table? (Color3, Transparency, etc.)
	@return BoxHandleAdornment
]=]
function Debugger.box(object, properties)
	local box = Instance.new("BoxHandleAdornment")

	if object:IsA("Model") then
		local cframe, size = object:GetBoundingBox()
		box.CFrame = cframe
		box.Size = size
	elseif object:IsA("BasePart") then
		box.CFrame = object.CFrame
		box.Size = object.Size
	else
		warn("Debugger.box can only be used with a BasePart or a Model.")
		return nil
	end

	for property, value in pairs(properties or {}) do
		box[property] = value
	end

	-- Parent to CoreGui to make sure it is visible and doesn't interfere with workspace scripts.
	box.Parent = game:GetService("CoreGui")
	return box
end

local function createPartAdornment(className, part, properties)
	if not part:IsA("BasePart") then
		warn("Debugger." .. className:lower():gsub("handleadornment", "") .. " requires a BasePart.")
		return nil
	end

	local adornment = Instance.new(className)
	adornment.Adornee = part

	for property, value in pairs(properties or {}) do
		adornment[property] = value
	end

	adornment.Parent = part
	return adornment
end

--[=[
	Creates a SphereHandleAdornment on a BasePart.
	@param part BasePart
	@param properties table?
	@return SphereHandleAdornment
]=]
function Debugger.sphere(part, properties)
	return createPartAdornment("SphereHandleAdornment", part, properties)
end

--[=[
	Draws a line between two points.
	The attachments created for the line are parented to the specified parent.
	@param origin Vector3
	@param destination Vector3
	@param parent Instance
	@param properties table?
	@return LineHandleAdornment, Attachment, Attachment
]=]
function Debugger.line(origin, destination, parent, properties)
	local line = Instance.new("LineHandleAdornment")

	local attachment1 = Instance.new("Attachment")
	attachment1.WorldPosition = origin
	attachment1.Parent = parent

	local attachment2 = Instance.new("Attachment")
	attachment2.WorldPosition = destination
	attachment2.Parent = parent

	line.Attachment0 = attachment1
	line.Attachment1 = attachment2

	for property, value in pairs(properties or {}) do
		line[property] = value
	end

	line.Parent = parent

	return line, attachment1, attachment2
end

return Debugger
