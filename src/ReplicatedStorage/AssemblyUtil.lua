export type MotorHierarchyChild = {
	part: BasePart;
	motor: Motor6D;
	children: {MotorHierarchyChild}?
}
export type MotorHierarchy = {
	part: BasePart;
	children: {MotorHierarchyChild}?
}

local AssemblyUtil = {}

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


local getAssemblyMotors = nil
getAssemblyMotors = function(part: BasePart, motors: {Motor6D}): {MotorHierarchyChild}?
	local partMotors = getPartMotors(motors, part)
	if #partMotors == 0 then return end

	local children: {MotorHierarchyChild} = {}
	for _,motor in (partMotors) do
		local child = motor.Part0 == part and motor.Part1 or motor.Part0
		table.insert(children, {
			part = child,
			motor = motor,
			children = getAssemblyMotors(child, motors)
		})
	end
	return children
end

local getAssemblyAnimCFrames = nil
getAssemblyAnimCFrames = function(root: BasePart, motors: {MotorHierarchyChild}, cframes: {[BasePart]: CFrame})
	local rootCF = cframes[root] or CFrame.new()
	for i,motor in ipairs(motors) do
		local cf = rootCF*motor.motor.C0*motor.motor.Transform*motor.motor.C1:Inverse()
		cframes[motor.part] = cf
		if motor.children then
			getAssemblyAnimCFrames(motor.part, motor.children, cframes)
		end
	end
	return cframes
end

local getPartAnimCFrame = nil
getPartAnimCFrame = function(part: BasePart, motor: MotorHierarchyChild): CFrame?
	local rootMotor = motor.motor
	local rootCF = rootMotor.C0*rootMotor.Transform*rootMotor.C1:Inverse()
	if motor.part == part then return rootCF end
	if not motor.children then return end
	for i,motor in ipairs(motor.children) do
		local cf = getPartAnimCFrame(part, motor)
		if cf then
			return rootCF*cf
		end
	end
	return
end

--[[
	getAssemblyMotors

	Makes a hierarchical list of the motors present in the assembly within model
	starting from motors connected to the AssemblyRootPart.
]]
function AssemblyUtil.getAssemblyMotors(model: Model): MotorHierarchy
	local rootPart = getAssemblyRootPart(model)
	assert(rootPart, "Model has no parts")
	return {
		part = rootPart,
		children = getAssemblyMotors(rootPart, getModelMotors(model))
	}
end

--[[
	getAssemblyAnimCFrames

	Returns a list of CFrames by applying Motor6D C0, Transform, C1 properties
	respectively starting from the motors which are connected to the AssemblyRootPart.
	
	The CFrames are meant to be in object space (i.e. relative to the AssemblyRootPart)

	Use this to get an assembly's raw animation CFrame data prior to other roblox
	processes modifying the Motor6D.Transform property (i.e. IKControl)
]]
function AssemblyUtil.getAssemblyAnimCFrames(motors: MotorHierarchy)
	return getAssemblyAnimCFrames(motors.part,motors.children,{})
end

function AssemblyUtil.getPartAnimCFrame(part: BasePart, motors: MotorHierarchy): CFrame?
	if motors.part == part then return CFrame.new() end
	if not motors.children then return end
	for _,motor in ipairs(motors.children) do
		local cf = getPartAnimCFrame(part, motor)
		if cf then return cf end
	end
	return
end

return AssemblyUtil