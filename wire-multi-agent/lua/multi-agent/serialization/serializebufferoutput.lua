local self   	= {}
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber
local print		= print

function self:InternalId ()
	return "WireMultiAgent:iSerializer"
end

function self:Constructor ()
	self.importedExpression2Codes = self.importedExpression2Codes or {}
end

local function getExpression2Name (code)
	local getNameUsingPattern = "@name%s+([^\n]+)" 
	
    local expression2Name = string.match (code, getNameUsingPattern)
	
	if not expression2Name or expression2Name == "" then
		expression2Name = "Generic"
	end
	
    return expression2Name
end

function self:SerializeExpression2PlagiatCode (codegen, codeHashBytescode, e2Description, e2Sharing, startLine, player)
	if not codegen then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Expression2 received code is empty, discarding..")
		
		return
	end
	
	if not e2Description or e2Description == "" then
		e2Description = "none"
	end
	
    if self.importedExpression2Codes [codeHashBytescode .. startLine] then
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("Already cached FunctionsInformations for " .. codeHashBytescode .. ", re-using this save.")
		
		WireMultiAgent ["WireMultiAgent:PerformFingerprint"]:PerformSampling (codeHashBytescode .. startLine, codegen, e2Sharing, player)
		
        return self.importedExpression2Codes [codeHashBytescode .. startLine]
    else
		self.importedExpression2Codes [codeHashBytescode .. startLine] 			= {}
		self.importedExpression2Codes [codeHashBytescode .. startLine].E2Name 	= getExpression2Name (codegen)
		self.importedExpression2Codes [codeHashBytescode .. startLine].E2Desc   = e2Description
		self.importedExpression2Codes [codeHashBytescode .. startLine].E2Lines 	= 0
		self.importedExpression2Codes [codeHashBytescode .. startLine].E2Code	= {}
		
		WireMultiAgent ["WireMultiAgent:Initializer"]:MiniLogger ("No cache found for " .. codeHashBytescode .. ", preparing to cache..")
		
        local expression2RawCode = codegen
        
        if expression2RawCode then
            if string.find (expression2RawCode, "\r") then
                self.importedExpression2Codes [codeHashBytescode .. startLine].E2Code = string.Split (expression2RawCode, "\r")
            else
                self.importedExpression2Codes [codeHashBytescode .. startLine].E2Code = string.Split (expression2RawCode, "\n")
            end
        else
            return nil
        end
    end
	
	self.importedExpression2Codes [codeHashBytescode .. startLine].E2Lines = #self.importedExpression2Codes [codeHashBytescode .. startLine].E2Code or 0
	
	WireMultiAgent ["WireMultiAgent:PlayerSession"].PlayerSession [player:SteamID64 ()] ["Seed"] = CurTime () + (0.0685 * self.importedExpression2Codes [codeHashBytescode .. startLine].E2Lines)
	
	WireMultiAgent ["WireMultiAgent:PerformFingerprint"]:PerformSampling (codeHashBytescode .. startLine, codegen, e2Sharing, player)
	
    return self.importedExpression2Codes [codeHashBytescode .. startLine]
end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())