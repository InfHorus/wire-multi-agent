local self   	= {}
local pairs		= pairs
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "WireMultiAgent:StylometryHelper"
end

function self:Constructor ()
	self.ImportedSerialization 	= WireMultiAgent ["WireMultiAgent:iSerializer"].importedExpression2Codes
	self.ImportedSequence		= "([A-Z][A-Za-z0-9_]*)" -- TODO: Fix bad sequence + @ bps.
end

function self:RetrieveVBL (serializer, importedCodeGen, e2Sharing, player)
	if not serializer then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " expected serializer but received nothing.")
		
		return
	end
	
	if not importedCodeGen then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " was unable to extract VBL due to missing {ImportedCodeGen}.")
		
		return
	end
	
	if not self.ImportedSerialization [serializer] then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " : Failed to import {ImportedSerialization}.")
		
		return
	end

	if self.ImportedSerialization [serializer] ["E2Vars"] then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger (self:InternalId () .. " : Found previous cache for Id {" .. serializer .. "}, re-using the cache..")
		
		WireMultiAgent ["WireMultiAgent:CodeRefactoring"]:ExtractFunctionsInformations (serializer, player, importedCodeGen, e2Sharing)
	else
		self.ImportedSerialization [serializer] ["E2Vars"] = {}
	
		for lineSpan, codeLine in pairs (self.ImportedSerialization [serializer] ["E2Code"]) do -- Denying the usage of ipairs as in some situation the table might have gap.
			if not string.find (string.sub (codeLine, 1, 1), "@") then
				for retrievedMatchedSequence in string.gmatch (codeLine, self.ImportedSequence) do
					table.insert (self.ImportedSerialization [serializer] ["E2Vars"], retrievedMatchedSequence)
				end
			end
		end
		
		--coroutine.wrap (WireMultiAgent ["WireMultiAgent:CodeRefactoring"].ExtractFunctionsInformations) (serializer) -- TODO: Fix upvalues. 
		WireMultiAgent ["WireMultiAgent:CodeRefactoring"]:ExtractFunctionsInformations (serializer, player, importedCodeGen, e2Sharing)
	end
end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())