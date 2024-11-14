local include 	   = include
local AddCSLuaFile = AddCSLuaFile

if SERVER then
	AddCSLuaFile ("multi-agent/system/systemdispatcher.lua")
end

include ("multi-agent/system/systemdispatcher.lua")

print("je load shit" .. "\n")
print("loaded include wiredev")