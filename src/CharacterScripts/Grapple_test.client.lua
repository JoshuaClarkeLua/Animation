-- Character head top always facing grappling point

-- Character distance away from grappling point confined

-- Gravity acts against the upward velocity of the character (stopping it from easily doing full rotations)


local RunService = game:GetService('RunService')
local InputService = game:GetService('UserInputService')
local ContextActionService = game:GetService('ContextActionService')

local libs = game:GetService('ReplicatedStorage').ROJO
local Lerp = require(libs.Lerp)
local Vec3 = require(libs.Vec3)

local GRAPPLE_KEY = Enum.KeyCode.R
local RAY_PARAMS = RaycastParams.new()
local GRAPPLE_FORCE = 5
local THRUST_FORCE = 9
local GRAPPLE_MAX_DIST = 1000000
local VELOCITY_DECREASE = 5
local MAX_VELOCITY = 150

local char = script.Parent
local humanoid = char.Humanoid
local rootPart: Part = humanoid.RootPart
local rootAttachment: Attachment = rootPart:FindFirstChild('RootRigAttachment') :: Attachment
local camera = workspace.CurrentCamera


local grappling = false
local currentGrapple: RaycastResult
local grapplePart: Part

local partFilter = {char}
RAY_PARAMS.FilterDescendantsInstances = partFilter
RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
ContextActionService:BindAction('Grapple', function(_,istate,iobj)
	if istate == Enum.UserInputState.Begin then
		local mousePos = InputService:GetMouseLocation()
		local cRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
		local res = workspace:Raycast(cRay.Origin, cRay.Direction*GRAPPLE_MAX_DIST, RAY_PARAMS)
		if res then
			local rayOrigin: Vector3 = char.Head.Position
			local rayDirection = (res.Position - rayOrigin).Unit*GRAPPLE_MAX_DIST
			res = workspace:Raycast(rayOrigin, rayDirection, RAY_PARAMS)
			if res then
				local part = Instance.new('Part')
				part.Transparency = 1
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.Position = res.Position
				local attachment = Instance.new('Attachment')
				attachment.Parent = part
				local rope = Instance.new('RopeConstraint')
				rope.Length = res.Distance
				rope.Attachment1 = attachment
				rope.Attachment0 = rootPart:FindFirstChild('RootRigAttachment')
				rope.Visible = true
				--rope.Restitution = .35
				rope.Parent = part
-- 
-- 				lineForce.Attachment1 = attachment
-- 				lineForce.Magnitude = GRAPPLE_SPEED*10*rootPart.AssemblyMass
				
				part.Parent = workspace

				currentGrapple = res
				grapplePart = part
				grappling = true
			end
		end
	else
		if grappling then
			grappling = false
			grapplePart:Destroy()
		end
	end
end, true, Enum.UserInputType.MouseButton1)

local lastVel = rootPart.AssemblyLinearVelocity
RunService.PreSimulation:Connect(function(dt)
	local vel = rootPart.AssemblyLinearVelocity
	local acc = vel - lastVel
	if grappling then
		local direction = currentGrapple.Position - rootPart.Position
		local dist = direction.Magnitude
		-- if vel.Y < 0 and humanoid.MoveDirection.Magnitude ~= 0 then
		-- 	rootPart:ApplyImpulse(Vector3.new(0,-rootPart.AssemblyMass*vel.Y,0))
		-- end

		if rootPart.AssemblyLinearVelocity.Magnitude > MAX_VELOCITY then
			rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity*humanoid.MoveDirection.Unit
		else
			local forceImpulse = humanoid.MoveDirection*rootPart.AssemblyMass*THRUST_FORCE
			rootPart:ApplyImpulse(forceImpulse)
		end

		local rope: RopeConstraint? = grapplePart:FindFirstChildOfClass('RopeConstraint')
		if rope then
			local newLen = rope.Length-5
			if dist < newLen then
				rope.Length = dist-.5
			else
				rope.Length = newLen
			end
		end
	end
	lastVel = vel
end)