local self   	= {}
local pairs		= pairs
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "WireMultiAgent:FnReporter"
end

function self:Constructor ()
	self.ImportedSerialization 	= WireMultiAgent ["WireMultiAgent:iSerializer"].importedExpression2Codes 
end
-- Functions exporter
function self:FunctionsReporter (serializer, importedCodeGen, e2Sharing, player)
	if not serializer then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " expected serializer but received nothing.")
		
		return
	end
	
	if not importedCodeGen then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " was unable to report functions due to missing {ImportedCodeGen}.")
		
		return
	end
	
	if not self.ImportedSerialization [serializer] then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " : Failed to import {ImportedSerialization}.")
		
		return
	end

end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())