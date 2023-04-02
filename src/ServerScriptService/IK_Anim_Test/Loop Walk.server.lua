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
animTrack:Play(0,1,.75)

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
local function applyFootIK(rootCF: CFrame, animCF: CFrame, footSize: Vector3, IK: IKControl)
	local footCF = rootCF*animCF

	-- Cast ray
	local footDownV = -footCF.UpVector
	local rayDirection = (footCF.Position-rootCF.Position)
	local rayDirU = rayDirection.Unit
	rayDirection = rayDirection+rayDirU*(footSize.Magnitude/2+FOOT_LOCK_DIST)
	local rayOrigin = rootCF.Position
	local ray = workspace:Raycast(rayOrigin, rayDirection, params)
	if ray then
		local pos, target: BasePart, normal = ray.Position, ray.Instance, ray.Normal
		local footDist = ray.Position - footCF.Position + footSize*Vector3.yAxis/2
		
		local dist = footDist.Unit:Dot(normal) > 0 and 0 or footDist.Magnitude
		if dist < FOOT_LOCK_DIST then

			local rot = rootCF.UpVector:Dot(normal)
			if rot == 1 then IK.Enabled = false; return end
			rot = math.acos(rot)
			local axis = rootCF.UpVector:Cross(normal).Unit
			if axis.Magnitude ~= axis.Magnitude then IK.Enabled = false; return end
			local incline = axis:Cross(normal)
			local weight = 1-dist/FOOT_LOCK_DIST

			IK.Enabled = true
			IK.Target = target
			IK.Offset = target.CFrame.Rotation:Inverse()
			IK.EndEffectorOffset = CFrame.fromAxisAngle(axis, -rot)
			IK.Weight = weight

			-- Debug.drawRay(rayOrigin, rayDirection, true).Color = Color3.new(1,0,0)
			-- Debug.drawRay(footCF.Position, incline, true).Color = Color3.new(0,0,1)
		else
			IK.Enabled = false
		end
	end
end

--[[
	preIK

	NOTE: This function is intended to be fired by RunService.Stepped
	- Saves character Motor6D transforms modified by currently playing AnimationTracks
	- Checks if applied animation transform makes feet touch ground. Sets IKControls accordingly
]]
local function preIK(dt: number)
	local animCFs = AssemblyUtil.getAssemblyAnimCFrames(AssemblyUtil.getAssemblyMotors(DUMMY))
	applyFootIK(rootPart.CFrame, animCFs[leftFoot], leftFoot.Size, IK['LeftFoot'])
	applyFootIK(rootPart.CFrame, animCFs[rightFoot], rightFoot.Size, IK['RightFoot'])
	--applyFootIK2(rootPart.CFrame, animCFs[leftFoot], leftFoot, leftFoot.LeftAnkle)
end

local function postIK(dt: number)
	-- print(workspace.B2.CFrame.UpVector)
	-- print(leftFoot.CFrame.UpVector)
end

local motors = AssemblyUtil.getAssemblyMotors(DUMMY)
RunService.Stepped:Connect(preIK)
RunService.PreSimulation:Connect(postIK)