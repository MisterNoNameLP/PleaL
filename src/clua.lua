--[[
    clua (custom lua) is a custom version of lua. implementing features like += and such. 
    clua works by comverting clua code unto native lua code. Wich means clua runs on ordenary lua interpreters.

    Requirements: 
        Interpreter: lua5.1+.


    clua Copyright (c) 2022 MisterNoNameLP

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local version = "v0.2"

local clua = {
	maxInsertingDeepth = 10000,
}

--===== internal variables =====--
local log = print

local replacePrefixBlacklist = "%\"'[]"
local allowedVarNameSymbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_." --string pattern

--===== internal functions =====--
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


--===== main functiosn =====--
local function getVersion()
	return version
end

local function parse(input)
	local lineCount = 0	
	local _, conf
	local output = ""
	local replacePrefix

	--=== load conf line ===--
	do 
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
					return false, "Invalid file conf line!"
				end
				_, conf = pcall(confInterpreterFunc)
				input = input:sub(len(line) + 1) --cut out conf line
			end
			break
		end
	end
	if type(conf) ~= "table" then
		conf = {}
	end
	
	--=== error checks ===--
	replacePrefix = pa(conf.replacePrefix, "$")
	if type(replacePrefix) ~= "string" then
		return false, "Invalid replacePrefix."
	end
	if len(replacePrefix) > 1 then
		return false, "replacePrefix is too long. Only a 1 char long prefix is allowed."
	end
	for c = 0, len(replacePrefixBlacklist) do
		local blacklistedSymbol = replacePrefixBlacklist:sub(c, c)
		if replacePrefix == blacklistedSymbol then
			return false, "replacePrefix (" .. replacePrefix .. ") is not allowed"
		end
	end

	--=== parse script ===--
	local function cut(pos)
		output = output .. input:sub(0, pos)
		input = input:sub(pos + 1)
	end

	local function keepInserting(inserter, symbol, level, maxDeepth)
		local done 
		local deepth = 0
		while done ~= 1 and done ~= true do
			deepth = deepth + 1
			if deepth > maxDeepth then
				return false, "max inserting deepth reached at level: " .. tostring(level)
			end
			done = inserter(symbol)
		end
	end

	local function insertVariables(finisher)
		log("PARSE_LINE: " .. tostring(finisher))
		log(input)


		--look for relevant symbols
		local pos = input:find("[%[%]\"'"..replacePrefix.."]")
		local symbol
		local prevSymbol, nextSymbol
		if not pos then
			cut(len(input))
			return true
		end

		--process symbol
		symbol = input:sub(pos, pos)
		prevSymbol = input:sub(pos - 1, pos - 1)
		nextSymbol = input:sub(pos + 1, pos + 1)

		if symbol == finisher then
			log(1)

			cut(pos)

			return 1
		elseif finisher and symbol == replacePrefix then
			log(2)

			cut(pos)

			local varFinishingPos = input:find("[^" .. allowedVarNameSymbols .. "]")
			local varFinishingSymbol = input:sub(varFinishingPos, varFinishingPos)

			--log(varFinishingSymbol)

			--cut out the var name
			local varName = input:sub(0, varFinishingPos - 1)
			input = input:sub(varFinishingPos)
			--remove replacePrefix
			output = output:sub(0, -2)

			if varFinishingSymbol == "[" then
				local insertingSuc, insertingErr

				output = output .. finisher .. "..tostring(" .. varName
				
				cut(1)

				log("### 1 ###")
				log(input)
				log("#")
				log(output)

				insertingSuc, insertingErr = keepInserting(insertVariables, "]", 3, clua.maxInsertingDeepth)
				if insertingSuc == false then
					return insertingErr
				end
				
				log("### 2 ###")
				log(input)
				log("#")
				log(output)
				--log("\n")

				output = output .. ").." .. finisher
			else
				--re insert the modified varname
				--input = finisher .. "..tostring(" .. varName .. ").." .. finisher  .. input
				output = output .. finisher .. "..tostring(" .. varName .. ").." .. finisher
			end

		else
			log(3)

			cut(pos)
			if symbol == "\"" or symbol == "'" then
				return keepInserting(insertVariables, symbol, 2, clua.maxInsertingDeepth)
			elseif symbol == "[" and nextSymbol == "[" then
				--insertVariables("]")
			elseif symbol == "[" then

			end
		end
	end


	if conf.clua == false then
		return true, conf, input
	else 
		local suc, err = keepInserting(insertVariables, nil, 1, 1000)
		if suc == false then 
			return false, err
		end
	end
	return true, conf, output
end

local function parseFile(path) 
    local fileContent = readFile(path)

    if not fileContent then
        return false, "File not found"
    else
        return parse(fileContent)
    end
end

local function getLogFunction()
	return log
end
local function setLogFunction(func)
	log = func
end


--===== linking local functions to clua table =====--
clua.version = version
clua.getVersion = getVersion

clua.parse = parse
clua.parseFile = parseFile

clua.exec = exec
clua.execFile = execFile

clua.getLogFunction = getLogFunction
clua.setLogFunction = setLogFunction


return clua