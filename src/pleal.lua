--[[
    pleal (PleasantLua) is a custom version of lua. Implementing features like a more convinient way of embetting variables into strings as well as things like +=. 
    pleal works by comverting pleal code unto native lua code. Wich means that pleal runs on ordinary lua interpreters.

    Requirements: 
        Interpreter: lua5.1+.


    pleal Copyright (c) 2022 MisterNoNameLP

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local version = "0.5"

local pleal = {}

--===== internal variables =====--
local log = print
local err = log
local dlog = function() end

local globalConfig = {
	replacementPrefix = "$",
	removeConfLine = false,
}


local replacePrefixBlacklist = "%\"'[]"
local allowedVarNameSymbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_." --string pattern

--===== internal functions =====--
--=== basic functions ===--
function readFile(path)
	local file, err = io.open(path, "rb")
	
	if file == nil then 
		return nil, err 
	else
		local fileContent = file:read("*all")
		file:close()
		return fileContent
	end
end
function pa(...) --returns the first non nil parameter.
	for _, a in pairs({...}) do
		if a ~= nil then
			return a
		end
	end
end
function len(string) --may gets replaces with utf8 support if needed.
    if type(string) == "string" then
        return #string
    else
        return 0
    end
end
local function keepCalling(func, maxTries, ...) --Call the given function until it returns true or 1.
	local done 
	local tries = 0
	if not maxTries then
		maxTries = math.huge
	end
	while done ~= 1 and done ~= true do
		tries = tries + 1
		if tries > maxTries then
			err("keepCalling failed: Max tries reached")
			return false, "max calling tries reached"
		end
		done = func(...)
	end
end

--=== conversion functions ===--
local function loadConf(input) --removes the conf line from the input and return it.
	local conf = {}
	local _, scriptConf
	for i, c in pairs(globalConfig) do
		conf[i] = c
	end
	for line in input:gmatch("[^\n]+") do
		if line:sub(0, 2) == "#?" then 
			local confLine = line:sub(3)
			local confInterpreterString = [[
				local conf = {}
				local globalMetatable = getmetatable(_G)
				_G = setmetatable(_G, {__newindex = function(_, index, value) conf[index] = value end})
			]] .. confLine .. [[
				_G = setmetatable(_G, globalMetatable)
				return conf
			]]
			local confInterpreterFunc = loadstring(confInterpreterString)
			if not confInterpreterFunc then
				return false, "Invalid file conf line"
			end
			_, scriptConf = pcall(confInterpreterFunc)
			--input = input:sub(len(line) + 1) --cut out conf line
		end
		break
	end
	if type(scriptConf) ~= "table" then
		return conf
	else
		for i, c in pairs(scriptConf) do
			conf[i] = c
		end
	end
	return conf
end
local function embedVariables(input)
	local output = ""

	local function cut(pos)
		output = output .. input:sub(0, pos)
		input = input:sub(pos + 1)
	end

	local function embed(finisher)
		local symbolPos
		local symbol
		local prevSymbol, nextSymbol
		local opener

		--preparing opener to handle [[]] strings
		if finisher == "]]" then
			opener = "[["
		else
			opener = finisher
		end
	
		--getting for relevant symbols
		local function setSymbol()
			symbolPos = input:find("[%[%]\"'"..replacePrefix.."]")
			if not symbolPos then
				cut(len(input))
				return true
			end
			symbol = input:sub(symbolPos, symbolPos)
			prevSymbol = input:sub(symbolPos - 1, symbolPos - 1)
			nextSymbol = input:sub(symbolPos + 1, symbolPos + 1)
		end
		if setSymbol() then
			return true
		end

		--error prevention 

		--process symbol
		if symbol == finisher then
			cut(symbolPos)
			if prevSymbol ~= "\\" then
				return 1
			end
		elseif finisher and symbol == replacePrefix and finisher ~= "]" then
			if prevSymbol == "\\" then
				input = input:sub(2)
				cut(symbolPos - 1)
				return 
			end

			cut(symbolPos)

			local varFinishingPos = input:find("[^" .. allowedVarNameSymbols .. "]")
			local varFinishingSymbol = input:sub(varFinishingPos, varFinishingPos)

			--cut out the var name
			local varName = input:sub(0, varFinishingPos - 1)
			input = input:sub(varFinishingPos)
			--remove replacePrefix
			output = output:sub(0, -2)

			if varFinishingSymbol == "[" then
				local insertingSuc, insertingErr
				local anotherIndex = true

				output = output .. finisher .. "..tostring(" .. varName
				cut(1)
				while anotherIndex do
					insertingSuc, insertingErr = keepCalling(embed, nil, "]")
					if insertingSuc == false then
						return insertingErr
					elseif setSymbol() then
						return true
					end
					if symbol ~= "[" then
						anotherIndex = false
					end
				end
				output = output .. ").." .. opener
			else
				output = output .. finisher .. "..tostring(" .. varName .. ").." .. opener
			end

		else
			cut(symbolPos)
			if (symbol == "\"" or symbol == "'") and (not finisher or finisher == "]" or finisher == "]]") then
			--if symbol == "\"" or symbol == "'" then
				return keepCalling(embed, nil, symbol)
			elseif symbol == "[" and nextSymbol == "[" and not finisher then
				return keepCalling(embed, nil, "]]")
			elseif symbol == "[" then

			end
		end
	end

	local suc, err = keepCalling(embed, nil)
	if suc == false then 
		return false, err
	end

	return true, output
end


--===== main functiosn =====--
--=== basic functions ===--
local function getVersion()
	return version
end
local function getLogFunctions()
	return log, err, dlog
end
local function setLogFunctions(newLog, newErr, newDlog)
	assert(type(log) == "function", "Tried to set an invalid log function")
	log = newLog
	err = pa(err, log)
	if newDlog then
		dlog = newDlog
	end
end
local function getConfig()
	return globalConfig
end
local function setConfig(conf)
	for i, c in pairs(conf) do
		globalConfig[i] = c
	end
end

--=== conversion functions ===--
local function parse(input)
	local lineCount = 0	
	local _, conf

	--load conf line
	do
		local err
		log("Load conf line")
		conf, err = loadConf(input)
		if not conf then
			err("Could conf line")
			return false, "Could not load conf line", err
		end
	end

	--process conf 
	if conf.removeConfLine then
		log("Remove conf line")
		local confLineEnd = input:find("\n")
		input = input:sub(confLineEnd)
	end
	
	--error checks
	replacePrefix = pa(conf.replacePrefix, "$")
	if type(replacePrefix) ~= "string" then
		err("Invalid replacePrefix")
		return false, "Invalid replacePrefix."
	end
	if len(replacePrefix) > 1 then
		err("replacePrefix is too long. Only a 1 char long prefix is allowed")
		return false, "replacePrefix is too long. Only a 1 char long prefix is allowed."
	end
	for c = 0, len(replacePrefixBlacklist) do
		local blacklistedSymbol = replacePrefixBlacklist:sub(c, c)
		if replacePrefix == blacklistedSymbol then
			err("replacePrefix (" .. replacePrefix .. ") is not allowed")
			return false, "replacePrefix (" .. replacePrefix .. ") is not allowed"
		end
	end

	--embed variables
	if conf.variableEmbedding ~= false then
		local suc 
		log("Embed variables")
		--embed variables
		suc, input = embedVariables(input)
		if not suc then
			err("Variable embedding failed")
			return false, "Variable embedding failed", input
		end
	else
		log("Variable embedding disabled per conf line")
	end


	--finishing up
	log("Finishing up")

	return true, conf, input
end
local function parseFile(path) 
    local fileContent = readFile(path)

    if not fileContent then
		err("Tried to parse non existing file")
        return false, "File not found"
    else
		log("Parse: " .. path)
        return parse(fileContent)
    end
end


--===== linking main functions to pleal table =====--
pleal.version = version
pleal.getVersion = getVersion

pleal.getConfig = getConfig
pleal.setConfig = setConfig

pleal.parse = parse
pleal.parseFile = parseFile

pleal.exec = exec
pleal.execFile = execFile

pleal.getLogFunctions = getLogFunctions
pleal.setLogFunctions = setLogFunctions


return pleal