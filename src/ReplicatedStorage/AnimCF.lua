type CFrameHierarchy = {
	root: BasePart;
	cf: CFrame;
	children: {CFrameHierarchy}?
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

local getPartCFrames = nil
getPartCFrames = function(model: Model, root: BasePart, rootCF: CFrame, motor: Motor6D?)
	if not motor then return end
	-- Get child part
	local child = motor.Part0 == root and motor.Part1 or motor.Part0
	-- Apply CFrame transformations to child part's CFrame
	-- and return the result
	local animCF = rootCF*motor.C0*motor.C1:Inverse()*motor.Transform
	return animCF, getPartCFrames(model, child, animCF, getPartCFrames(model, child))
end

local getAssemblyCFrames = nil
getAssemblyCFrames = function(cfs: CFrameHierarchy, motors: {Motor6D}): CFrameHierarchy
	local partMotors = getPartMotors(motors, cfs.root)
	if #motors == 0 then return cfs end

	local children = {}	
	for _,motor in (partMotors) do
		local root = motor.Part0 == cfs.root and motor.Part1 or motor.Part0
		table.insert(children, getAssemblyCFrames({
			root = root,
			cf = cfs.cf*motor.C0*motor.C1:Inverse()*motor.Transform
		}, motors))
	end
	cfs.children = children
	return cfs
end

--[[
	AnimCF - function

	NOTE: Use this within RunService.Stepped. The Motor6D.Transform property is overwritten by its Animator
		prior to RunService.Stepped.
]]
return function(model: Model)
	local rootPart = getAssemblyRootPart(model)
	assert(rootPart, "Model has no parts")
	return getAssemblyCFrames({
		root = rootPart,
		cf = CFrame.new()
	}, getModelMotors(model))
end
