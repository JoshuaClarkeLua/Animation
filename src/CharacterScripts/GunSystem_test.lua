local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local libs = game:GetService('ServerScriptService').ROJO
--local GunEquipSystem = require(libs.GunEquipSystem)
local ToolSystem = require(libs.ToolSystem)

local guns = workspace.Guns
local tool = ToolSystem.new(guns.TestGun:Clone())

local function newChar(char: Model)
	tool:equip(char.PrimaryPart)
end
local function newPlayer(player)
	if player.Character then newChar(player.Character) end
	player.CharacterAdded:Connect(newChar)
end

for _,player in pairs(Players:GetPlayers()) do newPlayer(player) end
Players.PlayerAdded:Connect(newPlayer)

-- GunEquipSystem.init()
-- GunEquipSystem.equip(script.Parent, 'TestGun')