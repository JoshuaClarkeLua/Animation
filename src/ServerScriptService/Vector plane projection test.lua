
local libs = game:GetService('ReplicatedStorage').ROJO
local Lerp = require(libs.Lerp)
local Vec3 = require(libs.Vec3)

local va = Vector3.new(1,1,1).Unit
local vb = Vector3.new(0,1,0)


print(Vec3.projectOnPlane(va, vb).Magnitude)