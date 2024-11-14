if WireMultiAgent ["WireMultiAgent:SystemDispatcher"]:GetStateStatus (SERVER) then
	return
end

coroutine_create = coroutine_create or coroutine.create 
coroutine_yield  = coroutine_yield or coroutine.yield 
coroutine_wait   = coroutine_wait or coroutine.wait 
coroutine_status = coroutine_status or coroutine.status 
coroutine_resume = coroutine_resume or coroutine.resume

string_sub  = string_sub or string.sub 
string_find = string_find or string.find 
string_byte = string_byte or string.byte 

table_insert = table_insert or table.insert 
table_remove = table_remove or table.remove 
table_Copy   = table_Copy or table.Copy 
table_Count  = table_Count or table.Count 

local function swap(a, b)
    return table_Copy(b), table_Copy(a) 
end

local function isUpper(char)  
    if not char or char == "" then return false end 
    local n = string_byte(char)
    return n >= 65 and n <= 90 
end

local function isLower(char)  
    if not char or char == "" then return false end 
    local n = string_byte(char)
    return n >= 97 and n <= 122 
end

local function isNumber(char) 
    if not char or char == "" then return false end 
    local n = string_byte(char)
    return n >= 48 and n <= 57 
end

local function isSpecial(char)
    return isNumber(char) == false and isLower(char) == false and isUpper(char) == false 
end 

local function mSub(x, strength)
    return x - (math.floor(x) % strength)
end

local function whitespace(str)
    if not str then return false end 
    return string.gsub(str, "%s", "") == ""
end

