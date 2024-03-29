--[[
	This script makes it possible to easly axecute PleaL script from the command line.
	It is supposed to be shippen within an all-in-one script wich is createt automatically. But it can be executet in its pure form as well.

	Requirements: 
		Interpreter: lua5.2+ or LuaJIT


	Copyright (C) 2023  MisterNoNameLP

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local version = "0.3.2"
local isDev = true

--===== local vars =====--
if isDev then
	package.path = package.path .. ";src/?.lua;src/thirdParty/?.lua"
end
_G.package.ppath = string.gsub(package.path, "%.lua", ".pleal") --pleal path
local ut = require("UT")
local pleal = require("plealTranspilerAPI")
local argparse = require("argparse")

local args
local org = {} --stores original buildin functions
local loadFunction, searchersTable, unpackFunction
local scriptArgs = {}
	
--===== arg parsing =====--
do
	local parser = argparse("PleaL", "A custom lua language")
	local runnerArgs = {}
	local runnerArgsCollected = false

	parser:flag("-v --version", "Shows the ltrs version and exit."):action(function() 
		print("PleaL runner: v" .. version)
		print("PleaL transpiler: v" .. pleal.getVersion())
		os.exit(0)
	end)
	 parser:flag("-D --dump", "Dumps every transpiled script to the console."):target("dump")
	 parser:flag("-L --no-dump-line-indicators", "Do not add line indicators to dumped scripts."):target("noDumpLineIndicators")

	parser:argument("script", "A PleaL scrip to execute"):target("script")
	 
	--sort out script args
	for _, arg in ipairs({...}) do
		if runnerArgsCollected then
			table.insert(scriptArgs, arg)
		else
			table.insert(runnerArgs, arg)
			table.remove(_G.arg, 1)
		end
		if not arg:find("-") then
			runnerArgsCollected = true
		end
	end
	args = parser:parse(runnerArgs)
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
	dlog = print,
	warn = function(...)
		print("[PleaL transpiling warn]: ", ...)
	end,
	err = function(...)
		print("[PleaL transpiling error]: ", ...)
		os.exit(1)
	end,
})

do --setting pleal conf
	local confTable = {}
	if args.dump then
		confTable.dumpScripts = true
	end
	if args.noDumpLineIndicators == nil then
		confTable.dumpLineIndicators = true --false by default
	end
	pleal.setConfig(confTable)
end

--=== replace / extend buildin functions ===--
_G.loadfile = function(path)
	local _, _, ending = ut.seperatePath(path)
	if ending ~= ".pleal" then
		return org.loadfile(path)
	else
		return loadFunction(select(3, pleal.transpileFile(path)))
	end
end
_G.dofile = function(path)
	local _, _, ending = ut.seperatePath(path)
	if ending ~= ".pleal" then
		return org.loadfile(path)
	else
		return loadFunction(select(3, pleal.transpileFile(path)))()
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

pleal.executeFile(args.script, unpackFunction(scriptArgs))
