local self   	= {}
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "WireMultiAgent:HandlerProcess"
end

function self:Constructor ()
	self.JsonToTable 	= util.JSONToTable
	
	self.importLogger 	= WireMultiAgent ["WireMultiAgent:Initializer"].MiniLogger
end

function self:HandleServerResponse (inBuffer, playerName, playerSteamId, expression2Name, expression2Lines, expression2Desc)
	if not inBuffer or inBuffer == "" then
		self.importLogger ("Warning: " .. self:InternalId () .. ".HandleServerResponse received an empty buffer.")
		
		return
	end
	
	local handleServerArrayResponse = util.JSONToTable (inBuffer)
	
	if not handleServerArrayResponse or type (handleServerArrayResponse) ~= "table" then
		self.importLogger ("Warning: " .. self:InternalId () .. ".HandleServerResponse failed to deserialize server's response.")
		
		self.importLogger ("Server response: " .. inBuffer)
		return
	end
	
	if handleServerArrayResponse [1] ~= 0 then
		self.importLogger ("Successfully submitted player " .. playerName .. " (" .. playerSteamId .. ")'s Expression2, request ID { " .. handleServerArrayResponse [2] .. " }.")
		self.importLogger ("Expression2 Name: " .. expression2Name .. " Lines: " .. expression2Lines .. " (Description: " .. expression2Desc .. ").")
	else
		self.importLogger ("Warning: Submission for player " .. playerName .. " (" .. playerSteamId .. ")'s Expression2 failed:")
		self.importLogger ("Expression2 Name: " .. expression2Name .. " Lines: " .. expression2Lines .. " (Description: " .. expression2Desc .. ").")

		self.importLogger ("Server response: " .. handleServerArrayResponse [2])
	end
end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())