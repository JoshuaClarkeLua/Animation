type ToolChar = {
	leftArmIK: IKControl,
	rightArmIK: IKControl,
	equippedTool: Tool?,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService('ContextActionService')
local Signal = require(ReplicatedStorage.Packages.Signal)



--[[

	Tool

]]
local Tool = {}
Tool.__index = Tool

local function getArmIK(character: Model, arm: 'Left' | 'Right')
	local upperArm = character:FindFirstChild(arm..'UpperArm')
	local hand = character:FindFirstChild(arm..'Hand')
	local ikControl = Instance.new('IKControl')
	ikControl.SmoothTime = 0
	ikControl.Type = Enum.IKControlType.Transform
	ikControl.ChainRoot = upperArm
	ikControl.EndEffector = hand
	ikControl.Enabled = true
	ikControl.Parent = upperArm
	return ikControl
end

local function getCharacter(character: Model)
	local toolChar = {
		leftArmIK = getArmIK(character, 'Left'),
		rightArmIK = getArmIK(character, 'Right'),
	}
end


function Tool.new(model: Model)
	local self = setmetatable({}, Tool)
	self.model = model
	self.onPrimaryAction = Signal.new()
	self.onSecondaryAction = Signal.new()

	-- Get grips
	local gripPart = model:FindFirstChild('Grip')
	assert(gripPart, "BasePart 'Grip' missing")
	assert(gripPart:IsA('BasePart'), "Invalid 'Grip', expected BasePart")
	local leftGrip = gripPart:FindFirstChild('LeftGrip')
	assert(leftGrip, "Attachment 'LeftGrip' missing")
	assert(leftGrip:IsA('Attachment'), "Invalid 'LeftGrip', expected Attachment")
	local rightGrip = gripPart:FindFirstChild('RightGrip')
	assert(rightGrip, "Attachment 'RightGrip' missing")
	assert(rightGrip:IsA('Attachment'), "Invalid 'RightGrip', expected Attachment")
	local gripOffset = gripPart:FindFirstChild('Offset')
	assert(gripOffset, "Attachment 'Offset' missing")
	assert(gripOffset:IsA('Attachment'), "Invalid 'Offset', expected Attachment")
	local grip = {
		part = gripPart,
		left = leftGrip,
		right = rightGrip,
		offset = gripOffset,
	}
	for _,grip in pairs(grip) do
		if grip:IsA('Attachment') then
			grip.CFrame *= CFrame.fromAxisAngle(Vector3.new(0,1,0), -math.pi*.5)
		end
	end
	self.grip = grip

	-- Setup Root Motor
	local rootMotor = Instance.new('Motor6D')
	rootMotor.Name = 'Root'
	rootMotor.Part0 = gripPart
	rootMotor.Parent = gripPart
	local motors = {
		root = rootMotor
	}
	self.motors = motors

	return self
end
export type Tool = typeof(Tool.new(...))

function Tool.equip(self: Tool, gripPart: BasePart)
	-- Setup Root motor
	local rootMotor = self.motors.root
	rootMotor.Part1 = gripPart
	rootMotor.C0 = self.grip.offset.CFrame
	-- Parent tool to workspace
	self.model.Parent = workspace
end

return Tool