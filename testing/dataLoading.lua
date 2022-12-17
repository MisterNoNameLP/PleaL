local _M, shared = ...
local _I = _M._I

local utf8 = require("utf8")

local DL = {}
local pa = _I.ut.parseArgs

local defaultFileCode = [[local _M, shared = ...;]]
local replacePrefixBlacklist = "%\"'[]"

--===== lib functions =====--
local function preparse(input, replacePrefix, logFuncs)
	local lineCount = 0	
	local _, conf
	local output = ""

	if _I.devConf.preParsing.loadConfLine then
		debug.lowDataLoadingLog("Load conf line")
		for line in input:gmatch("[^\n]+") do --load conf line
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
					--err("Invalid file conf line!")
					return false, "Invalid file conf line!"
				end
				_, conf = pcall(confInterpreterFunc)
				input = input:sub(utf8.len(line) + 1) --cut out conf line
			end
			break
		end
	end
	if type(conf) ~= "table" then
		conf = {}
	end
	
	replacePrefix = pa(replacePrefix, conf.replacePrefix, _I.devConf.preParsing.replacePrefix, "$")
	if type(replacePrefix) ~= "string" then
		--error("Invalid replacePrefix.")
		return false, "Invalid replacePrefix."
	end
	if utf8.len(replacePrefix) > 1 then
		--error("replacePrefix is too long. Only a 1 char long prefix is allowed.")
		return false, "replacePrefix is too long. Only a 1 char long prefix is allowed."
	end
	for c = 0, utf8.len(replacePrefixBlacklist) do
		local blacklistedSymbol = replacePrefixBlacklist:sub(c, c)
		if replacePrefix == blacklistedSymbol then
			--error("replacePrefix (" .. replacePrefix .. ") is not allowed")
			return false, "replacePrefix (" .. replacePrefix .. ") is not allowed"
		end
	end

	if pa(conf.preparse, _I.devConf.preParsing.preparseScripts) == false then
		return true, conf, input
	else
		debug.lowDataLoadingLog("Preparse script")
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
				--local varNameEndPattern = string.gsub("%s\"']", status, "")
				
				local tmpInput = input:sub(pos + 1)
				local spacePos = tmpInput:find("[%s\"'%]]")
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

