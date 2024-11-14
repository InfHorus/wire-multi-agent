--self:SubmitExpression2 (playerName, playerSteamId, expression2Name, expression2Desc, expression2Code, expression2Lines, expression2Vars, expression2Functions, ply)
local self   	= {}
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "WireMultiAgent:SignalProcessor"
end

function self:Constructor ()
	self.Identifiers = {}
	
	self.Identifiers.Carriage 	 = "wire-multi-agent-carriage"
	self.Identifiers.Fingerprint = "wire-multi-agent-fingerprint"
	
	if WireMultiAgent ["WireMultiAgent:SystemDispatcher"]:GetStateStatus (SERVER) then
		for _, identifiers in pairs (self.Identifiers) do
			util.AddNetworkString (identifiers)
		end
		
		self.TransferExpression2Code = function (ply, codeUniqueHashing, uncompressedCarriage, e2Description, e2Sharing)
			WireMultiAgent ["WireMultiAgent:iSerializer"]:SerializeExpression2PlagiatCode (uncompressedCarriage, codeUniqueHashing, e2Description, e2Sharing, 0, ply)
		end
	end
end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())

if WireMultiAgent ["WireMultiAgent:SystemDispatcher"]:GetStateStatus (CLIENT) then
	return
end
-- Str::ctor per LivePlayerSession()
function self:ReceiveCarriage ()
	net.Receive (self.Identifiers.Carriage, function (_, ply)
		local playerId64 = ply:SteamID64 ()
		local playerName = ply:Nick 	 () or ply:Name ()
		local playerId	 = ply:SteamID 	 ()
		
		if not WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] then
			WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: Received a network from a player without LivePlayerSession! " .. playerName .. "(" .. playerId .. ")")
			
			return
		end
		
		if not WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Constructor"] then 
			WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = ""
		end
		
		if WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Seed"] > CurTime () then
			WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: Received too many requests from player : " .. playerName .. " (" .. playerId .. ").")
			
			WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = ""
			
			WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Cooldown expires in: " .. WireMultiAgent ["WireMultiAgent:Resources"]:CalculateTimeRemaining (WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Seed"] - CurTime ()))
			
			return
		end
		
		local carriageEnded = net.ReadBool ()
			
		local signature 	= net.ReadBool ()
		
		if not signature then
			WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: Received a malformed carriage from player : " .. playerName .. " (" .. playerId .. ").")
			
			return
		end
		
		local packetsRemaining 		= net.ReadString  ()
		local sizeRemaining			= net.ReadString  ()
		
		local e2Sharing				= net.ReadString  ()
		local e2Description			= net.ReadString  ()
		
		local importedFloat  		= net.ReadUInt (16)
		local compressedCarriage   	= net.ReadData (importedFloat)
		
		WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Constructor"] .. compressedCarriage
		
		if not carriageEnded then
			return
		end
		
		if not WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Constructor"] then
			WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: Failed to reconstruct carriage packets from player : " .. playerName .. " (" .. playerId .. ").")
			
			WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = ""
			
			return
		end
	
		local uncompressedCarriage 	= util.Decompress (WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Constructor"]) or ""
		
		if not uncompressedCarriage or uncompressedCarriage == "" then
			WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: Deserialization failure for player " .. playerName .. " (" .. playerId .. ").")
			
			WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = ""
		end
		
		local codeUniqueHashing = string.format ("%07X", util.CRC (uncompressedCarriage))
		
		
		WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Seed"] 		= CurTime () + 3
		WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["TotalCount"] 	= WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["TotalCount"] + 1
		WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["TotalSize"]  	= WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["TotalSize"]  + string.len (uncompressedCarriage)
		
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Received a carriage from player : " .. playerName .. " (" .. playerId .. ").")
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger (playerName .. " (" .. playerId .. ") bandwidth used : " .. string.NiceSize (WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["TotalSize"]))
		
		
		WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [playerId64] ["Constructor"] = ""
		
		self.TransferExpression2Code (ply, codeUniqueHashing, uncompressedCarriage, e2Description, e2Sharing)
	end)
end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())
