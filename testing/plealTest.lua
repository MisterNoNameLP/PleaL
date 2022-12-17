local args = {...}

package.path = package.path .. ";../src/?.lua"

local clua = require("pleal")
--local clua = loadfile("../src/clua.lua")()

local suc, conf, luaCode = clua.parseFile("input.pleal")

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