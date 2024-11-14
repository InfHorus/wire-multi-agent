-- Forensics.Theme = Green
-- Cardinal.Theme  = Blue
-- Bastion.Theme   = Red
-- Minuit.Theme    = Black

local self 			= {}
local MsgC 			= MsgC
local type			= type
local previousSave 	= previousSave or {}
local sanitizedDate = string.gsub (os.date ("%d/%m/%Y"), "/", "_")

function self:InternalId ()
	return "WireMultiAgent:Initializer"
end

function self:MiniLogger_ (appender, _)
	if not appender and type (self) ~= "table" then
		appender = self
	end

	Msg ("\n")
	MsgC (Color (255,255,255), "(", Color (255,0,0), "[!] WireMultiAgent | " .. tostring (WireMultiAgent ["WireMultiAgent:SystemDispatcher"].TimeTracker ()) .. " [!]", Color (255,255,255),"): ", appender)
	Msg ("\n")
end

function self:MiniLogger (appender, shouldIgnore)
	if type (self) == "table" and not previousSave then
		--previousSave = previousSave or {}
	end
	
	if not appender and type (self) ~= "table" then
		appender = self
	end
	
	if not shouldIgnore then
		Msg ("\n")
		MsgC (Color (255,255,255), "(", Color (255,0,0), "[!] WireMultiAgent | " .. tostring (WireMultiAgent ["WireMultiAgent:SystemDispatcher"].TimeTracker ()) .. " [!]", Color (255,255,255),"): ", appender)
		Msg ("\n")
	end

	if previousSave then
		previousSave [#previousSave + 1] = "[" .. tostring (WireMultiAgent ["WireMultiAgent:SystemDispatcher"].TimeTracker ()) .. "] : " .. appender .. "\n"
	end
	
	if file.Exists ("wire-multi-agent/console/console" .. "_" .. sanitizedDate .. ".txt", "DATA") then
		if previousSave then
			file.Append ("wire-multi-agent/console/console" .. "_" .. sanitizedDate .. ".txt", table.concat (previousSave))
			previousSave = nil
		end
		file.Append ("wire-multi-agent/console/console" .. "_" .. sanitizedDate .. ".txt", "[" .. tostring (WireMultiAgent ["WireMultiAgent:SystemDispatcher"].TimeTracker ()) .. "] : " .. appender .. "\n")
	end
end

function self:LoadSubPath ()
	if WireMultiAgent ["WireMultiAgent:SystemDispatcher"].LoadFile and type (WireMultiAgent ["WireMultiAgent:SystemDispatcher"].LoadFile) == "table" then
	
		for incremental = 1, #WireMultiAgent ["WireMultiAgent:SystemDispatcher"].LoadFile do
			if not WireMultiAgent ["WireMultiAgent:SystemDispatcher"].LoadFile [incremental] or incremental == 1 then
				goto skipIteration
			end

			local isServer 	  = WireMultiAgent ["WireMultiAgent:SystemDispatcher"].ParseCorrectFiles (WireMultiAgent ["WireMultiAgent:SystemDispatcher"].LoadFile [incremental])
			local correctPath = string.gsub (WireMultiAgent ["WireMultiAgent:SystemDispatcher"].LoadFile [incremental], "SERVER|", "")
			correctPath		  = string.gsub (correctPath, "CLIENT|", "")
			
			if isServer and SERVER then
				local output = WireMultiAgent ["WireMultiAgent:SystemDispatcher"].DispatchFiles (correctPath)
				self:MiniLogger (output)
			elseif not isServer then
				local output = WireMultiAgent ["WireMultiAgent:SystemDispatcher"].DispatchFiles (correctPath)
				self:MiniLogger (output)
			end

			::skipIteration::
		end
	else
		self:MiniLogger ('!!Could not retrieve element {WireMultiAgent ["WireMultiAgent:SystemDispatcher"].LoadFile}.')
	end
end

WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())
self:LoadSubPath ()