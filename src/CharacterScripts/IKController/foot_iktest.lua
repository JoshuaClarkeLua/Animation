local RunService = game:GetService("RunService")
local char = script.Parent.Parent.Parent
local humanoid = char.Humanoid
local rootPart = humanoid.RootPart
local animator = humanoid.Animator

local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
RAYCAST_PARAMS.FilterDescendantsInstances = {char}

local IKControls = {}

local function initLegIK(leg: "Left" | "Right")
	local ik = Instance.new('IKControl')
	ik.Type = Enum.IKControlType.Position
	ik.SmoothTime = 0
	ik.Weight = 1
	ik.ChainRoot = char[leg.."UpperLeg"]
	ik.EndEffector = char[leg.."Foot"]
	IKControls[leg] = ik
end

local function getLegIKPos(leg: "Left" | "Right")
	local ik = IKControls[leg]
	local hip = char[leg.."UpperLeg"][leg.."Hip"]
	local foot = char[leg.."Foot"]

	-- Get the direction of the foot relative to the Motor6D

	local origin = rootPart.CFrame:PointToWorldSpace(hip.C0.Position)
	local dir = -rootPart.CFrame.UpVector*humanoid.HipHeight+.1
	local res = workspace:Raycast(origin, dir, RAYCAST_PARAMS)
	-- Disable IK if ray didn't touch anything
	if not res or not res.Target then ik.Enabled = false end

end

local p = Instance.new('Part')
p.Size = Vector3.new(.2,.2,100)
p.Color = Color3.new(1,0,0)
p.CanCollide = false
p.Anchored = true
p.Parent = workspace
local function check(leg: "Left" | "Right")
	local ankle = char[leg.."Foot"][leg.."Ankle"]
	p.CFrame = ankle.Transform
end

local function init()
	initLegIK("Left")
	initLegIK("Right")


end

-- RunService.Stepped:Connect(function()
-- 	local dir = -rootPart.CFrame.UpVector*100
-- 	local origin, res
-- 	local target
-- 	-- left leg
-- 	origin = rootPart.CFrame:PointToWorldSpace(leftUpperLeg.LeftHip.C0.Position)
-- 	res = workspace:Raycast(origin, dir, rayParams)
-- 	if res then
-- 		target = res.Instance
-- 		if target then
-- 			leftIK.Target = target
-- 			leftIK.Offset = CFrame.new(target.CFrame:PointToObjectSpace(res.Position+Vector3.one*leftFoot.Size.Y/2*rootPart.CFrame.UpVector))
-- 		else
-- 			leftIK.Enabled = false
-- 		end
-- 	end
-- 	-- right leg
-- 	origin = rootPart.CFrame:PointToWorldSpace(rightUpperLeg.RightHip.C0.Position)
-- 	res = workspace:Raycast(origin, dir, rayParams)
-- 	if res then
-- 		target = res.Instance
-- 		if target then
-- 			rightIK.Target = target
-- 			rightIK.Offset = CFrame.new(target.CFrame:PointToObjectSpace(res.Position+Vector3.one*rightFoot.Size.Y/2*rootPart.CFrame.UpVector))
-- 		else
-- 			rightIK.Enabled = false
-- 		end
-- 	end
-- end)



--Up and down motion for testing
-- rootPart.Anchored = true
-- local init = rootPart.CFrame
-- RunService.Stepped:Connect(function()
-- 	rootPart.CFrame = init+Vector3.yAxis*(math.sin(os.clock()*10)-.8)
-- end)
