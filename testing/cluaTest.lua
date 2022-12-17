package.path = package.path .. ";../src/?.lua"

local clua = require("clua")
--local clua = loadfile("../src/clua.lua")()

local suc, conf, luaCode = clua.parseFile("input.lua")

print("--===== lua code =====--\n" .. luaCode)



