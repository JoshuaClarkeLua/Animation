local RunService = game:GetService('RunService')

local Lerp = require(game:GetService('ReplicatedStorage').ROJO.Lerp)

local char = script.Parent
local humanoid = char.Humanoid
local rootPart: Part = humanoid.rootPart
local waist = char.UpperTorso.Waist
local neck = char.Head.Neck
local WAISTC1_DEFAULT_CF = waist.C1
local NECKC1_DEFAULT_CF = neck.C1
local angle = 12

RunService.PreRender:Connect(function(dt)
	local moveDir: Vector3 = humanoid.MoveDirection

	if humanoid.WalkSpeed <= 1 or moveDir.Magnitude == 0 then
		waist.C1 = Lerp.CFrame(waist.C1, WAISTC1_DEFAULT_CF, .99, dt)
		neck.C1 = Lerp.CFrame(neck.C1, NECKC1_DEFAULT_CF, .99, dt)
	else
		local charVel: Vector3 = rootPart.CFrame:VectorToObjectSpace(rootPart.AssemblyLinearVelocity)
		local vX, vZ: number = charVel.X, charVel.Z
		local charSpeed: number = math.sqrt(vX*vX + vZ*vZ)
		-- Determine rotation axis
		local axis = rootPart.CFrame.UpVector:Cross(rootPart.CFrame:VectorToObjectSpace(-moveDir))
		-- Determine rotation angle
		local rotCF = CFrame.fromAxisAngle(axis, math.rad(angle*charSpeed/humanoid.WalkSpeed))
		waist.C1 = Lerp.CFrame(waist.C1, CFrame.new(waist.C1.Position)*rotCF, .99, dt)
		neck.C1 = Lerp.CFrame(neck.C1, CFrame.new(neck.C1.Position)*rotCF:Inverse(), .99, dt)
	end
end)