-- Character head top always facing grappling point

-- Character distance away from grappling point confined

-- Gravity acts against the upward velocity of the character (stopping it from easily doing full rotations)


local RunService = game:GetService('RunService')
local InputService = game:GetService('UserInputService')
local ContextActionService = game:GetService('ContextActionService')

local libs = game:GetService('ReplicatedStorage').ROJO
local Lerp = require(libs.Lerp)
local Vec3 = require(libs.Vec3)

local GRAPPLE_KEY = Enum.KeyCode.Space
local RAY_PARAMS = RaycastParams.new()
local GRAPPLE_SPEED = 5
local GRAPPLE_MAX_DIST = 1000000
local GRAPPLE_LEN = 20

local char = script.Parent
local humanoid = char.Humanoid
local rootPart: Part = humanoid.RootPart
rootPart.CustomPhysicalProperties = PhysicalProperties.new(.7,0,0,0,0)
local rootAttachment: Attachment = rootPart:FindFirstChild('RootRigAttachment') :: Attachment
local camera = workspace.CurrentCamera

local grappling = false
local currentGrapple: RaycastResult
local grapplePart: Part
local floorMaterial: Enum.Material = Enum.Material.Plastic

local partFilter = {char}
RAY_PARAMS.FilterDescendantsInstances = partFilter
RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
ContextActionService:BindAction('Grapple', function(_,istate,iobj)
	if istate == Enum.UserInputState.Begin then
		local mousePos = InputService:GetMouseLocation()
		local cRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
		local res = workspace:Raycast(cRay.Origin, cRay.Direction*GRAPPLE_MAX_DIST, RAY_PARAMS)
		if res then
			local rayOrigin: Vector3 = rootPart.Position
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
				-- rope.Restitution = .35
				rope.Parent = part
				
-- 
-- 				lineForce.Attachment1 = attachment
-- 				lineForce.Magnitude = GRAPPLE_SPEED*10*rootPart.AssemblyMass
				
				part.Parent = workspace
				humanoid:ChangeState(Enum.HumanoidStateType.Physics)

				currentGrapple = res
				grapplePart = part
				GRAPPLE_LEN = (currentGrapple.Position - rootPart.Position).Magnitude
				grappling = true
				floorMaterial = Enum.Material.Air
			end
		end
	else
		if grappling then
			grappling = false
			grapplePart:Destroy()
		end
	end
end, true, GRAPPLE_KEY)

local lastVel = rootPart.AssemblyLinearVelocity
local lastGrappleDir = lastVel
RunService.PostSimulation:Connect(function(dt)
	local vel = rootPart.AssemblyLinearVelocity
	local acc = vel - lastVel
	if grappling then
		local grappleDir = currentGrapple.Position - rootPart.Position
		local charDist = grappleDir.Magnitude
		local grappleDirU = grappleDir.Unit

		local forceDir = Vector3.zero
		if humanoid.MoveDirection.Magnitude > 0 then
			forceDir = Vec3.projectOnPlane(humanoid.MoveDirection, Vector3.new(grappleDirU.X,0,grappleDirU.Z))
		end
		rootPart:ApplyImpulse(forceDir*GRAPPLE_SPEED*rootPart.AssemblyMass)

		local rope = grapplePart:FindFirstChildOfClass('RopeConstraint')
		GRAPPLE_LEN -= 4
		rope.Length = GRAPPLE_LEN
		lastGrappleDir = forceDir
	end
	lastVel = vel
end)

RunService.PreSimulation:Connect(function(dt)
	if not grappling and floorMaterial == Enum.Material.Air then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {char}
		local charBox, size = char:GetBoundingBox()
		local rayOrigin = charBox.Position
		-- Get prediction for velocity
		local velocityExtra = rootPart.AssemblyLinearVelocity.Y*dt
		--
		local rayDirection = -charBox.UpVector*(size.Y/1.99+velocityExtra)
		local res = workspace:Raycast(rayOrigin, rayDirection, params)
		if res then
			floorMaterial = res.Instance.Material
			humanoid:ChangeState(Enum.HumanoidStateType.Landed)
		end
	end
end)