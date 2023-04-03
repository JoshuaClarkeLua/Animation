local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService('RunService')

local libs = ReplicatedStorage.ROJO
local CharacterIKSystem = require(libs.CharacterIKSystem)




--[[
	TODO: Adjust character hip height (using Root Motor6D) based on:
	- Terrain inclination
	- Next step height
	- idk maybe something else (idk if necessary or not)
]]
CharacterIKSystem.init(script.Parent)