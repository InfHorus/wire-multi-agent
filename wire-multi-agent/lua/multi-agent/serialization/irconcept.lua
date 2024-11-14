local self   	= {}
local pairs		= pairs
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "WireMultiAgent:PerformIRTrace"
end

function self:Constructor ()
	self.ImportedSerialization 	= WireMultiAgent ["WireMultiAgent:iSerializer"].importedExpression2Codes
	
	self.PerformStandardizationCodegen = function (inBuffer)
		inBuffer = string.match (inBuffer, "^%s*(.-)%s*$")

		inBuffer = string.gsub (inBuffer, "[%s\128-\255]", "")

		return inBuffer
	end
end

function self:PerformIRTrace (serializer, importedCodeGen, e2Sharing, player)
	if not serializer then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " expected serializer but received nothing.")
		
		return
	end
	
	if not importedCodeGen then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " was unable to retrieve IR {ImportedCodeGen}.")
		
		return
	end
	
	if not self.ImportedSerialization [serializer] then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " : Failed to import {ImportedSerialization}.")
		
		return
	end
	
	if self.ImportedSerialization [serializer] ["IRTrace"] and self.ImportedSerialization [serializer] ["IRTrace"] ~= "" then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger (self:InternalId () .. " : Found previous cache for Id {" .. serializer .. "}, re-using the cache..")
		
		self.ImportedSerialization [serializer] ["IRTrace"] = string.format ("%015X", util.CRC (self.PerformStandardizationCodegen (importedCodeGen)))
	
		WireMultiAgent ["WireMultiAgent:StylometryHelper"]:RetrieveVBL (serializer, importedCodeGen, e2Sharing, player)
	else
		self.ImportedSerialization [serializer] ["IRTrace"] = string.format ("%015X", util.CRC (self.PerformStandardizationCodegen (importedCodeGen)))
	
		WireMultiAgent ["WireMultiAgent:StylometryHelper"]:RetrieveVBL (serializer, importedCodeGen, e2Sharing, player)
	end
end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())