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

local CharacterIKSystem = {}

local function newFootIK(character: Model, leg: 'Left' | 'Right')
	local name = leg..'Foot'
	local foot = character:FindFirstChild(name)
	local IKControl = Instance.new('IKControl')
	IKControl.Name = name
	IKControl.Type = Enum.IKControlType.Rotation
	IKControl.SmoothTime = 0
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
	IKControl.Type = Enum.IKControlType.Position
	IKControl.SmoothTime = 0
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
	local rootCF = rootPart.CFrame
	local foot = character:FindFirstChild(leg..'Foot')
	local footCF = rootPart.CFrame * animCFs[foot]
	local footIK = IK[leg].Foot
	local legIK = IK[leg].Leg

	--[[
		Foot Rotation IK
	]]
	local enabled, 
		target, 
		normal, 
		distance, 
		position = CharacterIK.raycastLeg(rootPart, footCF, foot.Size, raycastParams)
	
	if enabled then
		CharacterIK.setFootIK(footIK, rootCF, target, normal, distance)
	else
		footIK.Enabled = false
	end

	--[[
		Leg Position
	]]
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
	return function()
		if character.Parent ~= workspace then return end

		local rootPart = character.PrimaryPart
		local animCFs = AssemblyUtil.getAssemblyAnimCFrames(AssemblyUtil.getAssemblyMotors(character))

		-- Left leg
		applyLegIK('Left', character, IK, animCFs, raycastParams)
		-- Right leg
		applyLegIK('Right', character, IK, animCFs, raycastParams)
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