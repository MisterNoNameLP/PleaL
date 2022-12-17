local test = "TEST"
local index = "tbl"
local tbl = {
    t = "TBL TEST",
    tbl = {t = "TBL IN TBL"},
    TEST = "TEST_TEST"
}

print("### PTEST ###")

print("test value: $test")
print("test tbl: $tbl.t")

print("test tbl: $tbl['t']") 

print("test tbl: $tbl[test] ") 

print("test tbl: $tbl['$index'][t] ") 

