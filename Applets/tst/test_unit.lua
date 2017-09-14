
local luaunit   = require("tst.luaunit")

TestResponse    =   {}

TestResponse.new                =   function ()
    TestResponse.arg1           =   {}
    TestResponse.arg2           =   {}
    TestResponse.reportNumber   =   0
    TestResponse.reportCommand  =   {}
end


function TestResponse:test_SET_EARTHQUAKE_SENSOR_STATE()
    for i = 1, TestResponse.reportNumber do
        if TestResponse.reportCommand[i] == "SET_EARTHQUAKE_SENSOR_STATE" then
            print("Test number  :   ", i, " Command name    :   ",  TestResponse.reportCommand[i])
            luaunit.assertEquals(TestResponse.arg1[i],TestResponse.arg2[i])
        end        
    end
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_METER_STATUS()
    for i = 1, TestResponse.reportNumber do
        if TestResponse.reportCommand[i] == "SET_METER_STATUS" then
            print("Test number  :   ", i, " Command name    :   ",  TestResponse.reportCommand[i])
            luaunit.assertEquals(TestResponse.arg1[i],TestResponse.arg2[i])
        end        
    end
end

function TestResponse:test_GET_METER_GAS_VALVE_STATE()
    for i = 1, TestResponse.reportNumber do
        if TestResponse.reportCommand[i] == "GET_METER_GAS_VALVE_STATE" then
            print("Test number  :   ", i, " Command name    :   ",  TestResponse.reportCommand[i])
            luaunit.assertEquals(TestResponse.arg1[i],TestResponse.arg2[i])
        end        
    end
end

function TestResponse:test_GET_METER_SUMMATION_DELIVERED()
    for i = 1, TestResponse.reportNumber do
        if TestResponse.reportCommand[i] == "GET_METER_SUMMATION_DELIVERED" then
            print("Test number  :   ", i, " Command name    :   ",  TestResponse.reportCommand[i])
            luaunit.assertEquals(TestResponse.arg1[i],TestResponse.arg2[i])
        end        
    end
end


function TestResponse:test_GET_OFLOW_DETECT_DURATION()
    for i = 1, TestResponse.reportNumber do
        if TestResponse.reportCommand[i] == "GET_OFLOW_DETECT_DURATION" then
            print("Test number  :   ", i, " Command name    :   ",  TestResponse.reportCommand[i])
            luaunit.assertEquals(TestResponse.arg1[i],"1")
        end        
    end
end

return TestResponse