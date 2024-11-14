if WireMultiAgent ["WireMultiAgent:SystemDispatcher"]:GetStateStatus (CLIENT) then
	return
end

local self   	= {}
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "WireMultiAgent:PlayerSession"
end

function self:Constructor ()
	self.PlayerSession = self.PlayerSession or {}
end

function self:CreatePlayerSession (ply)
	if not ply or not WireMultiAgent ["WireMultiAgent:ProgramLogs"]:IsPlayerValid_ (ply) then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Denied session creation due to invalid player.")
		
		return 
	end
	
	local playerName 		= ply:Nick () or ply:Name ()
	local playerId	 		= ply:SteamID 	()
	local uniquePlayerId 	= ply:SteamID64 ()
	
	if not self.PlayerSession [uniquePlayerId] then
		self.PlayerSession [uniquePlayerId] = 
		{
			["TotalCount"] 	= 0,
			["TotalSize"]	= 0,
			["Seed"]		= CurTime (),
			["Constructor"]	= "",
		}
	end
	
	WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Created player " .. playerName .. " (" .. playerId .. ")'s session.")
end

function self:DestroyPlayerSession (ply)
	if not ply or not WireMultiAgent ["WireMultiAgent:ProgramLogs"]:IsPlayerValid_ (ply) then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Denied session destruction due to invalid player.")
		
		return 
	end
	
	local playerName 		= ply:Nick () or ply:Name ()
	local playerId	 		= ply:SteamID 	()
	local uniquePlayerId 	= ply:SteamID64 ()
	
	if not self.PlayerSession [uniquePlayerId] then
		return
	end
	
	
	WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Destroyed player " .. playerName .. " (" .. playerId .. ")'s session.")
end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())
