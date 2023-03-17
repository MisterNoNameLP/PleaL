--[[
    This script makes it possible to easly axecute PleaL script from the command line.
    It is supposed to be shippen within an all-in-one script wich is createt automatically. But it can be executet in its pure form as well.
    For more information see the official PleaL readme.

    https://github.com/MisterNoNameLP/PleaL#building
]]
local version = "0.1.3"

--===== local vars =====--
--package.path = package.path .. ";src/?.lua;src/thirdParty/?.lua"
_G.package.ppath = string.gsub(package.path, "%.lua", ".pleal") --pleal path
local ut = require("UT")
local pleal = require("plealTranspilerAPI")
local argparse = require("argparse")

local args
local org = {} --stores original buildin functions
local loadFunction, searchersTable, unpackFunction

--===== arg parsing =====--
do
    local parser = argparse("PleaL", "A custom lua language")

    parser:flag("-v --version", "Shows the ltrs version and exit."):action(function() 
        print("PleaL runner: v" .. version)
        print("PleaL transpiler: v" .. pleal.getVersion())
        os.exit(0)
    end)

    parser:argument("script", "A PleaL scrip to execute"):target("script")

    args = parser:parse()
end

--===== init =====--
org.require = require
org.loadfile = loadfile
org.dofile = dofile

--backward compatibility
if loadstring then
    loadFunction = loadstring
else
    loadFunction = load
end
if package.loaders then
    searchersTable = package.loaders
else
    searchersTable = package.searchers
end
if unpack then
    unpackFunction = unpack
else
    unpackFunction = table.unpack
end

pleal.setLogFunctions({
    log = function() end, --disableing transpiler logs.
    --log = print, --debug
    err = function(...)
        print(...)
        os.exit(1)
    end,
})

--=== replace / extend buildin functions ===--
_G.loadfile = function(path)
    local _, _, ending = ut.seperatePath(path)
    if ending ~= ".pleal" then
        return org.loadfile(path)
    else
        return loadFunction(select(3, pleal.transpileFile(path)))
    end
end

table.insert(searchersTable, function(module)
    local foundFile = package.searchpath(module, _G.package.ppath)
    if foundFile then
        return function()
            local returnValues = {pleal.executeFile(foundFile)}
            table.remove(returnValues, 1)
            return unpackFunction(returnValues)
        end, foundFile
    end
end)
--===== execute PleaL script =====--
pleal.executeFile(args.script, ...)
