#!/bin/lua5.1

local args = {...}

package.path = package.path .. ";../src/?.lua"

local pleal = require("pleal")
pleal.setLogFunctions(print, print, print)
--local pleal = loadfile("../src/pleal.lua")()

local suc, conf, luaCode

if args[1] ~= "1" then
    suc, conf, luaCode = pleal.parseFile("input.pleal")
else
    suc, conf, luaCode = pleal.parseFile("input-final.pleal")
end

if not suc then
    print("ERROR: " .. tostring(conf))
    os.exit(1)
end

print("--===== lua code =====--\n" .. luaCode)

if args[1] == "1" then
    print("--===== loaded function =====--")
    print(loadstring(luaCode))
    print("--===== exec =====--")
    print(loadstring(luaCode)())
end