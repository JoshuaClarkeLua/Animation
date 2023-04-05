local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService('RunService')

local libs = ReplicatedStorage.ROJO
local AssemblyUtil = require(libs.AssemblyUtil)
local Vec3 = require(libs.Vec3)
local Debug = require(libs.Debug)

local FOOT_LOCK_DIST = .4
local FOOT_MAXLOCK_DIST = .1
local LEG_LOCK_THRESH = .12

local CharacterIK = {}

--[[
	Legs
]]
local function raycastFoot(
	rootCF: CFrame, 
	footCF: CFrame, 
	footSize: Vector3, 
	raycastParams: RaycastParams
)
	local rayDirection = (footCF.Position-rootCF.Position)
	rayDirection = rayDirection+rayDirection.Unit*(footSize.Magnitude/2+FOOT_LOCK_DIST)
	local rayOrigin = rootCF.Position
	--[[
		TODO: IDEA (not super necessary)
			1. With first ray, check the inclination (normal) of the surface.
			2. Use the first ray to determine where to shoot the second.
				Shoot the ray toward the inclination so that we get the smallest distance
				from the foot to the surface.
			3. Use the second ray for the distance parameter
	]]
	local ray = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if not ray then return end
	local footDist = ray.Position - footCF.Position + footSize*Vector3.yAxis/2
	local distance = footDist.Unit:Dot(ray.Normal) > 0 and 0 or footDist.Magnitude
	return ray, distance
end

local function raycastLeg(
	rootCF: CFrame, 
	footCF: CFrame, 
	footSize: Vector3, 
	raycastParams: RaycastParams
)
	local footPos = footCF.Position-(footCF.UpVector*footSize.Y/2)
	local distFromRoot = Vec3.project(footPos-rootCF.Position, rootCF.UpVector)
	local rayOrigin = footPos-distFromRoot
	local rayDirection = distFromRoot*5
	local ray = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if not ray then return end

	local distance = ray.Distance-distFromRoot.Magnitude
	--Debug.drawRay(rayOrigin, rayDirection, true).Color = Color3.new(0,1,0)
	return ray, distance
end

function CharacterIK.setFootIK(
	IK: IKControl, 
	rootCF: CFrame, 
	footCF: CFrame,
	footSize: Vector3,
	raycastParams: RaycastParams
)
	IK.Enabled = false
	local ray, distance = raycastLeg(rootCF, footCF, footSize, raycastParams)
	if not ray then return end
	local target, normal = ray.Instance, ray.Normal
	local angle, rotAxis, weight

	if distance > FOOT_LOCK_DIST then return end
	if rootCF.Position:Dot(normal) == 1 then return end
	
	angle = math.acos(rootCF.UpVector:Dot(normal))
	if angle == 1 then return end
	rotAxis = rootCF.UpVector:Cross(normal).Unit
	if rotAxis.Magnitude ~= rotAxis.Magnitude then return end
	weight = 1-distance/FOOT_LOCK_DIST

	IK.Enabled = true
	IK.Target = target
	IK.Offset = target.CFrame.Rotation:Inverse()*CFrame.fromAxisAngle(rotAxis, angle)*rootCF.Rotation
	IK.Weight = weight

end

function CharacterIK.setLegIK(
	legIK: IKControl,
	footIK: IKControl,
	rootCF: CFrame, 
	footCF: CFrame,
	footSize: Vector3,
	raycastParams: RaycastParams
)
	legIK.Enabled = false
	footIK.Enabled = false
	local ray, distance = raycastLeg(rootCF, footCF, footSize, raycastParams)
	if not ray then return end
	local target, normal, position = ray.Instance, ray.Normal, ray.Position
	local angle, rotAxis, rotCF
	local legWeight, footWeight

	-- Set leg IK
	if distance <= LEG_LOCK_THRESH then
		legWeight = 1-distance/LEG_LOCK_THRESH
		legIK.Enabled = true
		legIK.Target = target
		legIK.Weight = legWeight
		legIK.Offset = CFrame.new(target.CFrame:PointToObjectSpace(position+normal*footSize.Y/2))
	end

	-- Get rotation
	angle = math.acos(rootCF.UpVector:Dot(normal))
	if angle == 1 then return end
	rotAxis = rootCF.UpVector:Cross(normal)
	if rotAxis.Magnitude == 0 then return end
	rotAxis = rotAxis.Unit
	rotCF = target.CFrame.Rotation:Inverse()*CFrame.fromAxisAngle(rotAxis, angle)*rootCF.Rotation

	-- Apply rotation to leg IK (Using IKType = Position wouldn't work so I had to resort to this)
	legIK.Offset *= rotCF

	-- Set foot IK
	if distance <= FOOT_LOCK_DIST then
		footWeight = 1-distance/FOOT_LOCK_DIST
		footIK.Enabled = true
		footIK.Target = target
		footIK.Offset = rotCF
		footIK.Weight = footWeight
	end
end

function CharacterIK.getHipOffset(humanoid: Humanoid, raycastParams: RaycastParams): Vector3?
	local rootPart = humanoid.RootPart
	local rootCF = rootPart.CFrame
	local hipHeight = humanoid.HipHeight
	local minHipHeight = hipHeight/2
	local hipOffset = Vector3.new()

	local rayOrigin = rootCF.Position-rootCF.UpVector*rootPart.Size.Y/2
	local rayDirection = -rootCF.UpVector*hipHeight*2
	local ray = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if ray and ray.Normal ~= Vector3.yAxis then
		local normal = ray.Normal
		local incline = Vector3.yAxis:Cross(normal):Cross(normal).Unit
		rayOrigin = rayOrigin+incline*Vector3.new(rootPart.Size.Z/2,0,rootPart.Size.X/2)
		Debug.drawRay(rayOrigin, rayDirection, true)
		ray = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		if ray then
			hipOffset = -rootCF.UpVector*math.min(ray.Distance-hipHeight, minHipHeight)
		end
	end

	return hipOffset
end

return CharacterIK