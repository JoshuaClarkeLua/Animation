type MotorHierarchyChild = {
	part: BasePart;
	motor: Motor6D;
	children: {MotorHierarchyChild}?
}
type MotorHierarchyRoot = {
	part: BasePart;
	children: {MotorHierarchyChild}?
}

local function getPartMotors(motors: {Motor6D}, part: BasePart): {Motor6D?}
	local partMotors = {}
	local i = 1
	while i <= #motors do
		local motor = motors[i]
		if motor.Part0 == part or motor.Part1 == part then
			table.insert(partMotors, table.remove(motors, i))
			continue
		end
		i += 1
	end
	return partMotors
end

local function getModelMotors(model: Model)
	local motors = {}
	for _,motor in ipairs(model:GetDescendants()) do
		if motor:IsA('Motor6D') then
			table.insert(motors, motor)
		end
	end
	return motors
end

local function getAssemblyRootPart(model: Model): BasePart?
	local rootPart
	for _,part in (model:GetDescendants()) do
		if part:IsA('BasePart') then
			rootPart = part
			break
		end
	end
	if rootPart then rootPart = rootPart.AssemblyRootPart end
	return rootPart
end


local getAssemblyCFrames = nil
getAssemblyCFrames = function(part: BasePart, motors: {Motor6D}): {MotorHierarchyChild}?
	local partMotors = getPartMotors(motors, part)
	if #partMotors == 0 then return end

	local children: {MotorHierarchyChild} = {}
	for _,motor in (partMotors) do
		local child = motor.Part0 == part and motor.Part1 or motor.Part0
		table.insert(children, {
			part = child,
			motor = motor,
			children = getAssemblyCFrames(child, motors)
		})
	end
	return children
end

--[[
	AnimCF - function

	NOTE: Use this within RunService.Stepped. The Motor6D.Transform property is overwritten by its Animator
		prior to RunService.Stepped.
]]
return function(model: Model): MotorHierarchyRoot
	local rootPart = getAssemblyRootPart(model)
	assert(rootPart, "Model has no parts")
	return {
		part = rootPart,
		children = getAssemblyCFrames(rootPart, getModelMotors(model))
	}
end
