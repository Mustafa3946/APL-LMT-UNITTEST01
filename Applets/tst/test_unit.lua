TestResponse    =   {}

TestResponse.arg1           =   {}
TestResponse.arg2           =   {}
TestResponse.reportNumber   =   0
TestResponse.reportCommand  =   {}

function TestResponse:testSET_EARTHQUAKE_SENSOR_STATE()
    for i = 1, TestResponse.reportNumber do
        if reportCommand[i] == "SET_EARTHQUAKE_SENSOR_STATE" then
            print("Test number  :   ", i, " Command name    :   ",  TestResponse.reportCommand[i])
            luaunit.assertEquals(TestResponse.arg1[i],TestResponse.arg2[i])
        end        
    end
end
---------------------------------------------------------------------------------------------------

function TestResponse:testSET_METER_STATUS()
    for i = 1, TestResponse.reportNumber do
        if reportCommand[i] == "SET_METER_STATUS" then
            print("Test number  :   ", i, " Command name    :   ",  TestResponse.reportCommand[i])
            luaunit.assertEquals(TestResponse.arg1[i],TestResponse.arg2[i])
        end        
    end
end
