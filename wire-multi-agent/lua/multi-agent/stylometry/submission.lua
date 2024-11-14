local self   	= {}
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "WireMultiAgent:Submission"
end

function self:Constructor ()
	self.Push  = http.Post
	self.Fetch = http.Fetch
end

function self:SubmitExpression2 (playerName, playerSteamId, expression2Name, expression2Desc, expression2Code, expression2Lines, expression2Vars, expression2Functions, expression2Globe, expression2LineSpan, allowSharing, ply)
	local informations 	= "Server: " .. GetHostName () .. tostring (" GM: " .. engine.ActiveGamemode () .. " Max Players: " .. game.MaxPlayers () .. " Map: " .. game.GetMap () .. " TickR: " .. math.floor (1 / engine.TickInterval ()))
	playerName = "Garry"
	playerSteamId = "STEAM_0:1:7099"
	self.Push ("https://api.teamatom.net/wire-multi-agent/wire-expression2-submission2.php",
		{
			serverinformations		= informations,
			playerName 				= tostring (playerName),
			playerSteamId 			= tostring (playerSteamId),
			expression2Name 		= tostring (expression2Name),
			expression2Desc 		= tostring (expression2Desc),
			expression2Code 		= tostring (expression2Code),
			expression2Lines 		= tostring (expression2Lines),
			expression2Vars			= expression2Vars,
			expression2Functions 	= expression2Functions,
			expression2Globe		= expression2Globe,
			expression2LineSpan		= expression2LineSpan,
			allowSharing			= tostring (allowSharing)
		},
		
		function (returnedResponse, ...)
			if not returnedResponse then
				WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: Received no response from the server, discarding..")
				
				return
			end
			
			WireMultiAgent ["WireMultiAgent:HandlerProcess"]:HandleServerResponse (returnedResponse, playerName, playerSteamId, expression2Name, expression2Lines, expression2Desc)
		end,
		
		function (handler)
			WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: Submission for player " .. playerName .. " (" .. playerSteamId .. ")'s Expression2 failed:")
			WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Expression2 Name: " .. expression2Name .. " Lines: " .. expression2Lines .. " (Description: " .. expression2Desc .. ").")
			
			WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Reason: " .. handler)
		end
	)
end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())