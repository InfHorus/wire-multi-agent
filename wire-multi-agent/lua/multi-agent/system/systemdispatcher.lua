WireMultiAgent 		= WireMultiAgent or {}
local self 		   	= {}
local include 	   	= include
local AddCSLuaFile 	= AddCSLuaFile
local tostring		= tostring
local type		   	= type
local setmetatable 	= setmetatable
local initTime  	= SysTime ()

function WireMultiAgent.MakeGateAway (SignalAccelerator, SignalFilter, ISaveMap)
    SignalFilter [ISaveMap] = SignalAccelerator
end

function self:WeakKeys ()
    local weakTable = {}
	
    setmetatable (weakTable, 
		{
			__mode = "k" 
		}
	)
	
    return weakTable
end

function self:TimeTracker ()
	local startupTime = SysTime () 
	startupTime 	  = startupTime - initTime
	
	return string.format ("%02d:%02d", math.floor (startupTime / 60), math.floor (startupTime % 60), math.floor (startupTime * 1000 % 1000))
end

function self:InternalId ()
	return "WireMultiAgent:SystemDispatcher"
end

function self:Constructor ()
	self.LoadFile = self:WeakKeys ()
	
	self.LoadFile [#self.LoadFile + 1] = "multi-agent/controllers/wire-multi-agent-initializer.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|multi-agent/system/resources.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|multi-agent/administration/programlogs.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|multi-agent/stylometry/submission.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|multi-agent/playersessions/handleplayers.lua"
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|multi-agent/playersessions/clienthandler.lua"
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|multi-agent/matching/signalprocessor.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|multi-agent/serialization/serializebufferoutput.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|multi-agent/serialization/minutiae.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|multi-agent/serialization/irconcept.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|multi-agent/serialization/stylometryfirststep.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|multi-agent/serialization/coderefactoringserializer.lua"
	self.LoadFile [#self.LoadFile + 1] = "SERVER|multi-agent/administration/responsehandler.lua"
	
	
	self.LoadFile [#self.LoadFile + 1] = "CLIENT|multi-agent/controllers/classesmegastructure.lua"
end

function self:ParseCorrectFiles (_)
	if string.sub (self, 1, 6) == "SERVER" then
		return true
	else
		return false
	end
end

function self:DispatchFiles (file, server)
	if type (self) ~= "table" and not file then
		file = tostring (self)
	end
	if file ~= nil then
		AddCSLuaFile (file)
		include (file)

		return "> Dispatched > " .. file .. "."
	else
		if type (self) == "table" then
			return self:InternalId () .. ".DispatchFiles : Empty allocation provided."
		else
			return self:InternalId () .. ".DispatchFiles : Empty allocation provided."
		end
	end
end

function self:GetStateStatus (status)
	if status then
		return true
	end
end

self:Constructor ()
WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())
self:DispatchFiles (self.LoadFile [1])