local function compareLines(A, B)
    if not A or not B then return nil end 
    local aL = {}
    local bL = {}
    do 
        local aT = type(A)
        local bT = type(B)
        if aT == "string" then 
            aL = string.Split(A, "\n")
        elseif aT == "table" then 
            aL = A 
        else return 0, 0 end 
        if bT == "string" then 
            bL = string.Split(B, "\n")
        elseif bT == "table" then 
            bL = B 
        else return nil end 
    end 
    local eL = 0 
    if #aL ~= #bL then 
        eL = (#aL > #bL and #aL or #bL)
    else 
        eL = #aL 
        while eL >= 1 and aL[eL] == bL[eL] do  
            eL = eL - 1
        end
    end
    if eL == 0 then return {0,0} end
    local sL = 1
    while aL[sL] == bL[sL] and sL < eL do  
        sL = sL + 1
    end
    return {sL, eL}
end

local SixLexer = {}

-- Really shitty written, use metatables as fix 
function SixLexer:Validate()
    if not self.config then self.config = {} end

    local config = self.config

    if not config.colors then config.colors = {} end 

    --- Reserved Check
    if not config.reserved then 
        config.reserved = {} 
    else
        for k, v in pairs(config.reserved) do
            if not v then 
                config.reserved[k] = {}
            else 
                if not config.colors[k] then 
                    config.colors[k] = Color(255,255,255) 
                end
            end
        end
    end

    --- Closing Pairs Check
    if not config.closingPairs then 
        config.closingPairs = {}
    else 
        for k, v in pairs(config.closingPairs) do 
            if not v then 
                config.closingPairs[k] = {}
            elseif type(v) ~= "table" then 
                config.closingPairs[k] = {}
            elseif #v > 2 then 
                config.closingPairs[k] = {}
            else 
                config.colors[k] = Color(255,255,255)
            end
        end
    end

    --- Matches
    if not config.matches then
        config.matches = {}
    else
        if not config.matches.whitespace then 
            config.matches.whitespace = {pattern = "%s+"}
        end

        for k, v in pairs(config.matches) do
            if not v then 
                config.matches[k] = {}
            elseif not v.pattern then 
                config.matches[k] = {}
            else
                if not v.validation then 
                    config.matches[k].validation = function() return true end
                end

                if not config.colors[k] then 
                    config.colors[k] = Color(255,255,255)
                end
            end
        end
    end

    --- Captures Check
    if not config.captures then 
        config.captures = {} 
    else  
        for k, v in pairs(config.captures) do
            if not v then 
                config.captures[k] = {}
            else 
                if not config.captures[k].begin then 
                    config.captures[k] = {}
                else
                    if not config.captures[k].begin.pattern then 
                        config.captures[k] = {}
                        continue
                    end

                    if not config.captures[k].begin.validation then 
                        config.captures[k].begin.validation = function() return true end                  
                    end
                end

                if not config.captures[k].close then 
                    config.captures[k] = {}
                else 
                    if not config.captures[k].close.pattern then 
                        config.captures[k] = {}
                        continue
                    end

                    if not config.captures[k].close.validation then 
                        config.captures[k].close.validation = function() return true end                  
                    end
                end
            end
        end   
    end      

    if not config.closingPairs then config.closingPairs = {} end 
    if not config.colors.error then config.colors.error = Color(255,0,0) end 

    if not config.onLineParseStarted then config.onLineParseStarted = function() end end 
    if not config.onLineParsed then config.onLineParsed = function() end end 
    if not config.onMatched then config.onMatched = function() end end 
    if not config.onCaptureStart then config.onCaptureStart = function() end end 
    if not config.onCaptureEnd then config.onCaptureEnd = function() end end 
    if not config.onTokenSaved then config.onTokenSaved = function() end end 
     
end


--- Sets the Lexer's text.
function SixLexer:SetText(text)
    self.lines = string.Split(text, "\n")
    self.hasChanges = true 
end

function SixLexer:SetLines(lines)
    self.lines = lines 
end

--- Returns the Lexer's text.
function SixLexer:GetText()
    return table.concat(self.lines, "\n") 
end


--[[
    static int[,] LCSLength(string a, string b)
{
   int[,] C = new int[a.Length + 1, b.Length + 1];//(a,b).Length+1
   for (int i = 0; i < a.Length; i++)
       C[i, 0] = 0;
   for (int j = 0; j < b.Length; j++)
       C[0, j] = 0;
   for (int i = 1; i <= a.Length; i++)
       for (int j = 1; j <= b.Length; j++)
       {
           if (a[i - 1] == b[j - 1])//i-1,j-1
               C[i, j] = C[i - 1, j - 1] + 1;
           else
               C[i, j] = Math.Max(C[i, j - 1], C[i - 1, j]);
       }
   return C;
}
]]
function SixLexer:CheckLineDifferences(a, b, includeMinors)
    includeMinors = includeMinors or false 
    local diffs   = {}
    local smaller = a 
    local bigger  = b
    local offset = 0
    for i, line in pairs(bigger) do
        if i > #smaller then 
            diffs[i] = "removed"
        elseif includeMinors == true and smaller[i] == bigger[i] then 
            diffs[i] = "unchanged"
    --    elseif includeMinors == true and  smaller[i - offset] ~= line and smaller[i] ~= bigger[i] then 
    --        diffs[i] = "shifted down"
    --        offset = offset + 1
        else
            diffs[i] = "modified"
        end
    end
    for i = 1, #smaller - #bigger, 1 do 
        diffs[#bigger + i - offset] = "added"
    end
    return diffs     
end

--- Sets the configurations for the Lexer
function SixLexer:SetConfig(config)
    self.config = config 
    self:Validate()
end

--- Tokenize a single line of the text
function SixLexer:ParseLine(i, prevLineTokens, unclosedPairs)
    self.config.onLineParseStarted(i)
    unclosedPairs = unclosedPairs or {}
    if not self.lines then 
        self.config.onLineParsed({}, i)
        return {}, unclosedPairs 
    end 
    local result  = {}
    local line    = self.lines[i] or ""
    local buffer  = 0
    local builder = ""
    local capture = {type = "", group = ""}
    local function block(t, g) capture.type, capture.group = t,  g  end
    local function unblock()   capture.type, capture.group = "", "" end       
    local function addToken(text, type, startPos, endPos, extra)
        if not text or text == "\n" then return end 
        extra = extra or {}
        type  = type  or "error"
        local newToken = {
            type   = type,
            text   = text,
            start  = (startPos or buffer),
            ending = (endPos or (buffer + #text -1)),
            extra = extra}
        table_insert(result, newToken)
        self.config.onTokenSaved(newToken, i, type, buffer, result)
    end
    local function addRest(fallback)
            if builder == "" then return end 
            fallback = fallback or "error"
            addToken(builder, fallback, buffer - #builder, buffer - 1)
            builder = ""
    end  
    local function addToBuilder(str, fallback)
        if not str or str == "\n" or str == "" then return end 
        fallback = fallback or "error"
        if #str > 1 then 
            builder = builder .. str
            return 
        end  
        local function isReserved(someChar)
            for key, chars in pairs(self.config.reserved) do 
                for _, char in pairs(chars) do 
                    if char == someChar then
                        return key
                    end 
                end
            end
            return nil   
        end
        local resr = isReserved(str)
        if resr then
            if self.config.reserved[(result[#(result or {})] or {}).type] then 
                result[#result].text = result[#result].text .. str 
            else
                addRest(fallback) 
                addToken(str, resr)
            end
            return 
        end
        for key, pairs in pairs(self.config.closingPairs) do 
            if str == pairs[1] or str == pairs[2] then 
                local extra = {}
                --[[ 
                    DONT REMOVE YET, MIGHT BE USEFUL LATER ON !!!

                if str == pairs[1] then
                    if not unclosedPairs[pairs[1] ] then unclosedPairs[pairs[1] ] = {} end 
                    table_insert(unclosedPairs[pairs[1] ], {
                        type = key,
                        line = i,
                        tkIndex = #result, 
                        char = buffer 
                    })
                else
                    if unclosedPairs[pairs[1] ] then 
                        local ucs = unclosedPairs[pairs[1] ]
                        local last = ucs[#ucs]
                        if last then 
                            table_remove(unclosedPairs[pairs[1] ])
                            extra = {
                                closes = {
                                    line = last.line,
                                    char = last.char,
                                    tkIndex = last.tkIndex
                                }
                            }
                        end 
                    end
                end]]
                addRest(fallback)
                addToken(str, key, buffer, buffer, extra)
                return 
            end
        end 
        builder = builder .. str 
    end
    local function readNext()
            buffer = buffer + 1
            if buffer > #line then return "\n" end 
            return line[buffer]
    end
    local function nextPattern(pattern)
            local s, e, txt = string_find(line, pattern, buffer)
            if not e or not e then return false end 
            return s == buffer  
    end
    local function readPattern(pattern)
            local s, e, txt = string_find(line, pattern, buffer)
            if not e or not s or s ~= buffer then return "" end 
            local res = string_sub(line, s, e)
            return res 
    end
    local interrupt = 0
    if prevLineTokens then --- Check if previous line starts a capture or is inside a capture.
        local lastTokenIndex = 1
        if prevLineTokens[#prevLineTokens].type ~= "newline" then lastTokenIndex = 0 end
        local lastRealToken = prevLineTokens[#prevLineTokens - lastTokenIndex]
        if lastRealToken and lastRealToken.extra.inCapture then 
            local capType = lastRealToken.extra.captureType
            block(capType, self.config.captures[capType])
        end
    end
    if line == "" then 
        if capture.type ~= "" then 
            addToken("", capture.type, 1, 1, {inCapture=1, captureType=capture.type})
        else 
            addToken("", "newline", 1, 1)   
        end
        self.config.onLineParsed(result, i)
        return result, unclosedPairs
    end
    while true do 
        if capture.type == "" then
            local char = readNext()
            if char == "\n" then 
                addRest()
                addToken("", "newline")            
                break
            end 
            local patternFound = false 
            --- Match handling
            for k, v in pairs(self.config.matches) do 
                if nextPattern(v.pattern) == true then
                    local finding = readPattern(v.pattern)
                    local function triggerOther(otherTrigger)
                        if not otherTrigger then return end
                        local xd = self.config.matches[otherTrigger]
                        if type(otherTrigger) == "string" and xd then 
                            k = otherTrigger 
                            v = xd 
                        end
                    end
                    patternFound = v.validation(line, buffer, finding, table_Count(result or {}), result or {}, i, triggerOther)
                    if patternFound == true then 
                        self.config.onMatched(finding, i, k, buffer, result)
                        addRest()  
                        addToken(finding, k)
                        buffer = buffer + #finding - 1
                        break 
                    end 
                end
            end
            if patternFound == true then continue end 
            --- Capture Start handling
            for k, v in pairs(self.config.captures) do
                local start = v.begin 
                if nextPattern(start.pattern) == true then 
                    local finding = readPattern(start.pattern)
                    local function triggerOther(otherTrigger)
                        if not otherTrigger then return end
                        local xd = self.config.captures[otherTrigger]
                        if type(otherTrigger) == "string" and xd then 
                            k = otherTrigger 
                            v = xd 
                        end
                    end
                    patternFound = start.validation(line, buffer, finding, table_Count(result or {}), result or {}, i, triggerOther)
                    if patternFound == true then          
                        self.config.onCaptureStart(start.pattern, i, k, buffer, result)
                        block(k, v)
                        builder = builder .. finding 
                        buffer = buffer + #finding - 1
                        break                  
                    end
                end
            end
            if patternFound == true then continue end 
            addToBuilder(char)
        else
            local char = readNext()
            if char == "\n" then 
                if builder ~= "" then 
                    addToken(builder, capture.type, buffer - #builder, buffer, {inCapture=1, captureType=capture.type})
                    builder = ""
                end
                break
            end
            local closeFound = false 
            local close = capture.group.close 
            if nextPattern(close.pattern) == true then 
                local finding = readPattern(close.pattern)
                closeFound = close.validation(line, buffer, finding, table_Count(result or {}), result or {}, i)
                if closeFound == true then 
                    self.config.onCaptureEnd(close.pattern, i, capture.type, buffer, result)
                    builder = builder .. finding 
                    addToken(builder, capture.type, buffer - #builder + #finding, buffer + 1, {endsCapture=1})
                    builder = ""
                    buffer  = buffer + #finding - 1
                end
            end
            if closeFound == true then 
                unblock()
                continue 
            end         
            builder = builder .. char
        end
    end
    self.config.onLineParsed(result, i)
    return result, unclosedPairs
end

--- Parse the entire current text
function SixLexer:ParseAll()
    if not self.lines then return end 
    local result = {}
    local lastLineTokens = {}
    for i, line in pairs(self.lines) do 
        local tokens = self:ParseLine(i, lastLineTokens)
        lastLineTokens = tokens 
        result[i] = tokens
    end
    return result 
end

local syntaxBox = {}
local fontBank = {}

local function dark(i)
    return Color(i,i,i)
end

local function out(s)
    print("'"..s.."'")
end


function syntaxBox:GetTokenAtPoint(char, line)
    if not char or not line then return nil end 
    if not self.lines[line] then return nil end 
    if not self.lines[line][char] then return nil end 
    local tokens = self.tokens[line]
    if tokens == nil then return nil end 
    for _, token in pairs(tokens) do 
        if (token.start <= char and token.ending >= char) then 
            return token, _
        end
    end
    return nil 
end

function syntaxBox:TokenAtCaret()
    return self:GetTokenAtPoint(self.caret.char, self.caret.line)
end

function syntaxBox:GetSurroundingPairs(char, line)
    if not char or not line then return nil end 
    local tokenUnderCaret, tkIndex = self:GetTokenAtPoint(char, line)
    tokenUnderCaret = tokenUnderCaret or {}
    tkIndex = tkIndex or 0
    local start = nil 
    local ending = nil 
    local nextIsPair = false
    if tokenUnderCaret.text then 
        for group, pair in pairs(self.lexer.config.closingPairs) do 
            if tokenUnderCaret.text == pair[2] then 
                ending = {
                    line = line,
                    char = tokenUnderCaret.start,
                    group = group 
                }
                break
            end         
        end
    end 
    if not ending then 
        local nextToken, _ = self:GetTokenAtPoint(char + 1, line)
        if nextToken and nextToken.text then 
            for group, pair in pairs(self.lexer.config.closingPairs) do 
                if nextToken.text == pair[1] then 
                    start = {
                        line = line,
                        char = nextToken.start,
                        group = group 
                    }
                    nextIsPair = true 
                    break
                end         
            end       
        end      
    end 
    if not start then  
        local tkCounter = tkIndex 
        local lnCounter = line
        local tk = tokenUnderCaret 
        local cCounter = {}
        if ending then 
            cCounter[ending.group] = -1
        end
        while true do    
            if tk then 
                local found = false 
                for group, pair in pairs(self.lexer.config.closingPairs) do 
                    if not cCounter[group] then cCounter[group] = 0 end 
                    if tk.text == pair[1] then
                        if cCounter[group] == 0 then  
                            if (ending and ending.group ~= group) or tk.text ~= pair[1] then 
                                continue
                            end
                            start = {
                                line = lnCounter,
                                char = tk.start,
                                group = group 
                            }
                            found = true 
                            break
                        else 
                            cCounter[group] = cCounter[group] - 1
                        end
                    elseif tk.text == pair[2] then 
                        cCounter[group] = cCounter[group] + 1
                    end
                end
                if found == true then 
                    break 
                end
            end 
            tkCounter = tkCounter - 1
            if tkCounter < 1 then 
                lnCounter = lnCounter - 1
            
                if not self.tokens[lnCounter] then 
                    self.tokens[lnCounter] = self.lexer:ParseLine(lnCounter, self.tokens[lnCounter - 1]) -- super shitty workaround but fuck it
                end
                local lastTK = #(self.tokens[lnCounter] or {})
                tkCounter = lastTK 
                if lnCounter < 1 then break end 
            end
            tk = (self.tokens[lnCounter] or {})[tkCounter] or {}
        end
    end

    if not ending and start then  
        local tkCounter = tkIndex + 1
        local lnCounter = line
        local tk = (self.tokens[lnCounter] or {})[tkCounter] or {}
        local cCounter = {}
        if start and nextIsPair == true then 
            cCounter[start.group] = -1
        end
        while true do    
            if not self.tokens[lnCounter] then 
                self.tokens[lnCounter] = self.lexer:ParseLine(lnCounter, self.tokens[lnCounter - 1]) -- super shitty workaround but fuck it
                tk = self.tokens[lnCounter]
            end
            if tk then 
                local found = false 
                for group, pair in pairs(self.lexer.config.closingPairs) do 
                    if not cCounter[group] then cCounter[group] = 0 end 
                    if tk.text == pair[2] then
                        if cCounter[group] == 0 then  
                            if (start and start.group ~= group) or tk.text ~= pair[2] then 
                                continue
                            end
                            ending = {
                                line = lnCounter,
                                char = tk.start,
                                group = group 
                            }
                            found = true 
                            break
                        else 
                            cCounter[group] = cCounter[group] - 1
                        end
                    elseif tk.text == pair[1] then 
                        cCounter[group] = cCounter[group] + 1
                    end
                end
                if found == true then 
                    break 
                end   
            end 
            tkCounter = tkCounter + 1
            if tkCounter > #(self.tokens[lnCounter] or {}) then 
                lnCounter = lnCounter + 1
                tkCounter = 1
                if lnCounter > #(self.lines or {}) then 
                    break 
                end 
            end
            tk = (self.tokens[lnCounter] or {})[tkCounter] or {}
        end 
    end
    if start and ending then 
        return {start = start,ending = ending}
    elseif not start then 
        if ending then 
            return {ending=ending}
        end
        return nil 
    elseif ending and not start then 
        return {start=start}
    elseif (ending or {}).group ~= (start or {}).group then
        if start then return {start=start}
        elseif ending then return {ending=ending}
        else return nil end 
    end 
  --  return {start = start,ending = ending}
end

function syntaxBox:FindPairMatch(char, line)
    local tokenUnderCaret, tkIndex = self:GetTokenAtPoint(char, line)
    if tokenUnderCaret then 
        local selPair = nil
        local isRight = false 
        for _, pair in pairs(self.lexer.config.closingPairs) do 
            if tokenUnderCaret.text == pair[1] or tokenUnderCaret.text == pair[2] then 
                if tokenUnderCaret.text == pair[2] then 
                    isRight = true 
                end
                selPair = pair 
                break
            end
        end
        if selPair then 
            local closer    = nil
            local tkCounter = tkIndex
            local lnCounter = line
            local cCounter  = 0
            if isRight == true then 
                local interrupt = 0
                while true do 
                    tkCounter = tkCounter - 1
                    if tkCounter < 1 then 
                        lnCounter = lnCounter - 1
                        local lastTK = #(self.tokens[lnCounter] or {})
                        if not lastTK then break end 
                        tkCounter = lastTK
                        if lnCounter < 1 then break end 
                    end
                    local tk = self.tokens[lnCounter][tkCounter]
                    if tk == nil then 
                        if not self.lines[lnCounter] then 
                            continue 
                        end 
                        self.tokens[lnCounter] = self.lexer:ParseLine(lnCounter, self.tokens[lnCounter - 1] or {}) -- Haha eat my ass 
                        tk = self.tokens[lnCounter]
                    end 
                    if tk.text == selPair[2] then 
                        cCounter = cCounter + 1 
                    elseif tk.text == selPair[1] then 
                        if cCounter <= 0 then 
                            closer = {line=lnCounter, token=tkCounter}
                            break  
                        end
                        cCounter = cCounter - 1  
                    end 
                end
            else
                while true do 
                    tkCounter = tkCounter + 1
                    if tkCounter > #self.tokens[lnCounter] then 
                        lnCounter = lnCounter + 1
                        tkCounter = 0
                        if lnCounter > #self.lines then 
                            break
                         end 
                    end
                    local tk = self.tokens[lnCounter][tkCounter]
                    if tk == nil then 
                        if not self.lines[lnCounter] then continue end 
                        self.tokens[lnCounter] = self.lexer:ParseLine(lnCounter, self.tokens[lnCounter - 1] or {}) -- Haha eat my ass 
                        tk = self.tokens[lnCounter]
                    end 
                    if tk.text == selPair[1] then 
                        cCounter = cCounter + 1 
                    elseif tk.text == selPair[2] then 
                        if cCounter <= 0 then 
                            closer = {line=lnCounter, token=tkCounter}
                            break  
                        end
                        cCounter = cCounter - 1  
                    end 
                end
            end
            if closer then 
                local tk = self.tokens[closer.line][closer.token]
                return {
                    start = {
                        char = char,
                        line = line
                    },
                    ending = {
                        char = tk.start,
                        line = closer.line 
                    }
                }
            else 
                return {
                    start = {
                        char = char,
                        line = line
                    }
                }
            end
        end
    end
    return nil 
end

function syntaxBox:TrimRightLine(i)
    local curTokens = self.tokens[i]
    local line = self.lines[i]
    if not curTokens or not line then return end 
    if (curTokens[#curTokens - 1] or {}).type == "whitespace" and (curTokens[#curTokens] or {}).type == "newline" then 
        local _, _, right = string_find(line, "(%s*)$")
        if right then 
            local tempLine = string_sub(line, 1, #line - #right)
            self.lines[i], line = tempLine, tempLine
            table_remove(self.tokens[i], #curTokens - 1)
        end 
    end 
end

function syntaxBox:TrimRight()
    if not self.lines then return end 
    if not self.tokens then return end 
    for i, _ in pairs(self.tokens) do 
        self:TrimRightLine(i)
    end 
end

function syntaxBox:UpdateTabIndicators()
    self.allTabs = {}
    local function saveTab(cc, tab) self.allTabs[cc] = tab end
    local lastTabs = ""
    local visualTabs = {}
    local m = (self.textPos.line - 1) ~= 0 and -1 or 0
    local c = m
    for i = self.textPos.line + m, self.textPos.line + math.ceil(self:GetTall() / self.font.h) + 1, 1 do 
        local line = self.lines[i]
        if not line then continue end 
        local _, _, left = string_find(line, "^(%s*)")
        if string.gsub(line, "%s", "") == "" then  
            table_insert(visualTabs, c)
        else 
            if #left < #lastTabs then 
                for _, vt in pairs(visualTabs) do saveTab(vt, left .. " ") end
            else 
                for _, vt in pairs(visualTabs) do saveTab(vt, lastTabs .. " ") end            
            end
            visualTabs = {}   
            saveTab(c, left)
            lastTabs = left
        end
        c=c+1
    end
end

function syntaxBox:IsPair(line, tkIndex)
    if not line or not tkIndex or not self.tokens[line] or not self.tokens[line][tkIndex] then return nil end 
    local tk = self.tokens[line][tkIndex]
    for _, pair in pairs(self.lexer.config.closingPairs) do 
        if pair[1] == tk.text then return "left" 
        elseif pair[2] == tk.text then return "right" end 
    end
    return nil 
end

function syntaxBox:TextIsPair(text)
    if not text then return nil end 
    for t, pair in pairs(self.lexer.config.closingPairs) do 
        if pair[1] == text then return {t, true}  
        elseif pair[2] == text then return {t, false} end 
    end
    return nil 
end

function syntaxBox:TextIsReserved(text) 
    if not text then return nil end 
    for _, group in pairs(self.lexer.config.reserved) do 
        for  _, char in pairs(group) do 
            if text == char then return true end 
        end 
    end
    return nil 
end

function syntaxBox:GetTextFrom(start, ending)
    if not start or not ending then return "" end 
    local function flip()
        local save = table_Copy(ending)
        ending = table_Copy(start)
        start = table_Copy(save)      
    end
    if start.line ~= ending.line and ending.line < start.line then 
        flip()
    elseif start.line == ending.line and start.char > ending.char then 
        flip()
    end
    local r = ""
    local lineCounter = start.line 
    local charCounter = start.char + 1
    local function atEnd() return lineCounter >= ending.line and charCounter > ending.char end
    while true do 
        local line = self.lines[lineCounter]
        if not line then break end 
        if charCounter > #line then 
            r = r .. "\n"
            if atEnd() then break end 
            lineCounter = lineCounter + 1
            charCounter = 0
            continue 
        end 
        local char = line[charCounter] or ""
        r = r .. char 
        charCounter = charCounter + 1
        if atEnd() then break end 
    end
    return r  
end

function syntaxBox:reindex(t)
    if not t then return end 
    local c = 1
    local max = table_Count(t)
    for key, value in pairs(t) do 
        if key ~= c then 
            t[c] = value
        end 
        c = c + 1
    end
    return t 
end

function syntaxBox:PasteTextAt(text, char, line, ressel)
    if not text or not char or not line then return end 
    local right = string_sub(self.lines[line], char + 1, #self.lines[line])
    self.lines[line] = string_sub(self.lines[line], 1, char)
    local lineCounter = line 
    for i = 1, #text, 1 do 
        local char = text[i]
        if char == "\n" then 
            table_insert(self.lines, lineCounter + 1, "")
            lineCounter = lineCounter + 1
            continue 
        end
        self.lines[lineCounter] = self.lines[lineCounter] .. char 
    end
    self.caret.char = #self.lines[lineCounter]
    self.lines[lineCounter] = self.lines[lineCounter] .. right 
    self.caret.line = lineCounter 
    if not ressel then 
        self.arrowSelecting = false 
        self.mouseSelecting = false 
        self:ResetSelection()
    end 
    self:FixCaret()
    self.hasChanges = true 
end

function syntaxBox:RemoveTextFromTo(start, ending)
    if not start or not ending then return end 
    local function flip()
        local save = table_Copy(ending)
        ending = table_Copy(start)
        start = table_Copy(save)      
    end
    if start.line ~= ending.line and ending.line < start.line then 
        flip()
    elseif start.line == ending.line and start.char > ending.char then 
        flip()
    end
    if start.line ~= ending.line then 
        local startline = self.lines[start.line]
        local endline   = self.lines[ending.line]
        if not endline or not startline then return end 
        for i = start.line, ending.line - 1, 1 do 
            table_remove(self.lines, start.line + 1)
        end
        self.lines[start.line] = string_sub(startline, 1, start.char)..string_sub(endline, ending.char + 1, #endline)
    else 
        local line = self.lines[start.line]
        self.lines[start.line] = string_sub(line, 1, start.char)..string_sub(line, ending.char + 1, #line) 
    end 
    self:SetCaret(start)
    self:FixCaret()
end 

function syntaxBox:GetWordAtPoint(char, line)
    if not char or not line then return nil, nil end 
    local line = self.lines[line]
    if not line then return nil, nil end 
    local res = ""
    local back = true 
    local charCounter = char  
    local start = charCounter
    while true do 
        local c = line[charCounter]
        if not c then break end 
        if back == true then 
            if isSpecial(c) == true and not self.lexer.config.unreserved[c] then 
                back = false 
                charCounter = charCounter + 1
                start = charCounter
                continue 
            end
            charCounter = charCounter - 1
            if charCounter < 0 then 
                start = 0
                charCounter = 0
                back = false 
            end 
        else 
            if isSpecial(c) == true and not self.lexer.config.unreserved[c] then 
                break 
            end
            res = res .. c 
            charCounter = charCounter + 1
            if charCounter > #line then 
                break 
            end 
        end
    end 
    if res == "" then return nil, nil end 
    return res, start 
end

function syntaxBox:HighlightTokens(word)
    self:ResetHighlighting()
    if not word or whitespace(word) == true then return end 
    for i = self.textPos.line, self.textPos.line + math.ceil(self:GetTall() / self.font.h) - 1, 1 do 
        local tokens = self.tokens[i]
        if not tokens then self:ParseVisibleLines() end
        if not tokens then break end 
        for _, token in pairs(tokens) do 
            if token.text == word then 
                self:AddHighlight(token.start - 1, i, token.ending, i)
            end
        end
    end
end

function syntaxBox:HighlightWords(word)
    self:ResetHighlighting()
    if not word or whitespace(word) == true then return end 
    for i = self.textPos.line, self.textPos.line + math.ceil(self:GetTall() / self.font.h) - 1, 1 do 
        local line = self.lines[i]
        if not line then continue end 
        local l = 1
        while l < #line do 
            local char = line[l]
            local ending = l + #word - 1
            local sub = string_sub(line, l, ending)
            if sub == word then 
                self:AddHighlight(l - 1, i, ending, i)
                l = ending
            end
            l=l+1
        end
    end    
end

local function getLeft(str)
    if not str then return "" end 
    local _,_,left = string.find(str, "^(%s*)")
    if not left then return "" end 
    return left
end

local function countTimes(haystack, needle, bOf)
    if not haystack or not needle or type(haystack) ~= "string" or type(needle) ~= "string" then return 0 end 
    local result = 0
    bOf = bOf or false 
    i = 1
    repeat 
        local limit = i + #needle - 1
        if limit > #haystack then break end 
        local a,b = string_find(haystack, needle, i - 1)
        if not a or not b or a ~= i then
            i = i + 1
            continue 
        end 
        if string_sub(haystack, a, b) == needle then 
            result = result + 1
            i = i + #needle - 1
            if bOf == true then break end 
        end
        i = i + 1
    until i > #haystack
    return result 
end

function syntaxBox:GetLineIndention(i)
    if not i or not self.lines[i] then return "" end 
    local top = ""
    local bot = ""
    do 
        local tc = 0
        local count = 0
        for c = i - 1, 0, -1 do 
            count = count + 1
            if count > 250 then return "" end  
            local line = self.lines[c]
            if not line then return "" end
            if whitespace(line) == true then continue end 

            for _, word in pairs(self.lexer.config.indentation.close or {}) do 
                tc = tc + countTimes(line, word) 
            end

            local canClose = false 
            for _, word in pairs(self.lexer.config.indentation.open or {}) do 
                local counts = countTimes(line, word)
                if counts ~= 0 then 
                    if tc == 0 then 
                        top = getLeft(line) 
                        canClose = true  
                        break 
                    end 
                    tc = tc - counts 
                end
            end
            if canClose == true then break end 
        end
        if tc ~= 0 then return "" end 
    end 
    do 
        local bc = 0
        local count = 0
        for c = i + 1, #self.lines + 1, 1 do
            count = count + 1
            if count > 250 then return "" end  
            local line = self.lines[c]
            if not line then return "" end
            if whitespace(line) == true then continue end 

            for _, word in pairs(self.lexer.config.indentation.open or {}) do 
                bc = bc + countTimes(line, word) 
            end

            local canClose = false 
            for _, word in pairs(self.lexer.config.indentation.close or {}) do 
                local counts = countTimes(line, word)
                if counts ~= 0 then 
                    if bc == 0 then 
                        bot = getLeft(line) 
                        canClose = true 
                        break 
                    end 
                    bc = bc - counts
                end
            end
            if canClose == true then break end 
        end
        if bc ~= 0 then return "" end 
    end 
    
    local result = ""
    local centre = (#top + #bot) / 2 
    centre = centre + (centre % self.tabSize)
    if #bot == #top and #bot == centre then 
        result = string.rep(" ", #bot + self.tabSize) 
    else 
        result = string.rep(" ", centre)
    end

    local function trimIndentation(tabs)
        if not self.lexer.config.indentation.offsets then return tabs end 
 
        local line = self:GetLine(i) 
        line = string.TrimLeft(line, " ")

        for word, offset in pairs(self.lexer.config.indentation.offsets) do 
            local a,b,_ = string_find(line, word)

            if not a or not b then continue end 
            if a ~= 1 then continue end 

            if string_sub(line, 1, b) == word then 
                if offset == false then return "" end 
                if offset < 0 then 
                    return string_sub(tabs, offset, #tabs)
                end 
                return tabs .. string.rep(" ", offset)
            end
        end
        return tabs  
    end

    return trimIndentation(result) 
end

function syntaxBox:LineInsideCapture(i)
    if not i or not self.lines[i] then return false end 
    for group, data in pairs(self.lexer.config.captures) do 
        if ((self.tokens[i] or {})[1] or {}).type == group then 
            return true 
        end
    end
    return false 
end

function syntaxBox:IntendLine(i)
    if not i or not self.lines[i] or self:LineInsideCapture(i) == true then return "" end 
    local line = self:GetLine(i)
    local _,_,left = string_find(line, "^(%s*)") 
    left = left or ""
    if whitespace(line) == true then 
        local tabs = self:GetLineIndention(i)
        local add = tabs .. line
        self.lines[i] = add
        return add 
    elseif #left == 0 then 
        local add = self:GetLineIndention(i) 
        self.lines[i] = add .. self.lines[i]
        return add 
    else
        local ind = self:GetLineIndention(i)
        local r = ind .. string.TrimLeft(line, "%s")
        out(r)
        self.lines[i] = r 
        return ind
    end
    return ""
end

function syntaxBox:Undo()
    if self.undoTimeout and self.undoTimeout >= SysTime() then return end 
	if #self.undo or 0 > 0 then
        local undo = self.undo[#self.undo]
        self:ResetSelection()
        self.arrowSelecting = false 
        self.mouseSelecting = false 
        if undo then 
            self:SaveState()
            local released = 0
            local centerLine = 0 
            local c = 0
            for i, str in pairs(undo) do 
                centerLine = centerLine + i 
                c = c + 1
                if str == false then 
                    self.lines[i] = nil 
                    released = released + 1
                    continue 
                end
                self.lines[i] = str
                released = released + #str
            end
            centerLine = math.Round(centerLine / math.max(c, 1))
            self:Goto(0, centerLine)
            released = released / 1024 
            self.undoMemory = math.max(self.undoMemory - released, 0)
            self:CompState(true)
            self:OnUndo(undo)
            self.undo[#self.undo] = nil 
            self.undoTimeout = SysTime() + 0.01
            self:FixCaret()
            self.hasChanges = true 
        end
    end 
end

function syntaxBox:Redo()
    if self.redoTimeout and self.redoTimeout >= SysTime() then return end 
    if #self.redo or 0 > 0 then
        self:ResetSelection()
        self.arrowSelecting = false 
        self.mouseSelecting = false 
        local redo = self.redo[#self.redo]
        if redo then 
            self:SaveState()
            local centerLine = 0 
            local c = 0
            for i, str in pairs(redo) do    
                c = c + 1      
                centerLine = centerLine + i       
                if str == false then 
                    self.lines[i] = nil 
                    continue 
                end
                self.lines[i] = str
            end
            centerLine = math.Round(centerLine / math.max(c, 1))
            self:Goto(0, centerLine)
            self:CompState(-1)
            self:OnRedo(redo)
            self.redo[#self.redo] = nil 
            self.redoTimeout = SysTime() + 0.01
            self:FixCaret()
            self.hasChanges = true 
        end
    end
end

-- fix dis later
function syntaxBox:CheckGay() -- Funny Easteregg
 --   local function gu(i) 
 --       if not self.undo or not self.undo[#self.undo - i] then return "" end 
 --       return self.undo[#self.undo - i].text 
 --   end

 --   if string.lower(gu(2) .. gu(1) .. gu(0)) == "gay" then 
 --       self.gaymode = SysTime() + 3
 --   end
end

function syntaxBox:GetUndoMemory()
    return math.Round(self.undoMemory, 1).."kb"
end

function syntaxBox:SaveState()
    self.tempLines = table_Copy(self.lines)
end

function syntaxBox:ClearState()
    self.tempLines = nil 
end

function syntaxBox:CompState(isRedo)
    if not self.tempLines then return end 
    if not self.undo then self.undo = {} end
    local memory = 0
    local comp = compareLines(self.lines, self.tempLines)
    self:OnLinesChanged(comp[1], comp[2])
    self:_LinesChanged(comp[1], comp[2])
    local temp = {}
    for i = comp[1], comp[2], 1 do 
        local s = (self.tempLines[i] and self.tempLines[i] or false)
        temp[i] = s
        memory = memory + (type(s) == "string" and #s or 1) 
    end
    memory = memory / 1024 
    if not isRedo or isRedo == -1 then 
        self.undo[#self.undo + 1] = table_Copy(temp)
        if isRedo ~= -1 then 
            self.undoMemory = ((self.undoMemory or 0) + memory) or memory 
        end 
        if #self.undo > 1000 or self.undoMemory > 1024 then table_remove(self.undo, 1) end
        if #self.redo > 0 and isRedo ~= -1 then self.redo = {} end    
    else 
        self.redo[#self.redo + 1] = table_Copy(temp)
    end
    self.tempLines = nil 
end


function syntaxBox:Init()
    self:SetCursor("beam")

    ---- Config ----
    self.tabSize = 4 -- Tab space length
    self.scrollMult = 4 -- Scroll speed multiplier
    self.rescaleMult = 2
    self.lineNumMargin = 0.25 -- Line Number margin to the left of the numbers and right of the numbers
    self.textOffset = 2 -- offset after the right line margin

    self.colors = {}
    self.colors.editorBG = dark(45)
    self.colors.editorFG = dark(255)
    self.colors.lineNumbersBG = dark(35)
    self.colors.lineNumbersColor = Color(240,130,0)
    self.colors.lineNumbersOutline = dark(150)
    self.colors.caret = Color(25,175,25)
    self.colors.caretBlock = Color(25,150,25,50)
    self.colors.caretLine = Color(150,150,150,25)
    self.colors.tabIndicators = Color(175,175,175,35)
    self.colors.pairs = Color(0, 230, 230, 86)

    self.colors.highlights = Color(0,60,220,50)
    self.colors.selection = Color(185, 230, 45, 40)
    ---------------

    self.syntax = {}
    self.tokens = {}

    self.lexer = SixLexer
    self:ResetProfile()

    self.caret = {["char"]=1,["line"]=-1}
    self.selection = {["start"]={["char"]=0,["line"]=0}, ["dest"]={["char"]=0,["line"]=0}}
    self.textPos = {["line"]=1,["char"]=1}
    self.font = {["w"]=0,["h"]=0,["n"]="",["s"]=0,["an"]=""}
   -- self.altFonts = {}
    self.lines = {}
    self.undo = {}
    self.redo = {}
    self.highlights = {}

    -- Scrollbar
    self.scrollBar = vgui.Create("DVScrollBar", self)
    self.scrollBar:Dock(RIGHT)
    self.scrollBar.Dragging = false

    -- TextEntry
    self.textBox = vgui.Create("TextEntry", self)
    self.textBox:SetSize(0,0)
    self.textBox:SetMultiline(true)
    local tbox                     = self.textBox 
    self.textBox.OnLoseFocus       = function(self)       tbox.Parent:_FocusLost()           end
    self.textBox.OnTextChanged     = function(self)       tbox.Parent:_TextChanged()         end
    self.textBox.OnKeyCodeTyped    = function(self, code) tbox.Parent:_KeyCodePressed(code)  end
    self.textBox.OnKeyCodeReleased = function(self, code) tbox.Parent:_KeyCodeReleased(code) end
	self.textBox.Parent            = self;
                
    self.lastCaret = table_Copy(self.caret)
    self.lastTextPos = table_Copy(self.textPos)
    self.allTabs = {}
    self.lastOffset = 0
    self.caretTimer = 0
    self.mouseSelecting = false 
    self.arrowSelecting = false 
    self.pairMatches = nil 

    self.textBox:RequestFocus()
    self:FixCaret()
    self:ResetSelection()

    self:SetFont("Consolas", 16)

    -- Derma Objects
    --[[ 
        This turned out to be shit

    self.fontSizeWang = vgui.Create("DNumberWang", self)
    self.fontSizeWang:SetMin(8)
    self.fontSizeWang:SetMax(48)
    self.fontSizeWang:SetDecimals(0)
    self.fontSizeWang:SetValue(self.font.s)
    self.fontSizeWang:SetSize(35,21)
    local this = self 
    self.fontSizeWang.OnValueChanged = function(self)
        this:SetFont(this.font.an, self:GetValue())
    end
    self.fontSizeWang:SetTextColor(Color(255,255,255,255))
    self.fontSizeWang.Paint = function(self, w, h)
        draw.SimpleText(self:GetValue().."", "DermaDefault", w / 4, h / 2, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.RoundedBox(2, 0, 0, w * 2, h, Color(255,255,255,30))
    end

    self.fontSizeLabel = vgui.Create("DLabel", self)
    self.fontSizeLabel:SetText("Fontsize:")

    self.languageLabel = vgui.Create("DLabel", self)
    self.languageLabel:SetText("Language:")]]
end 

function syntaxBox:OnTextChanged() end 
function syntaxBox:OnFocusLost() end 
function syntaxBox:OnKeyCodePressed(code) end 
function syntaxBox:OnKeyCodeReleased(code) end 
function syntaxBox:OnKeyCombo(code1, code2) end 
function syntaxBox:OnScrolled(delta) end 
function syntaxBox:OnUndo(t) end 
function syntaxBox:OnRedo(t) end 
function syntaxBox:OnTextWritten(text) end 
function syntaxBox:OnLinesChanged(start, ending) end


function syntaxBox:SetProfile(syntaxConfig)
    if not syntaxConfig then return end 
    self.lexer:SetConfig(syntaxConfig)
    if not self.lexer.config.language or string.gsub(self.lexer.config.language, "%s", "") == "" then 
        self:ResetProfile()
    end
end

function syntaxBox:ResetProfile()
    self:SetProfile({
        language     = "Plain",
        filetype     = ".txt",
        reserved     = {},
        unreserved   = {},
        closingPairs = {},
        intending    = {},
        Matches      = {},
        captures     = {},
        colors       = {}})
end

function syntaxBox:SetCaret(char, line)
    self.lastCaret = table_Copy(self.caret)
    if not line and type(char) == "table" then 
        self.caret = table_Copy(char)
      --  self:FixCaret()
        return 
    end
    line = line or self.caret.line 
    self.caret.char, self.caret.line = char, line 
  --  self:FixCaret()
end

function syntaxBox:SetFont(font, size)
    if not font then return end 
    size = math.Clamp(size, 8, 48)
    local newFont = "SLF" .. font  .. size
    if not fontBank[newfont] then
        local fontData_default = {
            font      = font,
            size      = size,
            weight    = 500,
            antialias = false,
            additive  = false
        }
        surface.CreateFont(newFont, fontData_default)
        fontBank[newFont] = 1
    end
    surface.SetFont(newFont)
    local w, h  = surface.GetTextSize(" ")
    self.font = {["w"]=w,["h"]=h,["n"]=newFont,["s"]=size,["an"]=font}
end

function syntaxBox:SetText(text)
    
    self.lines = string.Split(text, "\n")
    self:FixCaret()
    self.lexer:SetLines(self.lines)

    self.caret = {["char"]=1,["line"]=-1}
    self.selection = {["start"]={["char"]=0,["line"]=0}, ["dest"]={["char"]=0,["line"]=0}}
    self.textPos = {["line"]=1,["char"]=1}

    self.lastCaret = table_Copy(self.caret)
    self.lastTextPos = table_Copy(self.textPos)

    self.highlights = {}
    self.allTabs = {}
    self.lastOffset = 0
    self.caretTimer = 0
    self.mouseSelecting = false 
    self.arrowSelecting = false 
    self.pairMatches = nil 

    self:ResetHighlighting()
    self:ResetSelection()
    self.mouseSelecting = false 
    self.arrowSelecting = false 
    self.lastLines = table_Copy(self.lines) 
    self.hasChanges = true 
end

function syntaxBox:GetSelectedText()
    return self:GetTextFrom(self.selection.start, self.selection.dest)
end

function syntaxBox:GetText()
    return table.concat(self.lines, "\n")
end

function syntaxBox:GetLine(i)
    if not i then return nil end 
    return self.lines[i] 
end

function syntaxBox:AddHighlight(startChar, startLine, endChar, endLine)
    local start = {["char"]=startChar, ["line"]=startLine}
    local dest  = {["char"]=endChar, ["line"]=endLine}
    table_insert(self.highlights, {["start"]=start, ["ending"]=dest})
end 

function syntaxBox:ResetHighlighting()
    self.highlights = {}
end

function syntaxBox:StartSelection(char, line)
    if not line and type(char) == "table" then 
        self.selection.start = table_Copy(char)
        return 
    end
    self.selection.start = {char = char, line = line}
end

function syntaxBox:EndSelection(char, line)
    if not line and type(char) == "table" then 
        self.selection.dest = table_Copy(char)
        return 
    end
    self.selection.dest = {char = char, line = line}
end

function syntaxBox:HasSelection()
    return self.selection.start.char ~= self.selection.dest.char or self.selection.start.line ~= self.selection.dest.line
end

function syntaxBox:ResetSelection()
    self.selection.start = table_Copy(self.caret)
    self.selection.dest  = table_Copy(self.caret)
end

function syntaxBox:OverrideSelection(text)
    self:FlipSelection()
    local save = table_Copy(self.selection.start)
    self:RemoveSelectedText()
    self:FixCaret()
    self:PasteTextAt(text, save.char, save.line )
end

function syntaxBox:RemoveSelectedText(ressr)
    self:RemoveTextFromTo(self.selection.start, self.selection.dest)   
    if not ressr then 
        self:ResetSelection()
        self.arrowSelecting = false 
        self.mouseSelecting = false 
        self.hasChanges = true 
    end
end

function syntaxBox:FixCaret()
    self.lastCaret = table_Copy(self.caret)
    local line = math.Clamp(self.caret.line, 1, #self.lines)
    local char = math.Clamp(self.caret.char, 0, #(self.lines[self.caret.line] or ""))
    self.caret = {char = char, line = line}
    self:RetimeRematch()
end

function syntaxBox:FixPoint(char, line)
    local y = math.Clamp(line, 1, #self.lines)
    local x = math.Clamp(char, 0, #self.lines[y]) 
    return x, y
end

function syntaxBox:RematchPairs()
    local pairs = self:GetSurroundingPairs(self.caret.char, self.caret.line)
    if pairs and not self.lexerDiffCheck then 
        self.pairMatches = pairs 
    else 
        self.pairMatches = nil 
    end
end

function syntaxBox:ReTimeCaret()
    self.caretTimer  = SysTime() + 0.5
    self.caretToggle = true 
end

function syntaxBox:PosInText(x, y)
    x = x - self.lastOffset - self.font.w / 2 
    y = math.Round(mSub(y, self.font.h) / self.font.h + self.textPos.line)
    x = math.Round(mSub(x, self.font.w) / self.font.w + self.textPos.char)
    return x, y
end

function syntaxBox:PosOnPanel(char, line)
    local x, y = self.lastOffset, 0
  --  local tk = self:GetTokenAtPoint(char, line)
    local w =  self.font.w--(not tk and self.font.w or self:FontData(tk).w)
    x = x + char * w
    x = math.max(x - (self.textPos.char - 1) * w, self.lastOffset)
    y = line * self.font.h 
    return x, y
end

function syntaxBox:CaretFromLocal(x, y)
    local px, py = self:PosInText(x, y)
    self:SetCaret(px, py)
    self:FixCaret()
    self:ReTimeCaret()
end

function syntaxBox:RunLexer() -- Buggy piece of shit
    if self.runLexCoroutine and coroutine_status(self.runLexCoroutine) ~= "running" then 
        self.runLexCoroutine = nil 
    elseif self.runLexCoroutine and coroutine_status(self.runLexCoroutine) == "running" then 
        coroutine_yield(self.runLexCoroutine) 
        self.runLexCoroutine = nil 
    end
    self.lexAll = true 
end

function syntaxBox:ParseVisibleLines()
    self.lexer:SetLines(self.lines)
    for i = self.textPos.line, self.textPos.line + math.ceil(self:GetTall() / self.font.h) - 1, 1 do 
        local line = self.lines[i]
        if not line then break end
        self.tokens[i] = self.lexer:ParseLine(i, self.tokens[i - 1] or nil)
        self.lastLines[i] = line 
    end
end

function syntaxBox:Goto(char, line)
    do -- Line Difference 
        local bot = self.textPos.line + 2
        local top = bot + math.ceil(self:GetTall() / self.font.h) - 5
        local diff = 0
        if line < bot then
            diff = line - bot   
        elseif line > top then
            diff = line - top 
        end
        local mabs = math.abs(diff)
        if mabs ~= 0 then 
         --   if mabs > 1 then 
         --       self.scrollBar:AnimateTo(self.scrollBar:GetScroll() + diff, 0.25)
         --   else    
                self.scrollBar:SetScroll(self.scrollBar:GetScroll() + diff)
         --   end
            self:UpdateTabIndicators()
        end
    end

    do -- Char Difference
        local bot = self.textPos.char - 1
        local top = self.textPos.char + math.ceil((self:GetWide() - self.scrollBar:GetWide() - self.lastOffset - self.font.w) / self.font.w) - 4
        local diff = 0
        if char < bot then
            diff = char - bot         
        elseif char > top then 
            diff = char - top 
        end

        if math.abs(diff) > 0 then 
            self.textPos.char = self.textPos.char + diff
        end 
    end

    self:ParseVisibleLines()
end

function syntaxBox:Highlight(start, ending, i, col)
    if not start or not ending or not i then return end 
    col = col or self.colors.highlights
    surface.SetDrawColor(col)
    local limit = self.font.w / 2
    local c = i - self.textPos.line  
    local line = self.lines[i]
    if start.line == ending.line and i == start.line then -- If selection is in the same Line 
        local sx,sy = self:PosOnPanel(start.char, c)
        local ex,ey = self:PosOnPanel(ending.char, c)
        if ending.char > start.char then 
            surface.DrawRect(sx, sy, ex - sx, self.font.h)
        else
            surface.DrawRect(ex, ey, sx - ex, self.font.h)
        end
    elseif i == ending.line then -- if multiline, end of line selection
        if ending.line > start.line then 
            local ex,ey = self:PosOnPanel(ending.char, c)
            local sx,sy = self:PosOnPanel(0, c)
            surface.DrawRect(sx, sy, ex - sx, self.font.h)
        else
            local sx,sy = self:PosOnPanel(ending.char, c)
            local ex,ey = self:PosOnPanel(#line, c)     
            surface.DrawRect(sx, sy, ex - sx, self.font.h)               
        end
    elseif i == start.line then -- if multiline, start of line selection
        if ending.line > start.line then 
            local sx,sy = self:PosOnPanel(start.char, c)
            local ex,ey = self:PosOnPanel(#line, c)
            surface.DrawRect(sx, sy, math.max(ex - sx, limit), self.font.h)
        else
            local ex,ey = self:PosOnPanel(start.char, c)
            local sx,sy = self:PosOnPanel(0, c)
            surface.DrawRect(sx, sy, math.max(ex - sx, limit), self.font.h)
        end
    elseif ((i >= start.line and i <= ending.line) or (i <= start.line and i >= ending.line)) then -- All Lines inbetween Start and End of Selection  
        local sx,sy = self:PosOnPanel(0, c)
        local ex,ey = self:PosOnPanel(#line, c)
        surface.DrawRect(sx, sy, math.max(ex - sx, limit), self.font.h)
    end
end

function syntaxBox:RetimeDiffCheck()     self.lexerDiffCheck = SysTime()    + 0.33 end
function syntaxBox:RetimeRematch()       self.pairMatchTimer = SysTime()    + 0.25 end
function syntaxBox:RetimeVisiblesParse() self.parseVisibleTimer = SysTime() + 0.1  end

 --[[                              
                                 _   _             _        
                                | | | |           | |       
                                | |_| | ___   ___ | | _____ 
                                |  _  |/ _ \ / _ \| |/ / __|
                                | | | | (_) | (_) |   <\__ \
                                \_| |_/\___/ \___/|_|\_\___/
                                ]]

function syntaxBox:_TextChanged()
    self:SaveState()

    local text = self.textBox:GetText()

    if text == "\n" or not text or text == "" or #text == 0 then 
        self.textBox:SetText("")
        return 
    end 

    if #text > 1 then 
        if self.pasteCooldown and self.pasteCooldown >= SysTime() then else  
            if self:HasSelection() == true then 
                self:FlipSelection()
                self:RemoveSelectedText()
                self:FixCaret()
                self:PasteTextAt(text, self.caret.char, self.caret.line )
            else     
                self:PasteTextAt(text, self.caret.char, self.caret.line)
            end 
            self.pasteCooldown = SysTime() + 0.066
        end 
        self:OnTextWritten(text)
    else
        if self:HasSelection() then
            self:RemoveSelectedText()
        end

        local function add(t)
            local line = self:GetLine(self.caret.line)
            self.lines[self.caret.line] = string_sub(line, 1, self.caret.char) .. t .. string_sub(line, self.caret.char + 1, #line) 
            self:SetCaret(self.caret.char + #t)  
        end

        local save = text 

        add(text)

        local line = self:GetLine(self.caret.line)
        for _, v in pairs(self.lexer.config.autoPairing or {}) do 
            local sub = string_sub(line, self.caret.char - #v.word + 1, self.caret.char - 1) .. text 
            if sub == v.word  and v.validation(line, self.caret.char, self.caret.line) == true then 
                add(v.pair)
                save = save .. v.pair 
                self:SetCaret(self.caret.char - #v.pair)
                break 
            end
        end

        self:OnTextWritten(save)
    end

    self:CompState() 

    self:ResetSelection()
    self.arrowSelecting = false 
    self.mouseSelecting = false 

    self.textBox:SetText("")
    self:FixCaret()
    self:Goto(self.caret.char, self.caret.line)
    self.hasChanges = true 
end

function syntaxBox:FlipSelection()
    if self.selection.start.line > self.selection.dest.line or (self.selection.start.line == self.selection.dest.line and self.selection.start.char > self.selection.dest.char) then 
        self.selection.start, self.selection.dest = swap(self.selection.start, self.selection.dest)
    end 
end

function syntaxBox:OverrideLines(start, ending, newLines)
    if not start or not ending or not newLines then return end
    local function flip()
        local save = ending
        ending = start
        start = save     
    end
    if start ~= ending and ending < start then 
        flip()
    end
    local c = 1
    for i = start, ending, 1 do 
        if not self.lines[i] or not newLines[c] then continue end 
        self.lines[i] = newLines[c]
        c=c+1
    end
end

function syntaxBox:GetLines(start,ending)
    if not start or not ending then return end
    local function flip()
        local save = ending
        ending = start
        start = save     
    end
    if start ~= ending and ending < start then 
        flip()
    end
    local c = 1
    local r = {}
    for i = start, ending, 1 do 
        if not self.lines[i] then continue end 
        r[c] = self.lines[i]
        c=c+1
    end
    return r 
end

function syntaxBox:IndentCaret()
    local len = self:IntendLine(self.caret.line) 
    if #len == 0 then 
        self:IntendLine(self.caret.line)
    end
    self:SetCaret(self.caret.char + #len)
    return #len 
end

function syntaxBox:_KeyCodePressed(code)
    self:OnKeyCodePressed(code)

    local function intendCaret()
        return self:IndentCaret()
    end

    local function tabs()
        return string.rep(" ", self.tabSize, "")
    end

    local function checkOutside()
        self:FixCaret()
        self:Goto(self.caret.char, self.caret.line)
    end 

    local function checkSelection()
        if self.arrowSelecting then 
            self:EndSelection(self.caret.char, self.caret.line)
        elseif self:HasSelection() then  
            self:ResetSelection()
            self.mouseSelecting = false
            self.arrowSelecting = false        
        end
    end
--https://wiki.facepunch.com/gmod/Enums/KEY
    local shift   = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
	local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

    local red = false 

    if shift then 
        if self.arrowSelecting == false then 
            if self.mouseSelecting == false then 
                self:ResetSelection()
            end 
            self.arrowSelecting = true 
        end 
        self:ResetHighlighting()
    elseif control then 
        if code == KEY_C then
            SetClipboardText(self:GetSelectedText())
            self:ResetHighlighting()
            red = true 
        elseif code == KEY_Z then 
            self:Undo()
            self:ResetHighlighting()
            red = true 
            self.hasChanges = true 
        elseif code == KEY_Y then 
            self:Redo()
            self:ResetHighlighting()
            red = true 
            self.hasChanges = true 
        elseif code == KEY_A then 
            self:ResetSelection()
            self:StartSelection(0,1)
            local lastLine = self.lines[#self.lines]
            self:EndSelection(#lastLine, #self.lines)
            self:SetCaret(self.selection.dest.char, self.selection.dest.line)
          --  checkOutside()
            self:ResetHighlighting()
            red = true 
        elseif code == KEY_X then 
            if self:HasSelection() == true then 
                self:SaveState()
                self:RemoveSelectedText()
                self.hasChanges = true 
                self:CompState()
                self:ResetHighlighting()
                checkSelection()
            end 
            red = true 
        elseif code == KEY_TAB then 
            if self:HasSelection() then 
                self:SaveState()
                self:FlipSelection()
                local selLines = self:GetLines(self.selection.start.line, self.selection.dest.line)
                local newLines = {}
                for k, line in pairs(selLines) do 
                    local _, _, tabs = string_find(line, "^(%s*)")
                    if #tabs < self.tabSize then 
                        newLines[k] = line 
                        continue 
                    end
                    newLines[k] = string_sub(line, math.Clamp(self.tabSize, 1, #line) + 1, #line) or line  
                end
                self:OverrideLines(self.selection.start.line, self.selection.dest.line, newLines)
                self:StartSelection(0, self.selection.start.line)
                self:EndSelection(#(self.lines[self.selection.dest.line] or ""), self.selection.dest.line)
                self:SetCaret(self.selection.dest)
                self:FixCaret()
                red = true 
                self.hasChanges = true 
                self:CompState()
            end 
        elseif code == KEY_UP then 
            self:SetCaret(self.caret.char, self.caret.line - self.tabSize)
            self:FixCaret()
            red = true 
        elseif code == KEY_DOWN then 
            self:SetCaret(self.caret.char, self.caret.line + self.tabSize)
            self:FixCaret()
            red = true 
        elseif code == KEY_RIGHT then 
            self:SetCaret(self.caret.char + self.tabSize)
            self:FixCaret()
            red = true 
        elseif code == KEY_LEFT then 
            self:SetCaret(self.caret.char - self.tabSize)
            self:FixCaret()
            red = true 
        end
    end

    if red == true then 
        self:OnKeyCombo(control, code)
        self:ReTimeCaret()
        return 
    end 

    if code == KEY_DOWN then
        self:SetCaret(self.caret.char, self.caret.line + 1)

        -- Auto Indenting
        local cL = self.lines[self.caret.line]
        local left = getLeft(cL)
        if whitespace(cL) == true then 
            intendCaret()
        elseif (self.caret.char <= #left and self.caret.char > #left - self.tabSize) 
        or ((self.caret.char % self.tabSize) == 0 and self.caret.char == #left - self.tabSize) then 
            self:SetCaret(#left)
        end

        checkOutside()
        checkSelection()
        self:ResetHighlighting()
        self:RematchPairs()
    elseif code == KEY_UP then
        self:ResetHighlighting()
        self:SetCaret(self.caret.char, self.caret.line - 1)

        -- Auto Indenting
        local cL = self.lines[self.caret.line]
        local left = getLeft(cL)
        if whitespace(cL) == true then 
            intendCaret()
        elseif (self.caret.char <= #left and self.caret.char > #left - self.tabSize) 
         or ((self.caret.char % self.tabSize) == 0 and self.caret.char == #left - self.tabSize) then 
            self:SetCaret(#left)
        end

        checkOutside()
        checkSelection()
        self:ResetHighlighting()
        self:RematchPairs()
    elseif code == KEY_RIGHT then
        local line = self.lines[self.caret.line]

        self:SetCaret(self.caret.char + 1)

        if self.caret.char > #self.lines[self.caret.line] then
            self:SetCaret(0, self.caret.line + 1)
        end
        checkOutside()
        checkSelection()
        self:ResetHighlighting()
        self:RematchPairs()
    elseif code == KEY_LEFT then
        local line = self.lines[self.caret.line]
 
        self:SetCaret(self.caret.char - 1)

        if self.caret.char < 0 then
            self:SetCaret(self.caret.char, self.caret.line - 1)
            local line = self.lines[self.caret.line]
            if line then
                self:SetCaret(#line)
            end
        end
        checkOutside()
        checkSelection()
        self:ResetHighlighting()
        self:RematchPairs()
    elseif code == KEY_BACKSPACE then 
        self:SaveState()
        if self:HasSelection() == true then 
            self:FlipSelection()
            self:RemoveSelectedText()
            self:ResetSelection()
            self.arrowSelecting = false 
            self.mouseSelecting = false 
        else 
            local line = self.lines[self.caret.line]
            local l = string_sub(line, 1, self.caret.char)
            local r = string_sub(line, self.caret.char + 1, #line)
         
            -- Intend tab spaces 
            if string_sub(l, #l - self.tabSize + 1, #l) == tabs() then 
                self.lines[self.caret.line] = string_sub(line, 1, self.caret.char - self.tabSize) .. string_sub(line, self.caret.char + 1, #line)
                self:SetCaret(self.caret.char - self.tabSize)
            else 
                local function rem(i, len)
                    local li = self.lines[self.caret.line]
                    self.lines[self.caret.line] = string_sub(li, 1, i) .. string_sub(li, i + len + 1, #line)
                end

                local char = line[self.caret.char] or "" 

                for _, v in pairs(self.lexer.config.autoPairing or {}) do 
                    if char == v.word[#v.word] and v.validation(line, self.caret.char, self.caret.line) == true then 
                        if string_sub(line, self.caret.char + 1, self.caret.char + #v.pair) == v.pair then 
                            rem(self.caret.char, #v.pair)
                            break 
                        end 
                    end
                end

                self:SetCaret(self.caret.char - 1)
                rem(self.caret.char, 1)
            end 

            if self.caret.char < 0 and self.caret.line > 1 then 
                table_remove(self.lines, self.caret.line)
                local r = string_sub(line, self.caret.char + 1, #line)
                self:SetCaret(self.caret.char, self.caret.line - 1)
                local save = self.lines[self.caret.line]
                self.lines[self.caret.line] = self.lines[self.caret.line] .. r 
                self:SetCaret(#save)
            elseif self.caret.line == 1 and self.caret.char < 0 then 
                self.lines[self.caret.line] = line
            end
        end 
        self:CompState()
        self.hasChanges = true 
        checkOutside() 
    elseif code == KEY_ENTER then 
        self:SaveState()
        if self:HasSelection() then 
            self:RemoveSelectedText()
        else        
            local line = self.lines[self.caret.line]
            local l = string_sub(line, 1, self.caret.char)
            local r = string_sub(line, self.caret.char + 1, #line)
            self.lines[self.caret.line] = string.TrimLeft(l, " ")
            self:IntendLine(self.caret.line)
            table_insert(self.lines, self.caret.line + 1, r or "")
            self:SetCaret(0, self.caret.line + 1)
        --    if #getLeft(self.lines[self.caret.line]) ~= 0 then 
                self.lines[self.caret.line] = string.gsub(self.lines[self.caret.line], "^(%s*)", "")
                intendCaret()
      --     end 
        end
        self:CompState()
        self.hasChanges = true 
        checkOutside()    
    elseif code == KEY_TAB then 
        self:SaveState()
        if self:HasSelection() == false then 
            local line = self.lines[self.caret.line]
            local l = string_sub(line, 1, self.caret.char)
            local r = string_sub(line, self.caret.char + 1, #line)
            local retabbed = false 
            ::ReTab::
            if #l == 0 and retabbed == false then 
                local len = intendCaret()
                if len == 0 then 
                    retabbed = true 
                    goto ReTab 
                end
                self.lines[self.caret.line] = string.rep(" ", len) .. r
                self:SetCaret(len)
            else 
                self.lines[self.caret.line] = l .. tabs() .. r
                self:SetCaret(self.caret.char + self.tabSize)
            end 
        else 
            if math.abs(self.selection.start.line - self.selection.dest.line) > 1 then 
                self:FlipSelection()
                local selLines = self:GetLines(self.selection.start.line, self.selection.dest.line)
                local newLines = {}
                for k, v in pairs(selLines) do 
                    newLines[k] = tabs() .. v 
                end
                self:OverrideLines(self.selection.start.line, self.selection.dest.line, newLines)
                self:StartSelection(0, self.selection.start.line)
                self:EndSelection(#(self.lines[self.selection.dest.line] or ""), self.selection.dest.line)
                self:SetCaret(self.selection.dest)
            else 
                self:OverrideSelection(tabs())
                intendCaret()
            end
        end
        self:CompState()
        checkOutside()
        self.hasChanges = true 
    end

 --   self:FixCaret()
    self.codePressed = code 
    self:ReTimeCaret()
end

function syntaxBox:_KeyCodeReleased(code)
    self.codePressed = nil 

    self:OnKeyCodeReleased(code)

    if code == KEY_LSHIFT or code == KEY_RSHIFT then 
        self.arrowSelecting = false 
    elseif code == KEY_LCONTROL or code == KEY_RCONTROL then 
        
    end
end

function syntaxBox:OnMousePressed(code)
    local mx, my = self:LocalCursorPos()
    self:CaretFromLocal(mx, my)

    self.clickCounter = (self.clickCounter or 0) + 1
    if self.clickCounter > 2 then self.clickCounter = 0 end 

    if code == MOUSE_RIGHT then
        
    elseif code == MOUSE_LEFT then 
        self:RematchPairs()
    end

    if self:HasSelection() then 
        self:ResetSelection()
        self.mouseSelecting = false
        self.arrowSelecting = false 
    end 

    local function resDef()
        if  self:HasSelection() == false then 
            self:ResetHighlighting()
            local word = self:GetWordAtPoint(self.caret.char, self.caret.line)
            if word then 
                self:HighlightWords(word)
            end 
        end  
        self.clickCounter = 0
    end

    if self.lastClickPos and self.caret.char == self.lastClickPos.char and self.caret.line == self.lastClickPos.line then 
        self:ResetHighlighting()
        if self.clickCounter == 1 then 
            self:ResetHighlighting()
            local word, start = self:GetWordAtPoint(self.caret.char, self.caret.line)
            if word and start then 
                self:StartSelection(start - 1, self.caret.line)
                self:EndSelection(start + #word - 1, self.caret.line)
            end
        elseif self.clickCounter == 2 then 
            local line = self.lines[self.caret.line]
            self:StartSelection(0, self.caret.line)
            self:EndSelection(#line, self.caret.line)
        else 
            resDef()
        end
    else 
        resDef()
    end

    self.lastClickPos = table.Copy(self.caret)
    self:Goto(self.caret.char, self.caret.line)
end

function syntaxBox:OnMouseReleased(code)
    if code == MOUSE_LEFT then 

    end
end

function syntaxBox:_FocusLost()
    self.textBox:RequestFocus()
    self:OnFocusLost()
end

function syntaxBox:Think()
    local w, h = self:GetSize()
    local vLines = math.ceil(h / self.font.h) - 1
    local vChars = math.ceil(w / self.font.w)

    self.scrollBar:SetUp(vLines, #self.lines + 1)

    -- Scrollbar out of bounds check
    do 
		local scroll = self.scrollBar:GetScroll()
		self.textPos.line = math.ceil(scroll + 1)
        self.scrollBar:SetScroll(scroll)
        if self.lastTextPos.line ~= self.textPos.line then 
            if self:HasSelection() then 
                self:HighlightWords(self:GetSelectedText())
            end 
            self:UpdateTabIndicators()
            self:RematchPairs()
            self:ParseVisibleLines()
            self.parseVisibleTimer = nil 
        end
	end

    -- Caret Blink
    if SysTime() > self.caretTimer then
        self.caretTimer  = SysTime() + 0.5
        self.caretToggle = not self.caretToggle 
    end

    -- Pair matching trigger
    if self.caret.char ~= self.lastCaret.char or self.caret.line ~= self.lastCaret.line then 
        if (self.lastTextPos.char ~= self.textPos.char) and self.hasChanges == false then 
            if self.lexerDiffCheck then 
                self:RetimeDiffCheck()
            end 
        end

     --   self:RematchPairs()
     --   self.lastCaret = table_Copy(self.caret)
    end 

    if self.parseVisibleTimer and SysTime() > self.parseVisibleTimer then 
        self:ParseVisibleLines()
        self.parseVisibleTimer = nil 
    end

    if self.pairMatchTimer and SysTime() > self.pairMatchTimer then 
        self:RematchPairs()
        self.pairMatchTimer = nil 
    end
    
    -- Area Selection
    if self:IsHovered() and self.scrollBar.Dragging == false and self.arrowSelecting == false then 
        if input.IsMouseDown(MOUSE_LEFT) then
            local mx, my = self:LocalCursorPos()  
            local px, py = self:PosInText(mx, my)
            local px, _ = self:FixPoint(px, py)

            if self.mouseSelecting == false then 
                if (px ~= self.caret.char or py ~= self.caret.line) and self.lines[py] then 
                    self:ResetSelection()
                    self:StartSelection(self.caret)
                    self.mouseSelecting = true 
                elseif self.lines[py] == nil then
                    self:ResetSelection()
                    self.caret.char = #self.lines[#self.lines]
                end
            else 
                if self.lines[py] then 
                    self:ReTimeCaret()
                    self:EndSelection(px, py)
                    self:SetCaret(px, py)
                    self:FixCaret()

                    if my < (self.font.h * 4) then 
                        local minus = 1 - math.Clamp((1 / (self.font.h * 4)) * my,0.1,1)
                        local scroll = math.max(self.scrollBar:GetScroll() - minus * 4, 0)
                        self.textPos.line = math.ceil(scroll + 1)
                        self.scrollBar:SetScroll(scroll)
                    elseif my > (h - self.font.h * 4) then  
                        my = h - my 
                        local minus = 1 - math.Clamp((1 / (self.font.h * 4)) * my,0.1,1)
                        local scroll = self.scrollBar:GetScroll() + minus * 4
                        self.textPos.line = math.min(math.ceil(scroll + 1), #self.lines - vLines + 2)
                        self.scrollBar:SetScroll(scroll)
                    end 
                end
            end 
        end
    end

    self.lastTextPos = table_Copy(self.textPos) 
 --   self.lastCaret   = table_Copy(self.caret)

    if self.lexAll and not self.runLexCoroutine then 
        local lineCounter = 0
        local diff = compareLines(self.lastLines or {}, self.lines)
        self.lexer:SetLines(self.lines)
        if diff[1] ~= 0 and diff[2] ~= 0 then 
            local ml = math.ceil(self:GetTall() / self.font.h)
            self.runLexCoroutine = coroutine_create(function()
                for i = diff[1], diff[2], 1 do 
                    local lineTokens = self.lexer:ParseLine(i, self.tokens[i - 1])
                    self.tokens[i] = lineTokens
                    self:TrimRightLine(i)
                    lineCounter = lineCounter + 1
                    if lineCounter > 150 then 
                        lineCounter = 0
                        coroutine_wait(0.1)
                    end
                end
                self.lastLines = table_Copy(self.lines) 
                self.hasChanges = false 
                self.lexAll = nil 
                if coroutine_status(self.runLexCoroutine) == "running" then coroutine_yield(self.runLexCoroutine) end
            end)
        end 
    elseif self.runLexCoroutine then 
        coroutine_resume(self.runLexCoroutine)
    end
end

function syntaxBox:PaintCaret(i)
    local line = self.lines[i] 
    if not line then return end 
    local offset = self.lastOffset or 0 
    local w = self:GetWide() or 0 
    local c = i - self.textPos.line  
    local lpos = c * self.font.h
    if i == self.caret.line and self.caret.line ~= -1 then
        local caretX = offset + ((self.caret.char - self.textPos.char + 1) * self.font.w)

        draw.RoundedBox(0, offset, lpos, w - offset, self.font.h, self.colors.caretLine)

        if self.caretToggle then 
            draw.RoundedBox(0, caretX, lpos, 2, self.font.h, self.colors.caret)
        end
        
        if self.caret.char < #line then 
            -- Caret Block 
            draw.RoundedBox(0, caretX, lpos, self.font.w, self.font.h, self.colors.caretBlock)
        end 
    else
        -- Trim right whitespaces
        self:TrimRightLine(i)
    end
end

function syntaxBox:PaintBackground()
    local w, h = self:GetSize()
    local vLines = math.ceil(h / self.font.h) - 1
    local lnm = self.lineNumMargin * self.font.w * 1.5
    local offset = self.lastOffset
    local lineNumWidth = #tostring(self.textPos.line + vLines - 1) * self.font.w

    -- Background
    draw.RoundedBox(0,lineNumWidth + lnm + self.font.w,0,w,h, self.colors.editorBG)

    -- Line Numbers Background
    draw.RoundedBox(0,0,0,lineNumWidth + lnm + self.font.w,h, self.colors.lineNumbersBG) 

    -- Editor & Line Numbers Seperator
 --   surface.SetDrawColor(self.colors.lineNumbersOutline)
 --   surface.DrawLine(lineNumWidth + self.font.w, 0, lineNumWidth + self.font.w, h) 
    surface.SetDrawColor(self.colors.lineNumbersOutline)
    surface.DrawLine(lineNumWidth + lnm + self.font.w, 0, lineNumWidth + lnm + self.font.w, h) 
end

function syntaxBox:Paint(w, h)
    local vLines = math.ceil(h / self.font.h) - 1
    local vChars = math.ceil(w / self.font.w)

    local lineNumWidth = #tostring(self.textPos.line + vLines - 1) * self.font.w

    local lnm = self.lineNumMargin * self.font.w * 1.5

    local offset = (lineNumWidth + (lnm) + self.font.w + self.textOffset) 

    self:PaintBackground()

   -- lnm = lnm + self.font.w 

    local errorIndicators = {}
    local rightTrimmed = false 
    local c = 0
    for i = self.textPos.line, self.textPos.line + vLines, 1 do 
        local line = self.lines[i]
        if not line then break end 

        local lpos = c * self.font.h

        -- Line Numbers
        draw.SimpleText(i, self.font.n, 2.5, c * self.font.h, self.colors.lineNumbersColor) 

        -- Caret 
        self:PaintCaret(i)
        
        -- Syntax Coloring 
        if self.tokens[i] and self.lines[i] and self.lexer.config.language ~= "Plain" then 
            local hasError = false 
            local lastY = 0
            for tokenIndex, token in pairs(self.tokens[i] or {}) do 
                local txt = token.text
    
                if token.ending < self.textPos.char or token.start > self.textPos.char + vChars then 
                    continue
                elseif token.start < self.textPos.char and token.ending >= self.textPos.char then  
                    txt = string_sub(txt, self.textPos.char - token.start + 1, #txt)
                end
    
                if token.type == "newline" then 
                    draw.SimpleText("топ", self.font.n, offset + lastY, c * self.font.h, self.colors.tabIndicators)
                    continue       
                elseif token.type == "error" then 
                    hasError = true 
                end
                
                local syntaxCol = {}
    
                if self.gaymode and SysTime() < self.gaymode then 
                    syntaxCol = HSVToColor((SysTime()*100 + i*5 + tokenIndex*5) % 360, 1, 1)
                else 
                    syntaxCol = self.lexer.config.colors[token.type] or Color(255,255,255) 
                end 
    
                local textY, _ = draw.SimpleText(txt, self.font.n, offset + lastY, c * self.font.h, syntaxCol)
    
                lastY = lastY + textY
            end
    
            if hasError == true and not errorIndicators[i] then -- Error indicator
                draw.RoundedBox(0, lineNumWidth + self.font.w - 1, lpos, lnm - 1, self.font.h, self.lexer.config.colors.error or Color(255,0,0))
                errorIndicators[i] = 1      
            end
        elseif (not self.tokens[i] and self.lines[i]) or self.lexer.config.language == "Plain" then 
            local txt = string_sub(line, self.textPos.char, self.textPos.char + vChars) 
            draw.SimpleText(txt, self.font.n, offset , c * self.font.h, self.colors.editorFG)
        end

        -- Pair highlighting
        if self.pairMatches and not self.pairMatchTimer and self.lexer.config.language ~= "Plain" then 
            local open  = self.pairMatches.start  
            local close = self.pairMatches.ending  
            local pcol  = self.colors.pairs 
            local hasError = false 
            if not open or not close then 
                pcol = self.lexer.config.colors.error or Color(255,100,100,50)
                hasError = true 
            end

            if open then 
                if i == open.line and open.char >= self.textPos.char then 
                    draw.RoundedBox(0, offset + (open.char - self.textPos.char) * self.font.w, lpos, self.font.w, self.font.h, pcol)
                    if hasError and not errorIndicators[i] then 
                        draw.RoundedBox(0, lineNumWidth + self.font.w - 1, lpos, lnm - 1, self.font.h, self.lexer.config.colors.error or Color(255,0,0))
                        errorIndicators[i] = 1    
                    end
                end 
            end

            if close then 
                if i == close.line and close.char >= self.textPos.char then 
                    draw.RoundedBox(0, offset + (close.char - self.textPos.char) * self.font.w, lpos, self.font.w, self.font.h, pcol)
                    if hasError and not errorIndicators[i] then 
                        draw.RoundedBox(0, lineNumWidth + self.font.w - 1, lpos, lnm - 1, self.font.h, self.lexer.config.colors.error or Color(255,0,0))
                        errorIndicators[i] = 1    
                    end
                end 
            end 

            if open and close then 
                local picol = table_Copy(pcol)  
                picol.a = 255
                if math.abs(open.line - close.line) > 1 and not errorIndicators[i] then 
                    if ((i >= open.line and i <= close.line) or (i <= open.line and i >= close.line)) then 
                        draw.RoundedBox(0, lineNumWidth + self.font.w - 1, lpos, lnm - 1, self.font.h, picol)
                    end
                elseif math.abs(open.char - close.char) > 1 and i == open.line then  
                    surface.SetDrawColor(picol)
                    local max = offset + w 
                    local z = lpos + self.font.h
                    local startChar = math.Clamp((open.char - self.textPos.char + 1) * self.font.w + offset, offset, max)
                    local endChar   = math.Clamp((close.char - self.textPos.char) * self.font.w + offset, offset, max)
                    surface.DrawLine(startChar, z, endChar, z)
                end
            end
        end 

        -- Tab Indicators
        if self.lexer.config.language ~= "Plain" then 
            for tabC, tab in pairs(self.allTabs) do     
                if c == tabC then 
                    for t = 2, #tab, 1 do 
                        if ((t - 1) % self.tabSize) == 0 and t >= self.textPos.char then 
                            local pos = t * self.font.w - self.textPos.char * self.font.w
                            draw.RoundedBox(0, offset + pos, tabC * self.font.h, 1, self.font.h, self.colors.tabIndicators)
                        end
                    end 
                end 
            end
        end 

        if self:HasSelection() then
             self:Highlight(self.selection.start, self.selection.dest, i, self.colors.selection) 
             if #self.highlights > 0 then 
                for _, highlight in pairs(self.highlights) do 
                    if ((self.selection.start.char == highlight.start.char or self.selection.dest.char == highlight.ending.char) 
                    or (self.selection.dest.char == highlight.start.char or self.selection.start.char == highlight.ending.char))
                    and highlight.start.line ~= i then 
                        continue 
                    end 
                    self:Highlight(highlight.start, highlight.ending, i)
                end
            end 
        else 
            if #self.highlights > 0 then 
                for _, highlight in pairs(self.highlights) do 
                    self:Highlight(highlight.start, highlight.ending, i)
                end
            end 
        end

        c = c + 1
    end

    self.lastOffset = offset 

    if self:HasSelection() == true and self.clickCounter ~= 1 then
        if not self.lastSelectionDest then 
            self.lastSelectionDest = table_Copy(self.selection.dest) 
        end

        if math.abs(self.selection.start.line - self.selection.dest.line) == 0 
            and (self.lastSelectionDest.char ~= self.selection.dest.char or self.lastSelectionDest.line ~= self.selection.dest.line) then 
            self:HighlightWords(self:GetSelectedText())
            self:RematchPairs()
        elseif math.abs(self.selection.start.line - self.selection.dest.line) ~= 0 then  
            self:ResetHighlighting()
            if self.lastSelectionDest.char ~= self.selection.dest.char or self.lastSelectionDest.line ~= self.selection.dest.line then 
                self:RematchPairs()
            end 
        end

        self.lastSelectionDest = table_Copy(self.selection.dest)
    end

    if self.hasChanges == true then 
        if self.lexAll then 
            self:RunLexer()
        else 
            self:RetimeDiffCheck()
        end
        self:UpdateTabIndicators()
        self:ParseVisibleLines()
        self:RetimeRematch()
        self.hasChanges = false 
        self:ResetHighlighting()

        self:OnTextChanged()
    elseif self.lexerDiffCheck and self.lexerDiffCheck <= SysTime() then
        self.lexerDiffCheck = nil
        if not self.lexAll then  
            self:RunLexer()
        end 
        self:RematchPairs()
    end
end

function syntaxBox:OnMouseWheeled(delta)
    self:OnScrolled(delta)

    if self.codePressed == KEY_LCONTROL then
        delta = delta * self.rescaleMult 
        self:SetFont(self.font.an, self.font.s + delta)
    else
        delta = delta * self.scrollMult 
        self.scrollBar:SetScroll(self.scrollBar:GetScroll() - delta)
    end

    if self.lexerDiffCheck then 
        self:RetimeDiffCheck()
    end 
end

function syntaxBox:_LinesChanged(a, b)
   -- print(a .. " " ..b )
end

vgui.Register("DSyntaxBox", syntaxBox, "DPanel")












local keywords = {
    ["if"]       = 1,
    ["else"]     = 1,
    ["elseif"]   = 1,
    ["while"]    = 1,
    ["for"]      = 1,
    ["foreach"]  = 1,
    ["switch"]   = 1,
    ["case"]     = 1,
    ["break"]    = 1,
    ["default"]  = 1,
    ["continue"] = 1,
    ["return"]   = 1,
    ["local"]    = 1,
    ["function"] = 1
}

local function isUpper(char)  
    if not char or char == "" then return false end 
    local n = string.byte(char)
    return n >= 65 and n <= 90 
end

local function isLower(char)  
    if not char or char == "" then return false end 
    local n = string.byte(char)
    return n >= 97 and n <= 122 
end

local function isNumber(char) 
    if not char or char == "" then return false end 
    local n = string.byte(char)
    return n >= 48 and n <= 57 
end

local function isSpecial(char)
    return isNumber(char) == false and isLower(char) == false and isUpper(char) == false 
end 

local E2Cache = {}

local E2Profile = 
{
    language = "Expression 2",
    filetype = ".txt",
    reserved = 
    {
        operators = {"+","-","/","|","<",">","=","*","?","$","!",":","&","%","~",",", "^"},
        others    = {".", ";"}
    },
    indentation = 
    {
        open = {"{", "%(", "%["},
        close = {"}", "%)", "%]"},
        offsets = {
            ["#ifdef"] = false, 
            ["#else"] = false,    
            ["#endif"] = false 
        }
    },
    autoPairing =
    {
        {
            word = "{",
            pair = "}",
            validation = function() return true end     
        },
        {
            word = "(",
            pair = ")",
            validation = function() return true end 
        },
        {
            word = "[",
            pair = "]",
            validation = function(line, charIndex, lineIndex)  
                return (line[charIndex - 1] or "") ~= "#"
            end 
        },
        {
            word = '"',
            pair = '"',
            validation = function(line, charIndex, lineIndex)  
                return (line[charIndex - 1] or "") ~= '"'
            end 
        },
        {
            word = "#[", 
            pair = "]#",
            validation = function() return true end 
        },
    },
    unreserved = 
    {
        ["_"] = 0,
        ["@"] = 0
    },
    closingPairs = 
    {
        scopes            = {"{", "}"},
        parenthesis       = {"(", ")"},
        propertyAccessors = {"[", "]"}
    },
    matches = 
    {
        preprocDirective = 
        {
            pattern = "^@[^ ]*",
            validation = function(line, buffer, result, tokenIndex, tokens, lineIndex, triggerOther)
                if result == "@persist" 
                or result == "@inputs" 
                or result == "@outputs"
                or result == "@autoupdate" then 
                    return true 
                end
                return false 
            end
        },
        preprocLine =
        {
            pattern = "^@[^\n]*",
            validation = function(line, buffer, result, tokenIndex, tokens)  
                local _, _, txt = string.find(line, "^(@[^ ]*)")
                if txt == "@name" 
                or txt == "@trigger" 
                or txt == "@model" then 
                    return true 
                end
                return false 
            end
        },
        variables = 
        {
            pattern     = "[A-Z][a-zA-Z0-9_]*",
            validation = function(line, buffer, result, tokenIndex, tokens) 
                return isSpecial(line[buffer - 1]) == true 
            end,
       --     cacheResult = true -- Save First declaration and all positions
        },
        keywords = 
        {
            pattern = "[a-z][a-zA-Z0-9_]*",
            validation = function(line, buffer, result, tokenIndex, tokens) 
                if result == "function" then 
                    local _,_,str = string_find(line, "^%s*([^ ]*)", 1)
                    if str ~= "function" then return false end 
                end
                return keywords[result] and isSpecial(line[buffer - 1]) == true
            end
        },
        userfunctions = 
        {
            pattern = "[a-z][a-zA-Z0-9_]*",
            validation = function(line, buffer, result, tokenIndex, tokens) 
                if keywords[result] then 
                    return false 
                end

                local function getPrevToken(index)
                    return tokens[tokenIndex - index] or {}
                end
                --[[
                                        function someFunction()     
                                function someType:someFunction()
                                function someType someFunction()
                    function someType someType:someFunction()
                        5    4    3   2    1   0
                ]]

                local res = false 
                if getPrevToken(1).text == "function" or getPrevToken(3).text == "function" or getPrevToken(5).text == "function" then 
                    res = true 
                end

                return res == true and line[buffer + #result] == "(" and isSpecial(line[buffer - 1]) == true 
            end,
            cacheResult = true,
            reparseOnChange = true 
        },
        builtinFunctions = 
        {
            pattern = "[a-z][a-zA-Z0-9_]*",
            validation = function(line, buffer, result, tokenIndex, tokens, lineIndex, tot) 
                if keywords[result] then 
                    return false 
                end

                for i, lineCache in pairs(E2Cache) do -- Need cache for every line so if something cached gets removed it can be updated
                    if i > lineIndex then continue end 
                    if lineCache.userfunctions and lineCache.userfunctions[result] then 
                        tot("userfunctions")
                        return true 
                    end
                end 

                local extraCheck = true 
                if E2Lib then 
                    if not wire_expression2_funclist[result] then 
                        extraCheck = false 
                    end
                end

                local function nextChar(char)
                    return line[buffer + #result] == char  
                end

                return nextChar("(") and extraCheck and isSpecial(line[buffer - 1]) == true 
            end
        },
        types = 
        {
            pattern = "[a-z][a-zA-Z0-9_]*",
            validation = function(line, buffer, result, tokenIndex, tokens, lineIndex, tOther) 
                if keywords[result] then 
                    return false 
                end

                local function nextChar(char)
                    return line[buffer + #result] == char  
                end
                
                local extraCheck = true  

                if E2Lib then 
                    local function istype(tp)
                        return wire_expression_types[tp:upper()] or tp == "number" or tp == "void"
                    end
                    extraCheck = istype(result)
                    if extraCheck == false then 
                        if wire_expression2_funclist[result] and isSpecial(line[buffer - 1]) == true then 
                            tOther("builtinFunctions")
                            return true 
                        end
                    end
                end

                return (nextChar("]") or nextChar(" ") or nextChar(":") or nextChar("=") or nextChar(",") or nextChar("") or nextChar(")")) and extraCheck and isSpecial(line[buffer - 1]) == true 
            end
        },
        includeDirective = 
        {
            pattern = "#include",
            validation = function(line, buffer, result, tokenIndex, tokens) 
                return line[buffer + #result] == " "
            end
        },
        ppcommands = 
        {
            pattern = "#[a-z]+",
            validation = function(line, buffer, result, tokenIndex, tokens) 
                local res = result == "#ifdef" 
                            or result == "#else" 
                            or result == "#endif" 

                return res 
            end
        },
        constants = 
        {
            pattern = "_[A-Z][A-Z_0-9]*",
            validation = function(line, buffer, result, tokenIndex, tokens) 
                if E2Lib then 
                    return wire_expression2_constants[result] ~= nil 
                end
                return true  
            end
        },
        lineComment = 
        {
            pattern = "#[^\n]*",
            validation = function(line, buffer, result, tokenIndex, tokens) 
                local _, _, txt = string.find(result, "(#[^ ]*)")
                if txt == "#ifdef" 
                or txt == "#include"
                or txt == "#else" 
                or txt == "#endif"
                or string.sub(txt, 1, 2) == "#[" then return false end 
                return true 
            end
        },
        decimals = 
        {
            pattern = "[0-9][0-9.e]*",
            validation = function(line, buffer, result, tokenIndex, tokens) 
                local function nextChar(char)
                    return line[buffer + #result] == char  
                end

                if nextChar("x") or nextChar("b") then return false end 

                return true 
            end
        },
        hexadecimals = 
        {
            pattern = "0[xb][0-9A-F]+"
        }
    },
    captures = 
    {
        strings = 
        {
            begin = {
                pattern = '"'
            },
            close = {
                pattern = '"',
                validation = function(line, buffer, result, tokenIndex, tokens) 
                    local stepper = 0
                    local prevChar = line[buffer - 1 - stepper] or ""

                    while prevChar == "\\" do 
                        stepper = stepper + 1
                        prevChar = line[buffer - 1 - stepper]
                    end

                    return stepper == 0 or stepper % 2 == 0   
                end
            }
        },
        comments = 
        {
            begin = {
                pattern = '#%['
            },
            close = {
                pattern = '%]#'
            }
        }
    },

    onLineParseStarted = function(i)
        E2Cache[i] = {}
    end,

    onLineParsed = function(result, i)  
    end,

    onMatched = function(result, i, type, buffer, prevTokens) 
        if type == "userfunctions" then 
            if not E2Cache[i] then E2Cache[i] = {} end 
            if not E2Cache[i][type] then E2Cache[i][type] = {} end 
            if not E2Cache[i][type][result] then E2Cache[i][type][result] = 0 end 
            E2Cache[i][type][result] = E2Cache[i][type][result] + 1
        end
    end,

    onCaptureStart = function(result, i, type, buffer, prevTokens) 
    end,

    onCaptureEnd = function(result, i, type, buffer, prevTokens) 
    end,
    
    onTokenSaved = function(result, i, type, buffer, prevTokens) 
    end,

    colors = 
    {
        preprocDirective = Color(240,240,160),
        preprocLine      = Color(240,240,160),
        operators        = Color(255,255,255),
        scopes           = Color(255,255,255),
        parenthesis      = Color(255,255,255),
        strings          = Color(150,150,150),
        comments         = Color(128,128,128),
        lineComment      = Color(128,128,128),
        variables        = Color(160,240,160),
        decimals         = Color(247,167,167),
        hexadecimals     = Color(247,167,167),
        keywords         = Color(160,240,240),
        includeDirective = Color(160,240,240),
        builtinFunctions = Color(160,160,240),  
        userfunctions    = Color(102,122,102),
        types            = Color(240,160,96),
        constants        = Color(240,160,240),
        ppcommands       = Color(240,96,240),
        error            = Color(241,96,96),
        others           = Color(241,96,96)
    }
}


------------------------
local self   	= {}
local ipairs 	= ipairs
local tostring 	= tostring
local tonumber 	= tonumber

function self:InternalId ()
	return "WireMultiAgent:ClientHandler"
end

function self:Constructor ()
	if not WireMultiAgent ["WireMultiAgent:SignalProcessor"].Identifiers then
		WireMultiAgent ["WireMultiAgent:SignalProcessor"]:Constructor ()
	end
	
	self.Packet 		= 20
	self.SessionHash 	= function ()
		math.randomseed (os.clock () ^ 5)
		
		return tostring (math.random (-9999999999, 9999999999))
	end
end
	
local function performSleepThread (tick, cid)
	local cooperativeThread = coroutine.running ()
		
	timer.Create (self:InternalId () .. "internal_" .. cid, tick, 0,
		function ()
			coroutine.resume (cooperativeThread)
		end
	)
		
	coroutine.yield ()
end

local function sendExpression2PlagiatCode (e2code, e2description, channel, allowSharing)
	local sessionHash = self.SessionHash ()
	local loadPacket = util.Compress (e2code)
		
	if not loadPacket or loadPacket == NULL or loadPacket == "" then return end
	
	local length  = string.len (loadPacket)
	local packets = self.Packet
	local parts   = math.ceil (length / packets)
	local start   = 0
	
	for i = 1, parts do
		local endbyte = math.min (start + packets, length)
		local size    = endbyte - start
		net.Start (channel)
		net.WriteBool (i == parts)
		net.WriteBool (true)
		net.WriteString (i .. ":" .. parts)
		net.WriteString (size .. ":" .. length)
		net.WriteString (allowSharing)
		net.WriteString (e2description)
		net.WriteUInt (size, 16)
		net.WriteData (loadPacket:sub (start + 1, endbyte + 1), size)
		net.SendToServer ()
		start = endbyte
		
		--performSleepThread (0.1, channel .. sessionHash) for production
		performSleepThread (0.0001, channel .. sessionHash) -- open bar on dev server
		print(i .. " / " .. parts)
		if i == parts then
			print ("Sent E2 code successfully to server.")
		end
	end
end
-- before sending ensure the text contains at least one direct = @name, @persist, @input, @output, @trigger

local defaultCode = [[@name E.A.S
@inputs 
@outputs 
@persist Players:array [GlobalThreat NpcBones NpcOffsets FallbackBones]:table
@trigger 

runOnTick(1)
local Sta = 0
Players = players()
if (first())
{
    print("hello")
}

if (owner():keyAttack1())
{
    triggerAim(owner())
}
updateTargetList()
]]

function self:SubmitPlagiatCode ()
    local frame = vgui.Create("DFrame")
	frame:SetSize(ScrW() / 2, ScrH() / 2)
	frame:SetTitle("Text Entry Menu")
	frame:Center()
	frame:MakePopup()	

	local expression2RawCode = vgui.Create("DSyntaxBox", frame)
	expression2RawCode:SetProfile(E2Profile)
	expression2RawCode:SetPos(20, 30)
	expression2RawCode:SetSize(frame:GetWide() - 40, frame:GetTall() / 1.2)
	expression2RawCode:SetText(defaultCode)
	expression2RawCode:SetFont("DejaVu Sans Mono", 16)

	local expression2Description = vgui.Create("DTextEntry", frame)
	expression2Description:SetPos(20, frame:GetTall() / 1.13) 
	expression2Description:SetSize(frame:GetWide() - 40, 30)
	expression2Description:SetPlaceholderText("Short description of the e2, up to 255 characters")

	local allowSharingCheckbox = vgui.Create("DCheckBoxLabel", frame)
	allowSharingCheckbox:SetText("Allow Sharing with Public")
	allowSharingCheckbox:SetPos(20, frame:GetTall() - 60)
	allowSharingCheckbox:SetValue(0) 
	allowSharingCheckbox:SizeToContents()

	local function limitTextLength(entry, maxLength)
		local text = entry:GetValue()
		if #text > maxLength then
			entry:SetText(text:sub(1, maxLength))
		end
	end

	expression2Description.OnTextChanged = function()
		limitTextLength(expression2Description, 255)
	end

	local submitButton = vgui.Create("DButton", frame)
	submitButton:SetPos(20, frame:GetTall() - 40)
	submitButton:SetSize(frame:GetWide() - 40, 30)
	submitButton:SetText("Submit")

	submitButton.DoClick = function()
		local expression2CodeGen = expression2RawCode:GetText()
		local expression2Desc = expression2Description:GetValue()
		local allowSharing = allowSharingCheckbox:GetChecked() and 1 or 0
		
		defaultCode = expression2CodeGen
		--print("Multiline code:\n" .. expression2CodeGen)
		--print("Singleline code:\n" .. expression2Desc)
		--print("Allow Sharing: " .. allowSharing)
		local err, includes
		if (E2Lib and E2Lib.Validate) then
				print("Found E2Lib")
				err, includes = E2Lib.Validate (expression2CodeGen)
			else
				print("Switching to old compatibility")
				err, includes = wire_expression2_validate(expression2CodeGen)
			end
			
			if err then
				error (err)
			end
			
			if includes then
				print("newinclude  : ")
				local newincludes = {}
				for k, v in pairs(includes) do
					newincludes[k] = v
				end
				
				PrintTable(newincludes)
			end
		frame:Close()

		coroutine.wrap(sendExpression2PlagiatCode)(expression2CodeGen, expression2Desc, WireMultiAgent["WireMultiAgent:SignalProcessor"].Identifiers.Carriage, tostring (allowSharing))
	end

	
	PrintTable(WireMultiAgent ["WireMultiAgent:SignalProcessor"])
end

concommand.Add("wire_submit", self.SubmitPlagiatCode)


WireMultiAgent.MakeGateAway (self, WireMultiAgent, self:InternalId ())