local function loadDir(target, dir, logFuncs, overwrite, subDirs, structured, priorityOrder, loadFunc, executeFiles)
	local path = dir .. "/" --= _I.shell.getWorkingDirectory() .. "/" .. dir .. "/"
	logFuncs = logFuncs or {}
	--local print = logFuncs.log or dlog
	local print = logFuncs.log or debug.dataLoadingLog
	--local warn = logFuncs.warn or warn
	local warn = logFuncs.warn or err
	local onError = logFuncs.error or err
	local loadedFiles = 0
	local failedFiles = 0
	
	subDirs = _I.ut.parseArgs(subDirs, true)
	
	for file in _I.fs.dir(path) do
		local p, name, ending = _I.ut.seperatePath(path .. file)		
		if file ~= "." and file ~= ".." and name ~= "gitignore" and name ~= "gitkeep" then
			if _I.fs.attributes(path .. file).mode == "directory" and subDirs then
				if structured then
					if target[string.sub(file, 0, #file)] == nil or overwrite then
						target[string.sub(file, 0, #file)] = {}
						local s, f = loadDir(target[string.sub(file, 0, #file)], dir .. "/" .. file, logFuncs, overwrite, subDirs, structured, priorityOrder, loadFunc, executeFiles)
						loadedFiles = loadedFiles + s
						failedFiles = failedFiles + f
					else
						onError("[DLF]: Target already existing!: " .. file .. " :" .. tostring(target))
					end
				else
					local s, f = loadDir(target, path .. file, logFuncs, overwrite, subDirs, structured, priorityOrder, loadFunc, executeFiles)
					loadedFiles = loadedFiles + s
					failedFiles = failedFiles + f
				end
			elseif target[name] == nil or overwrite then
				local debugString = ""
				if target[name] == nil then
					debugString = "Loading file: " .. dir .. "/" .. file .. ": "
				else
					debugString = "Reloading file: " .. dir .. "/" .. file .. ": "
				end
				
				local suc, err 
				if loadFunc ~= nil then
					suc, err = loadFunc(path .. file)
				else
					--suc, err = loadfile(path .. file)
					--local filePath = "core/" .. path .. file
					local filePath = path .. file
					local fileCode, fileErr = _I.ut.readFile(filePath)
					local tracebackPathNote = filePath
					--print(path .. file)
					if fileCode == nil then
						suc, err = nil, fileErr
					else
						local cutPoint
						cutPoint = select(2, string.find(tracebackPathNote, "/env/"))
						if not cutPoint then
							cutPoint = select(2, string.find(tracebackPathNote, "/api/"))
						end
						if cutPoint then
							tracebackPathNote = string.sub(tracebackPathNote, cutPoint + 1)
						end

						do 	
							local preparseSuc, conf, newFileCode = preparse(fileCode)
							if not preparseSuc then
								suc = false
								err = conf
							else
								fileCode = newFileCode
							end
						end
						suc, err = loadstring("--[[" .. tracebackPathNote .. "]] " .. defaultFileCode .. fileCode)
					end
				end
				
				if priorityOrder then
					local order = 50
					for fileOrder in string.gmatch(name, "([^_]+)") do
						order = tonumber(fileOrder)
						break
					end
					if order == nil then
						order = 50
					end
					if target[order] == nil then
						target[order] = {}
					end
					target[order][name] = suc
				else
					target[name] = suc
					if executeFiles then
						if type(suc) == "function" then
							local suc, returnValue = xpcall(suc, debug.traceback, _M, shared)
							if suc == false then
								warn("Failed to execute: " .. name)
								warn(returnValue)
							else
								target[name] = returnValue
							end
						end
					end
				end
				
				if suc == nil then 
					failedFiles = failedFiles +1
					warn("Failed to load file: " .. dir .. "/" .. file .. ": " .. tostring(err))
				else
					loadedFiles = loadedFiles +1
					debug.lowDataLoadingLog(debugString .. tostring(suc))
				end
			end
		end
	end
	return loadedFiles, failedFiles
end

local function load(args)
	local target = pa(args.t, args.target, {})
	local dir = pa(args.d, args.dir)
	local name = pa(args.n, args.name, args.dir)
	local structured = pa(args.s, args.structured)
	local priorityOrder = pa(args.po, args.priorityOrder)
	local overwrite = pa(args.o, args.overwrite)
	local loadFunc = pa(args.lf, args.loadFunc)
	local executeFiles = pa(args.e, args.execute, args.executeFiles, args.executeDir)
	
	local loadedFiles, failedFiles = 0, 0
	
	debug.dataLoadingLog("Loading dir: " .. dir .. " (" .. name .. ")")
	loadedFiles, failedFiles = loadDir(target, dir, nil, overwrite, nil, structured, priorityOrder, loadFunc, executeFiles)
	debug.dataLoadingLog("Successfully loaded files: " .. tostring(loadedFiles) .. " (" .. name .. ")")
	if failedFiles > 0 then
		warn("Failed to load " .. tostring(failedFiles) .. " (" .. name .. ")")
	end
	debug.dataLoadingLog("Loading dir done: " .. dir .. " (" .. name .. ")")
	return target
end

local function execute(t, dir, name, callback, callbackArgs)
	local executedFiles, failedFiles = 0, 0
	
	debug.dataExecutionLog("Execute: " .. dir .. " (" .. name .. ")")
	
	for order = 0, 100 do
		local scripts = t[order]
		if scripts ~= nil then
			for name, func in pairs(scripts) do
				debug.lowDataExecutionLog("Execute: " .. name .. " (" .. tostring(func) .. ")")
				local suc, err = xpcall(func, debug.traceback, _M, shared)
				
				if suc == false then
					warn("Failed to execute: " .. name)
					warn(err)
					failedFiles = failedFiles +1
				else
					if callback ~= nil then 
						callback(err, name, callbackArgs)
					end
					executedFiles = executedFiles +1
				end
			end
		end
	end
	
	return executedFiles, failedFiles
end

local function loadDir_Disabled(dir, target, name) --is this used or even done? edit1: what the frick is that and why? renamed it to loadDir_Disabled
	name = name or ""
	debug.dataLoadingLog("Prepare loadDir execution: " .. name .. " (" .. dir .. ")")
	local scripts = load({
		target = {}, 
		dir = dir, 
		name = name, 
		priorityOrder = true,
		structured = true,
	})
	print("################################")
	print(_I.ut.tostring(scripts))
	
	local function sortIn(value, orgName, args)
		local index = args.index
		local name = orgName
		local order = string.gmatch(name, "([^_]+)")()
		local target = args.target
		
		if tonumber(order) ~= nil then
			name = string.sub(name, #order +2)
		end
		
		--print("F", orgName, name, index, value, args)
		
		
		target[name] = value
	end
	
	execute(scripts, dir, name, sortIn, {target = target})
	
	local function iterate(toIterate)
		if type(toIterate) ~= "table" then return end
		
		for i, t in pairs(toIterate) do
			print(i, type(tonumber(i)))
			if tonumber(i) == nil and type(t) == "table" then
				print(i, t)
				
				if toIterate[i] == nil then
					toIterate[i] = {}
				end
				
				execute(t, dir, name, sortIn, {target = t})
			end
			iterate(t)
		end
	end
	iterate(scripts)
	
	print(_I.ut.tostring(target))
end

local function executeDir(dir, name)
	name = name or ""
	debug.dataExecutionLog("Prepare executeDir execution: " .. name .. " (" .. dir .. ")")
	local scripts = load({
		target = {}, 
		dir = dir, 
		name = name, 
		priorityOrder = true,
	})
	
	local executedFiles, failedFiles = execute(scripts, dir, name)

	debug.dataExecutionLog("Successfully executed: " .. tostring(executedFiles) .. " files (" .. name .. ")")
	if failedFiles > 0 then
		warn("Failed to executed: " .. tostring(failedFiles) .. " (" .. name .. ")")
	end
	debug.dataExecutionLog("Executing done: " .. name .. " (" .. dir .. ")")
end

local function setEnv(newEnv, newShared)
	_M = newEnv
	shared = newShared
end

--===== set functions =====--
--DL.loadData = loadData
DL.preparse = preparse
DL.load = load
DL.loadDir = loadDir
DL.executeDir = executeDir
DL.setEnv = setEnv

return DL