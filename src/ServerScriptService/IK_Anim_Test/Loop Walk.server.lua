local Workspace = game:GetService("Workspace")
local RunService = game:GetService('RunService')

local DUMMY = workspace.DUMMY
local WALK_ANIM = workspace.DUMMY.WalkAnim

local humanoid = DUMMY.Humanoid
local animator = humanoid.Animator
local animTrack = animator:LoadAnimation(WALK_ANIM)

animTrack.Looped = true
animTrack:Play(0,1,.25)

local leftFoot = DUMMY.LeftFoot
local leftFootIK = DUMMY.IK.LeftFoot

--[[
	IK Stuff
]]
local animTransform = leftFoot.LeftAnkle.Transform

local function checkFoot(character: Model, IK: Folder, leg: 'Left' | 'Right')
	local foot = character:FindFirstChild(leg..'Foot') :: BasePart
	local ankle = foot:FindFirstChild(leg..'Ankle') :: Motor6D
	local footIK = IK:FindFirstChild(leg..'Foot') :: IKControl
	local lowerLeg = character:FindFirstChild(leg..'LowerLeg') :: BasePart
	local knee = lowerLeg:FindFirstChild(leg..'Knee') :: Motor6D

	local animTransform = ankle.Transform
	local newFootCF = foot.CFrame*knee
	local rayOrigin = foot.CFrame
	-- local ray = workspace:Raycast()
	local dummyFoot = workspace:FindFirstChild(leg..'Foot') :: BasePart
	dummyFoot.CFrame = newFootCF
end

--[[
	TODO: get the leg part positions relative to the HumanoidRootPart
		then you can convert to world-position and use to Raycast
		prior to the animation or IK positions updating.

		After this, you can use the raycast information and modify IK weights and offsets/targets prior
		to any updates.
]]
local function getLegCF(character: Model, IK: Folder, leg: 'Left' | 'Right')
	local upperLeg = character:FindFirstChild(leg..'UpperLeg') :: BasePart
	local hip = upperLeg:FindFirstChild(leg..'Hip') :: Motor6D
	local lowerLeg = character:FindFirstChild(leg..'LowerLeg') :: BasePart
	local knee = lowerLeg:FindFirstChild(leg..'Knee') :: Motor6D
	local foot = character:FindFirstChild(leg..'Foot') :: BasePart
	local ankle = foot:FindFirstChild(leg..'Ankle') :: Motor6D
	local footIK = IK:FindFirstChild(leg..'Foot') :: IKControl
end

--[[
	preIK

	NOTE: This function is intended to be fired by RunService.Stepped
	- Saves character Motor6D transforms modified by currently playing AnimationTracks
	- Checks if applied animation transform makes feet touch ground. Sets IKControls accordingly
]]
local function preIK(dt: number)
	--checkFoot(DUMMY, DUMMY.IK, 'Left')
end

local function postIK(dt: number)

end

RunService.Stepped:Connect(preIK)
RunService.PreSimulation:Connect(postIK)