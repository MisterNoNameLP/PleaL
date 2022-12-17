local test = "TEST"
local tbl = {
    t = "TBL TEST",
    tbl = {t = "TBL IN TBL"},
    TEST = "TEST_TEST"
}

print("### PTEST ###")

print("test value: $test")
print("test tbl: $tbl.t")

print("test tbl: $tbl['t']") --not working

print("test tbl: $tbl[$test] ") --not working

