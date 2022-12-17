local ut = require("UT")
local input = ut.readFile("input.lua")
local output

local utf8 = {len = function(s) return #s end}

local function warn(...)
    print(...)
end
local function err(...)
    print(...)
end
local function fatal(...)
    print(...)
end

local replacePrefixBlacklist = "%\"'[]"
local function preparse(input, replacePrefix)
    local lineCount = 0
    local _, conf
    local output = ""

    for line in input:gmatch("[^\n]+") do --load conf line
        if line:sub(0, 2) == "#?" then 
            local confLine = line:sub(3)
            local confInterpreterString = [[
                local conf = {}
                _G = setmetatable(_G, {__newindex = function(_, index, value) conf[index] = value end})
            ]] .. confLine .. [[
                return conf
            ]]
            local confInterpreterFunc = loadstring(confInterpreterString)

            if not confInterpreterFunc then
                err("Invalid file conf line!")
                return false, "Invalid file conf line!"
            end
            _, conf = pcall(confInterpreterFunc)
            input = input:sub(utf8.len(line) + 1) --cut out conf line
        end
        break
    end
    if type(conf) ~= "table" then
        conf = {}
    end

    replacePrefix = conf.replacePrefix or replacePrefix
    if replacePrefix == nil then
        replacePrefix = replacePrefix or "$"
    elseif type(replacePrefix) ~= "string" then
        fatal("Invalid replacePrefix.")
        return false, "Invalid replacePrefix."
    end
    if utf8.len(replacePrefix) > 1 then
        fatal("replacePrefix is too long. Only a 1 char long prefix is allowed.")
        return false, "replacePrefix is too long. Only a 1 char long prefix is allowed."
    end
    for c = 0, utf8.len(replacePrefixBlacklist) do
        local blacklistedSymbol = replacePrefixBlacklist:sub(c, c)
        print(blacklistedSymbol)
        if replacePrefix == blacklistedSymbol then
            fatal("replacePrefix (" .. replacePrefix .. ") is not allowed")
            return false, "replacePrefix (" .. replacePrefix .. ") is not allowed"
        end
    end

    if conf.preparse == false then
        return true, conf, input
    else
        local status
        while true do
            local pos = input:find("[%[%]\"'"..replacePrefix.."]")
            local symbol

            if not pos then
                break
            end

            symbol = input:sub(pos, pos)
            if not status then
                if symbol == "\"" or symbol == "'" then
                    status = symbol
                elseif symbol == "[" and input:sub(pos + 1, pos + 1) == "[" and input:sub(pos - 1, pos - 1) ~= "-" then
                    status = "]"
                end
            elseif status == symbol then
                if 
                    symbol == "\"" and input:sub(pos - 1, pos - 1) ~= "\\" or
                    symbol == "'" and input:sub(pos - 1, pos - 1) ~= "\\" or
                    symbol == "]" and input:sub(pos + 1, pos + 1) == "]"
                then
                    status = nil
                end
            elseif symbol == replacePrefix then
                local tmpInput = input:sub(pos + 1)
                local spacePos = tmpInput:find("%s")
                local varName = tmpInput:sub(0, spacePos - 1)
                local insertion = "tostring(" .. varName ..")"

                if status == "\"" then
                    insertion = "\".." .. insertion .. "..\""
                elseif status == "'" then
                    insertion = "'.." .. insertion .. "..'"
                elseif status == "]" then
                    insertion = "]].." .. insertion .. "..[["
                end

                output = output .. input:sub(0, pos - 1)
                input = insertion .. input:sub(pos + utf8.len(varName) + 1)
                pos = utf8.len(insertion)
            end

            do --input cutting
                output = output .. input:sub(0, pos)
                input = input:sub(pos + 1)
            end
        end
        output = output .. input
    end
    return true, conf, output
end

local suc, conf, output = preparse(input)
print("OUTPUT:\n" .. tostring(output) or "NEIN!")

do --save to file
    local file = io.open("output.lua", "w")
    file:write(output)
    file:close()
end

--os.execute("echo '" .. tostring(output) .. "' > output.lua")