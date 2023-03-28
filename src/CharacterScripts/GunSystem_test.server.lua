local Players = game:GetService("Players")
local libs = game:GetService('ServerScriptService').ROJO
local GunEquipSystem = require(libs.GunEquipSystem)

GunEquipSystem.init()
GunEquipSystem.equip(script.Parent, 'TestGun')