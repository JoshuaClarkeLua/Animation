local lerp = {}

--[[
	lerp.CFrame()

	@param a - Start CFrame
	@param b - End CFrame
	@param smooth - [0-1] Closer to 1 = faster transition
	@param dt - Time passed since last update
]]
function lerp.CFrame(a: CFrame, b: CFrame, smooth: number, dt: number)
	if smooth >= 1 then return b end
	return b:Lerp(a, math.pow(1-smooth, dt))
end

--[[
	lerp.Vector2()

	@param a - Start Vector2
	@param b - End Vector2
	@param smooth - [0-1] Closer to 1 = faster transition
	@param dt - Time passed since last update
]]
function lerp.Vector2(a: Vector2, b: Vector2, smooth: number, dt: number)
	if smooth >= 1 then return b end
	return b:Lerp(a, math.pow(1-smooth, dt))
end

--[[
	lerp.Vector3()

	@param a - Start Vector3
	@param b - End Vector3
	@param smooth - [0-1] Closer to 1 = faster transition
	@param dt - Time passed since last update
]]
function lerp.Vector3(a: Vector3, b: Vector3, smooth: number, dt: number)
	if smooth >= 1 then return b end
	return b:Lerp(a, math.pow(1-smooth, dt))
end

--[[
	lerp.value()

	@param a - Start value
	@param b - End value
	@param smooth - [0-1] Closer to 1 = faster transition
	@param dt - Time passed since last update
]]
function lerp.value(a: number, b: number, smooth: number, dt: number)
	if smooth >= 1 then return b end
	return b+(a-b)*math.pow(1-smooth, dt)
end

return lerp