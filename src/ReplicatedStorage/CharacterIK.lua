local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService('RunService')

local libs = ReplicatedStorage.ROJO
local AssemblyUtil = require(libs.AssemblyUtil)
local Vec3 = require(libs.Vec3)
local Debug = require(libs.Debug)

local FOOT_LOCK_DIST = .4
local FOOT_MAXLOCK_DIST = .1

local CharacterIK = {}

--[[
	Legs
]]
function CharacterIK.raycastLeg(
	rootCF: CFrame, 
	footCF: CFrame, 
	footSize: Vector3, 
	raycastParams: RaycastParams
)
	local rayDirection = (footCF.Position-rootCF.Position)
	rayDirection = rayDirection+rayDirection.Unit*(footSize.Magnitude/2+FOOT_LOCK_DIST)
	local rayOrigin = rootCF.Position
	local ray = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	--[[
		TODO: IDEA (not super necessary)
			1. With first ray, check the inclination (normal) of the surface.
			2. Use the first ray to determine where to shoot the second.
				Shoot the ray toward the inclination so that we get the smallest distance
				from the foot to the surface.
			3. Use the second ray for the distance parameter
	]]

	if ray then
		local footDist = ray.Position - footCF.Position + footSize*Vector3.yAxis/2
		local distance = footDist.Unit:Dot(ray.Normal) > 0 and 0 or footDist.Magnitude
		return true, ray.Instance, ray.Normal, distance, ray.Position
	end
	return false
end

function CharacterIK.setFootIK(
	IK: IKControl, 
	rootCF: CFrame, 
	target: BasePart, 
	normal: Vector3, 
	distance: number
)
	local angle, rotAxis, weight
	
	IK.Enabled = false
	if distance > FOOT_LOCK_DIST then return end
	if rootCF.Position:Dot(normal) == 1 then return end

	angle = math.acos(rootCF.UpVector:Dot(normal))
	if angle == 1 then return end
	rotAxis = rootCF.UpVector:Cross(normal).Unit
	if rotAxis.Magnitude ~= rotAxis.Magnitude then return end
	weight = 1-distance/FOOT_LOCK_DIST

	IK.Enabled = true
	IK.Target = target
	IK.Offset = target.CFrame.Rotation:Inverse()
	IK.EndEffectorOffset = CFrame.fromAxisAngle(rotAxis, -angle)
	IK.Weight = weight

end

local function setLegIK(
	IK: IKControl,
	rootCF: CFrame, 
	animCF: CFrame
)
	
end



return CharacterIK