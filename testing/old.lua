local status
while true do
	local pos = input:find("[%[%]\"'"..replacePrefix.."]")
	local symbo
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
		local insertion = "tostring(" .. varName ..")
		if status == "\"" then
			insertion = "\".." .. insertion .. "..\""
		elseif status == "'" then
			insertion = "'.." .. insertion .. "..'"
		elseif status == "]" then
			insertion = "]].." .. insertion .. "..[["
        end
		output = output .. input:sub(0, pos - 1)
		input = insertion .. input:sub(pos + len(varName) + 1)
		pos = len(insertion)
    end
	do --input cutting
		output = output .. input:sub(0, pos)
		input = input:sub(pos + 1)
	end
end
output = output .. input