local Vec3 = {}

--[[
	scalarProjection

	Returns scalar projection of va onto vb
	@param va - Vector to be projected
	@param vb - Vector to project onto
]]
local function scalarProjection(va: Vector3, vb: Vector3)
	return va:Dot(vb.Unit)
end

--[[
	Vec3.project

	Projects va onto vb
	@param va - Vector to be projected
	@param vb - Vector to project onto
]]
function Vec3.project(va: Vector3, vb: Vector3)
	return scalarProjection(va, vb) * vb.Unit
end

--[[
	Vec3.projectOnPlane

	Projects v onto plane defined by normal n
	@param v - Vector to be projected
	@param n - Plane normal
]]
function Vec3.projectOnPlane(v: Vector3, n: Vector3)
	return v - Vec3.project(v, n)
end

function Vec3.max(va: Vector3, vb: Vector3)
	return va.Magnitude >= vb.Magnitude and va or vb
end

return Vec3