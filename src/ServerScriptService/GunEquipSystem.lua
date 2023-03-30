type CharacterSetup = {
	leftArmIK: IKControl,
	rightArmIK: IKControl,
	equippedGun: GunState?,
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService('ServerStorage')

local GUN_MODELS = workspace.Guns

local GunSystem = {}
local characters: {[Model]: CharacterSetup} = {}


local function createGun(gunModel: Model)
	local model = gunModel:Clone()

	local handlePart = model:FindFirstChild('Handle')
	assert(handlePart, "BasePart 'Handle' missing")
	assert(handlePart:IsA('BasePart'), "Invalid 'Handle', expected BasePart")

	local leftHandle = handlePart:FindFirstChild('LeftHandle')
	assert(leftHandle, "Attachment 'LeftHandle' missing")
	assert(leftHandle:IsA('Attachment'), "Invalid 'LeftHandle', expected Attachment")

	local rightHandle = handlePart:FindFirstChild('RightHandle')
	assert(rightHandle, "Attachment 'RightHandle' missing")
	assert(rightHandle:IsA('Attachment'), "Invalid 'RightHandle', expected Attachment")

	local gripOffset = handlePart:FindFirstChild('GripOffset')
	assert(gripOffset, "Attachment 'GripOffset' missing")
	assert(gripOffset:IsA('Attachment'), "Invalid 'GripOffset', expected Attachment")
	--gripOffset.CFrame *= CFrame.fromAxisAngle(Vector3.new(1,0,0), math.rad(-90))

	local runGripOffset = handlePart:FindFirstChild('RunGripOffset')
	assert(runGripOffset, "Attachment 'RunGripOffset' missing")
	assert(runGripOffset:IsA('Attachment'), "Invalid 'RunGripOffset', expected Attachment")

	local rootMotor = Instance.new('Motor6D')
	rootMotor.Name = 'Root'
	rootMotor.Part0 = handlePart
	rootMotor.Parent = handlePart
	local gun = {
		model = model,
		handle = handlePart,
		motors = {
			root = rootMotor,
		},
		attachments = {
			gripOffset = gripOffset,
			runGripOffset = runGripOffset,
			leftHandle = leftHandle,
			rightHandle = rightHandle,
		},


		offset = Vector3.zero,
	}
	return gun
end
type GunState = typeof(createGun(...))

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
	if not characters[character] then
		local char = {
			leftArmIK = getArmIK(character, 'Left'),
			rightArmIK = getArmIK(character, 'Right'),
		}
		characters[character] = char
	end
	return characters[character]
end

function GunSystem.init()
	-- Setup Gun Models
	for _,model in ipairs(GUN_MODELS:GetChildren()) do
		for _,p in ipairs(model:GetDescendants()) do
			if p:IsA('BasePart') then
				p.Massless = true
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
			end
		end
	end

	--[[
		onCharacterRemoving

		Cleanup character instances
	]]
	local function onCharacterRemoving(characterModel: Model)
		if not characters[characterModel] then return end
		GunSystem.unequip(characterModel)
		characters[characterModel] = nil
	end
	local function onCharacterAdded(character: Model)
		character.Destroying:Connect(onCharacterRemoving)
	end
	local function onPlayerAdded(player: Player)
		if player.Character then onCharacterAdded(player.Character) end
		player.CharacterAdded:Connect(onCharacterAdded)
	end


	for _,player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	--[[
		Update Gun Animations
	]]
	local function onStepped(time: number, dt: number)
		for characterModel,character: CharacterSetup in pairs(characters) do
			local gun = character.equippedGun
			local humanoid = characterModel:FindFirstChild('Humanoid')
			if gun and humanoid then
				-- Add breathe offset
				local offset: Vector3
				local ofx, ofy, ofz = 0,0,0
				ofy = math.sin(time*2)/15
				offset = Vector3.new(ofx,ofy,ofz)
				-- Add run offset
				if humanoid.MoveDirection.Magnitude > 0 then
					ofx = (math.cos(time*10)*.5-.5)/5
					ofy = (math.sin(time*20)*.5-.5)/15
					offset = Vector3.new(ofx,ofy,0)
				end
				-- Update gun model offsets
				gun.motors.root.C1 = CFrame.new(offset)
				--gun.motors.root.C0 = gun.attachments.runGripOffset.CFrame
				--gun.motors.root.C1 *= CFrame.fromAxisAngle(Vector3.new(0,1,0).Unit, math.rad(30))
	
				-- Update offsets
				gun.offset = offset
			end
		end
	end
	RunService.Stepped:Connect(onStepped)
end

function GunSystem.equip(characterModel: Model, modelName: string)
	local model: Model? = GUN_MODELS:FindFirstChild(modelName)
	assert(model, "Gun model not found")
	-- Attach gun model to player
	local humanoid = characterModel:FindFirstChildOfClass('Humanoid')
	local rootPart = humanoid.RootPart
	local character = getCharacter(characterModel)
	local gun = createGun(model)
	local rootMotor = gun.motors.root
	local gripOffset = gun.attachments.gripOffset
	rootMotor.Part1 = rootPart
	rootMotor.C0 = gripOffset.CFrame


	-- Setup IKControls
	local leftArmIK, rightArmIK = character.leftArmIK, character.rightArmIK
	leftArmIK.Target = gun.attachments.leftHandle
	rightArmIK.Target = gun.attachments.rightHandle
	leftArmIK.Enabled = true
	rightArmIK.Enabled = true
	
	character.equippedGun = gun
	-- Put model in workspace
	gun.model.Parent = workspace
end

function GunSystem.unequip(characterModel: Model)
	local character = characters[characterModel]
	if character then
		character.equippedGun.model:Destroy()
		character.equippedGun = nil
	end
end


return GunSystem