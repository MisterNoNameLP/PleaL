

local var = "VAR"
local tbl = {test = "TEST"}

local str1 = "test &var blob"
local str2 = 'test '..tostring(var)..' blob'
local str3 = [[test ]]..tostring(var)..[[ blob]]

local str4 = "test "..tostring(tbl['test']).." blob"
--local str5 = "test "..tostring(tbl[\"test\"]).." blob" --not working

local str10 = "test "..tostring(str1).." blob"


print(str1)
print(str2)
print(str3)
print(str4)
print(str10)