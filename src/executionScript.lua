--[[
    This script makes it possible to easly axecute PleaL script from the command line.
    It is supposed to be shippen within an all-in-one script wich is createt automatically. But it can be executet in its pure form as well.
    For more information see the official PleaL readme.
    
    https://github.com/MisterNoNameLP/PleaL#building
]]

package.path = package.path .. ";src/?.lua;src/thirdParty/?.lua"

local ut = require("UT")
local pleal = require("plealTranspilerAPI")
local argparse = require("argparse")

print("This script is not finished yet.")
os.exit(0)