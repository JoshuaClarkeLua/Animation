local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService('RunService')

local libs = ReplicatedStorage.ROJO
local CharacterIKSystem = require(libs.CharacterIKSystem)

local DUMMY = workspace.DUMMY
local WALK_ANIM = workspace.DUMMY.WalkAnim

local humanoid = DUMMY.Humanoid
local animator = humanoid.Animator
local animTrack = animator:LoadAnimation(WALK_ANIM)

animTrack.Looped = true
animTrack:Play(0,1,.25)


--[[
	TODO: Adjust character hip height (using Root Motor6D) based on:
	- Terrain inclination
	- Next step height
	- idk maybe something else (idk if necessary or not)
]]
CharacterIKSystem.init(DUMMY)