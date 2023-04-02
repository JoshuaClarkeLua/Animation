local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService('RunService')

local libs = ReplicatedStorage.ROJO
local AssemblyUtil = require(libs.AssemblyUtil)
local Vec3 = require(libs.Vec3)
local Debug = require(libs.Debug)

local DUMMY = workspace.DUMMY
local WALK_ANIM = workspace.DUMMY.WalkAnim

local humanoid = DUMMY.Humanoid
local rootPart = humanoid.RootPart
local animator = humanoid.Animator
local animTrack = animator:LoadAnimation(WALK_ANIM)

animTrack.Looped = true
animTrack:Play(0,1,.5)

local leftFoot = DUMMY.LeftFoot
local rightFoot = DUMMY.RightFoot
local IK = {
	LeftFoot = DUMMY.IK.LeftFoot,
	RightFoot = DUMMY.IK.RightFoot,
}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {DUMMY}


--[[
	IK Stuff
]]
local FOOT_LOCK_DIST = .4
local FOOT_MAXLOCK_DIST = .1

local function castLegRay(rootCF: CFrame, footAnimCF: CFrame, footSize: Vector3)
	local footCF = rootCF*footAnimCF
	local rayDirection = (footCF.Position-rootCF.Position)
	local rayDirU = rayDirection.Unit
	rayDirection = rayDirection+rayDirU*(footSize.Magnitude/2+FOOT_LOCK_DIST)
	local rayOrigin = rootCF.Position
	local ray = workspace:Raycast(rayOrigin, rayDirection, params)
	
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

local function applyFootIK(rootCF: CFrame, footAnimCF: CFrame, IK: IKControl, footSize: Vector3)
	local enabled, target, normal, distance = castLegRay(rootCF, footAnimCF, footSize)
	local angle, rotAxis, weight

	IK.Enabled = false
	if not enabled then return end
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
	IK.Enabled = true
end

local function applyLegIK(rootCF: CFrame, animCF: CFrame, IK: IKControl)
	
end

--[[
	preIK

	NOTE: This function is intended to be fired by RunService.Stepped
	- Saves character Motor6D transforms modified by currently playing AnimationTracks
	- Checks if applied animation transform makes feet touch ground. Sets IKControls accordingly
]]
local function preIK(dt: number)
	local animCFs = AssemblyUtil.getAssemblyAnimCFrames(AssemblyUtil.getAssemblyMotors(DUMMY))
	applyFootIK(rootPart.CFrame, animCFs[leftFoot], IK['LeftFoot'], leftFoot.Size)
	applyFootIK(rootPart.CFrame, animCFs[rightFoot], IK['RightFoot'], leftFoot.Size)
end

local function postIK(dt: number)
	-- print(workspace.B2.CFrame.UpVector)
	-- print(leftFoot.CFrame.UpVector)
end

local motors = AssemblyUtil.getAssemblyMotors(DUMMY)
RunService.Stepped:Connect(preIK)
RunService.PreSimulation:Connect(postIK)