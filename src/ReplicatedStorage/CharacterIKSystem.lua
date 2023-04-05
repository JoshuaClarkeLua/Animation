type LegIK = {
	Leg: IKControl,
	Foot: IKControl,
}

type CharacterIK = {
	Right: {} & LegIK,
	Left: {} & LegIK,
}

local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local libs = ReplicatedStorage.ROJO
local AssemblyUtil = require(libs.AssemblyUtil)
local CharacterIK = require(libs.CharacterIK)
local Vec3 = require(libs.Vec3)
local Lerp = require(libs.Lerp)

local CharacterIKSystem = {}

local function newFootIK(character: Model, leg: 'Left' | 'Right')
	local name = leg..'Foot'
	local foot = character:FindFirstChild(name)
	local IKControl = Instance.new('IKControl')
	IKControl.Name = name
	IKControl.Type = Enum.IKControlType.Rotation
	IKControl.SmoothTime = 0
	IKControl.Priority = 3
	IKControl.ChainRoot = foot
	IKControl.EndEffector = foot
	IKControl.Parent = foot
	return IKControl
end

local function newLegIK(character: Model, leg: 'Left' | 'Right')
	local upperLeg = character:FindFirstChild(leg..'UpperLeg')
	local foot = character:FindFirstChild(leg..'Foot')
	local IKControl = Instance.new('IKControl')
	IKControl.Name = leg..'Leg'
	IKControl.Type = Enum.IKControlType.Transform
	IKControl.SmoothTime = 0
	IKControl.Priority = 2
	IKControl.ChainRoot = upperLeg
	IKControl.EndEffector = foot
	IKControl.Parent = upperLeg
	return IKControl
end

function getIK(character: Model): CharacterIK
	return {
		Right = {
			Leg = newLegIK(character, 'Right'),
			Foot = newFootIK(character, 'Right')
		},
		Left = {
			Leg = newLegIK(character, 'Left'),
			Foot = newFootIK(character, 'Left')
		},
	}
end

function applyLegIK(
	leg: 'Left' | 'Right', 
	character: Model, 
	IK: CharacterIK, 
	animCFs: {[Instance]: CFrame},
	raycastParams: RaycastParams
)
	local rootPart = character.PrimaryPart
	local foot = character:FindFirstChild(leg..'Foot')
	local footCF = rootPart.CFrame * animCFs[foot]
	local footIK = IK[leg].Foot
	local legIK = IK[leg].Leg

	local ray, distance = CharacterIK.raycastLeg(rootPart, footCF, foot.Size, raycastParams)
	CharacterIK.setLegIK(legIK, footIK, rootPart.CFrame, foot.Size, ray, distance)
	return ray, distance
end

local function getHipOffset(
	leg: 'Left' | 'Right',
	character: Model,
	footCF: CFrame,
	raycastParams: RaycastParams
)
	local humanoid = character:FindFirstChild('Humanoid')
	local rootPart = humanoid.RootPart
	local foot = character:FindFirstChild(leg..'Foot')
	local footCF = rootPart.CFrame * animCFs[foot]

	return CharacterIK.getHipOffset(humanoid, footCF, foot.Size, raycastParams)
end

--[[
	initPreIK

	NOTE: This function is intended to be fired by RunService.Stepped
	- Saves character Motor6D transforms modified by currently playing AnimationTracks
	- Checks if applied animation transform makes feet touch ground. Sets IKControls accordingly
]]
local function initPreIK(character: Model, IK: CharacterIK)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}
	local motors = AssemblyUtil.getAssemblyMotors(character)
	local humanoid = character:FindFirstChild('Humanoid')
	local leftFoot = character:FindFirstChild('LeftFoot')
	local rightFoot = character:FindFirstChild('RightFoot')
	local rootPart = humanoid.RootPart

	local hipOffset
	local lastHipOffset = Vector3.new()
	return function(dt: number)
		if character.Parent ~= workspace then return end
		
		local rootCF = rootPart.CFrame
		local leftFootCF = rootCF*AssemblyUtil.getPartAnimCFrame(leftFoot, motors)
		local rightFootCF = rootCF*AssemblyUtil.getPartAnimCFrame(rightFoot, motors)

		--[[
			Adjust Hip height
		]]
		local root = motors.children[1]
		hipOffset = Vec3.max(
			CharacterIK.getHipOffset(humanoid, leftFootCF, leftFoot.Size, raycastParams),
			CharacterIK.getHipOffset(humanoid, rightFootCF, rightFoot.Size, raycastParams)
		)
		lastHipOffset = Lerp.Vector3(lastHipOffset, hipOffset, .01, dt)
		root.motor.Transform += lastHipOffset
		print(lastHipOffset)

		local animCFs = AssemblyUtil.getAssemblyAnimCFrames(motors)
		leftFootCF = rootCF*animCFs[leftFoot]
		rightFootCF = rootCF*animCFs[rightFoot]

		--[[
			Adjust feet
		]]
		-- Left foot
		CharacterIK.setLegIK(IK.Left.Leg, IK.Left.Foot, rootPart, leftFootCF, leftFoot.Size, raycastParams)
		-- Right foot
		CharacterIK.setLegIK(IK.Right.Leg, IK.Right.Foot, rootPart, rightFootCF, rightFoot.Size, raycastParams)
		
	end
end

-- local function initPostIK()
-- 	return function()
-- 		if character.Parent ~= workspace then return end
-- 	end
-- end

function CharacterIKSystem.init(character: Model)
	local IK = getIK(character)
	local preIKConn = RunService.Stepped:Connect(initPreIK(character, IK))
	--local postIKConn = RunService.PreSimulation:Connect(postIK(character, IK))

	character.Destroying:Connect(function()
		preIKConn:Disconnect()
		--postIKConn:Disconnect()
	end)
end

return CharacterIKSystem