local self   	= {}
local pairs		= pairs
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "WireMultiAgent:PerformFingerprint"
end

function self:Constructor ()
	self.ImportedSerialization 	= WireMultiAgent ["WireMultiAgent:iSerializer"].importedExpression2Codes
	self.ExportLineSpanHash		= {}
	
	self.PerformStandardization = WireMultiAgent ["WireMultiAgent:PerformIRTrace"].PerformStandardizationCodegen
end

function self:PerformSampling (serializer, rawCode, e2Sharing, player)
	if not serializer then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " expected serializer but received nothing.")
		
		return
	end
	
	local getExpression2Data = self.ImportedSerialization [serializer]
	
	if not getExpression2Data then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Warning: " .. self:InternalId () .. " was unable to retrieve getExpression2Data.")
		
		return
	end
	
	if not self.ExportLineSpanHash [serializer] then
		self.ExportLineSpanHash [serializer] = {}
	end
	
	local maxIteration = getExpression2Data.E2Lines
	
	if self.ImportedSerialization [serializer] ["LineSpan"] then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger (self:InternalId () .. " : Found previous cache for Id {" .. serializer .. "}, re-using the cache..")
		
		WireMultiAgent ["WireMultiAgent:PerformIRTrace"]:PerformIRTrace (serializer, rawCode, e2Sharing, player)
		
		return
	else
		self.ImportedSerialization [serializer] ["LineSpan"] 	= {}
		self.ExportLineSpanHash [serializer] ["LineSpan"] 		= {}
		
		for lineSpan, codeLine in pairs (getExpression2Data.E2Code) do
			if #codeLine >= 15 and string.match (codeLine, "[%S{}%(%)]") and not string.find (string.sub (codeLine, 1, 1), "@") then
				self.ImportedSerialization [serializer] ["LineSpan"] [lineSpan] = string.format ("%010X", util.CRC (codeLine))
				
				self.ExportLineSpanHash [serializer] ["LineSpan"] [lineSpan] = string.format ("%010X", util.CRC (self.PerformStandardization (codeLine)))
			end
		end
	end
	
	local retrieveGlobalizedLineSpan = WireMultiAgent ["WireMultiAgent:ProgramLogs"]:GetTableLength (self.ExportLineSpanHash [serializer]["LineSpan"])
	
	if retrieveGlobalizedLineSpan < 50 then
		player:ChatPrint ("[Wire Multi-Agent] Your code is too basic and is not eligible to the DRM") -- TODO: incorporate this to the menu
		print(retrieveGlobalizedLineSpan)
		self.ImportedSerialization [serializer] = {}
		
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Player " .. player:Nick () .. "(" .. player:SteamID () .. ")'s code was denied due to not being eligible to the DRM system.")
		
		return
	end
	
	WireMultiAgent ["WireMultiAgent:PerformIRTrace"]:PerformIRTrace (serializer, rawCode, e2Sharing, player)
end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())