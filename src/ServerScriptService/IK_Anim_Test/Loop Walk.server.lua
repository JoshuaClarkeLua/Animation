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
animTrack:Play(0,1,.05)

local leftFoot = DUMMY.LeftFoot
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
local FOOT_DISTANCE_ANGLE_LOCK_THRESH = 1
local function applyFootIK(rootCF: CFrame, animCF: CFrame, footSize: Vector3, IK: IKControl)
	local footCF = rootCF*animCF

	-- Cast ray
	local footDownV = -footCF.UpVector
	local rayDirection = (footCF.Position-rootCF.Position)
	local rayDirU = rayDirection.Unit
	rayDirection = rayDirection+rayDirU*(footSize.Magnitude/2+FOOT_DISTANCE_ANGLE_LOCK_THRESH)
	local rayOrigin = rootCF.Position
	local ray = workspace:Raycast(rayOrigin, rayDirection, params)
	--Debug.drawRay(rayOrigin, rayDirection, true)
	if ray then
		local pos, target: BasePart, normal = ray.Position, ray.Instance, ray.Normal
		local dist = (ray.Position - footCF.Position).Magnitude
		if dist >= 0 and dist < FOOT_DISTANCE_ANGLE_LOCK_THRESH then
			Debug.drawRay(rayOrigin, rayDirection, true).Color = Color3.new(1,0,0)
			-- Project foot lookvector onto plane defined by normal. Use angle between 
			-- projected lookvector and foot lookvector to determine rotation angle

			-- You basically don't need IK for this, use IK only for foot/leg position.
			-- Rotate foot Motor6D directly instead.

			-- REMEMBER: rotation is applied already by setting IK target

			--local offset = CFrame.fromAxisAngle(footCF.UpVector, angle)
			local weight = 1-dist/FOOT_DISTANCE_ANGLE_LOCK_THRESH
			IK.Enabled = true
			--IK.Target = target

			-- local rot = rootCF.UpVector:Dot(normal)
			-- if rot == 1 then return end
			-- rot = math.acos(rot)
			local axis = rootCF.UpVector:Cross(normal).Unit
			local incline = axis:Cross(normal)
			local inclineDir = rootCF.UpVector:Cross(axis)
			Debug.drawRay(footCF.Position, axis, true).Color = Color3.new(1,0,0)
			--Debug.drawRay(footCF.Position, inclineDir, true).Color = Color3.new(0,1,0)
			local xRot = normal:Dot(target.CFrame.RightVector)
			local zRot = normal:Dot(target.CFrame.LookVector)
			if xRot ~= 0 then
				
			end
			--local zRot = math.acos(math.clamp(normal:Dot(target.CFrame.)))
			--print(math.deg(xRot))
			IK.Offset = CFrame.new(0,-normal,0)--*CFrame.fromAxisAngle(animCF.RightVector, math.rad(90))
			--IK.EndEffectorOffset = CFrame.fromAxisAngle(rootCF.RightVector, xRot)
			--IK.Offset = CFrame.fromAxisAngle(rootCF.UpVector, math.rad(75))
			--IK.Weight = weight
		else
			IK.Enabled = false
		end
	end
end

local function applyFootIK2(rootCF: CFrame, animCF: CFrame, foot: BasePart, ankle: Motor6D)
	local footCF = rootCF*animCF

	-- Cast ray
	local footDownV = -footCF.UpVector
	local rayDirection = (footCF.Position-rootCF.Position)
	local rayDirU = rayDirection.Unit
	rayDirection = rayDirection+rayDirU*(foot.Size.Magnitude/2+FOOT_DISTANCE_ANGLE_LOCK_THRESH)
	local rayOrigin = rootCF.Position
	local ray = workspace:Raycast(rayOrigin, rayDirection, params)
	--Debug.drawRay(rayOrigin, rayDirection, true)
	if ray then
		local pos, target: BasePart, normal = ray.Position, ray.Instance, ray.Normal
		local dist = (ray.Position - footCF.Position).Magnitude
		if dist >= 0 and dist < FOOT_DISTANCE_ANGLE_LOCK_THRESH then
			--Debug.drawRay(rayOrigin, rayDirection, true).Color = Color3.new(1,0,0)

			local weight = 1-dist/FOOT_DISTANCE_ANGLE_LOCK_THRESH
			
			local rot = rootCF.UpVector:Dot(normal)
			if rot == 1 then return end
			print(rot)
			rot = math.acos(rootCF.UpVector:Dot(normal))
			local axis = rootCF.UpVector:Cross(normal).Unit
			local incline = axis:Cross(normal)
			local inclineDir = rootCF.UpVector:Cross(axis).Unit
			foot.CFrame = CFrame.new(foot.CFrame.Position)
			Debug.drawRay(footCF.Position, axis, true)
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
	--applyFootIK(rootPart.CFrame, animCFs[leftFoot], leftFoot.Size, IK['LeftFoot'])
	applyFootIK2(rootPart.CFrame, animCFs[leftFoot], leftFoot, leftFoot.LeftAnkle)
end

local function postIK(dt: number)
	-- print(workspace.B2.CFrame.UpVector)
	-- print(leftFoot.CFrame.UpVector)
end

local motors = AssemblyUtil.getAssemblyMotors(DUMMY)
RunService.Stepped:Connect(preIK)
RunService.PreSimulation:Connect(postIK)