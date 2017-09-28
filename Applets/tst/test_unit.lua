
local luaunit   = require("tst.luaunit")
local def       = require("src.defines")

TestResponse    =   {}

TestResponse.new                =   function ()
    TestResponse.rsp            =   {}
    TestResponse.reportNumber   =   0
    TestResponse.reportCommand  =   {}
end
---------------------------------------------------------------------------------------------------
function TestResponse:common_responses(msgname)
    luaunit.assertEquals(TestResponse.rsp[msgname].error_details,  "MP_STATUS_SUCCESS")
    luaunit.assertEquals(TestResponse.rsp[msgname].result_code,0)
    luaunit.assertIsNumber(TestResponse.rsp[msgname].cid)
    luaunit.assertIsNumber(TestResponse.rsp[msgname].flags)

end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_METER_SUMMATION_DELIVERED()
    local msgname   =   "GET_METER_SUMMATION_DELIVERED"
    TestResponse:common_responses(msgname)
    luaunit.assertIsNumber(TestResponse.rsp[msgname].summation_delivered)
    luaunit.assertIsNumber(TestResponse.rsp[msgname].timestamp)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_SET_EARTHQUAKE_SENSOR_STATE()
    local msgname   =   "SET_EARTHQUAKE_SENSOR_STATE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_SET_METER_STATUS()
    local msgname   =   "SET_METER_STATUS"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_GET_METER_GAS_VALVE_STATE()
    local msgname   =   "GET_METER_GAS_VALVE_STATE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_GET_OFLOW_DETECT_DURATION()
    local msgname   =   "GET_OFLOW_DETECT_DURATION"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_GET_PROTOCOL_VERSION()
    local msgname   =   "GET_PROTOCOL_VERSION"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_METER_SERIAL_NUMBER()
    local msgname   =   "GET_METER_SERIAL_NUMBER"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_EARTHQUAKE_SENSOR_STATE()
    local msgname   =   "GET_EARTHQUAKE_SENSOR_STATE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_PILOT_LIGHT_MODE()
    local msgname   =   "GET_PILOT_LIGHT_MODE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_COMMS_MODE()
    local msgname   =   "GET_COMMS_MODE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_ELECTRIC_QNT_VALUE()
    local msgname   =   "GET_ELECTRIC_QNT_VALUE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_NIC_BATTERY_LIFE()
    local msgname   =   "GET_NIC_BATTERY_LIFE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_METER_TYPE()
    local msgname   =   "GET_METER_TYPE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_METER_CURRENT_PRESSURE()
    local msgname   =   "GET_METER_CURRENT_PRESSURE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_SUMMATION_REPORT_INTERVAL()
    local msgname   =   "GET_SUMMATION_REPORT_INTERVAL"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_PRESSURE_REPORT_INTERVAL()
    local msgname   =   "GET_PRESSURE_REPORT_INTERVAL"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_PRESSURE_REPORT_INTERVAL()
    local msgname   =   "GET_PRESSURE_REPORT_INTERVAL"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_SUMMATION_REPORT_INTERVAL()
    local msgname   =   "GET_SUMMATION_REPORT_INTERVAL"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_GET_PRESSURE_REPORT_INTERVAL()
    local msgname   =   "GET_PRESSURE_REPORT_INTERVAL"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_GET_METER_CUSTOMERID()
    local msgname   =   "GET_METER_CUSTOMERID"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_NIC_TIME()
    local msgname   =   "GET_NIC_TIME"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_NIC_VERSION()
    local msgname   =   "GET_NIC_VERSION"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_OFLOW_DETECT_ENABLE()
    local msgname   =   "GET_OFLOW_DETECT_ENABLE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_CONFIG_DISABLE_CENTER_SHUTDOWN()
    local msgname   =   "SET_CONFIG_DISABLE_CENTER_SHUTDOWN"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_SET_CONFIG_CENTER_SHUTDOWN()
    local msgname   =   "SET_CONFIG_CENTER_SHUTDOWN"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_OFLOW_DETECT_RATE()
    local msgname   =   "GET_OFLOW_DETECT_RATE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_GET_PRESSURE_ALARM_LEVEL_LOW()
    local msgname   =   "GET_PRESSURE_ALARM_LEVEL_LOW"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_PRESSURE_ALARM_LEVEL_HIGH()
    local msgname   =   "GET_PRESSURE_ALARM_LEVEL_HIGH"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_LEAK_DETECT_RANGE()
    local msgname   =   "GET_LEAK_DETECT_RANGE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_MANUAL_RECOVER_ENABLE()
    local msgname   =   "GET_MANUAL_RECOVER_ENABLE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_GET_METER_FIRMWARE_VERSION()
    local msgname   =   "GET_METER_FIRMWARE_VERSION"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_GET_METER_SHUTOFF_CODES()
    local msgname   =   "GET_METER_SHUTOFF_CODES"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_METER_READING_VALUE()
    local msgname   =   "GET_METER_READING_VALUE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_GET_METER_STATUS()
    local msgname   =   "GET_METER_STATUS"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_METER_SERIAL_NUMBER()
    local msgname   =   "SET_METER_SERIAL_NUMBER"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_SET_PILOT_LIGHT_MODE()
    local msgname   =   "SET_PILOT_LIGHT_MODE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_COMMS_MODE()
    local msgname   =   "SET_COMMS_MODE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_NIC_MODE()
    local msgname   =   "SET_NIC_MODE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_NIC_SCHEDULE()
    local msgname   =   "SET_NIC_SCHEDULE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_METER_GAS_VALVE_STATE()
    local msgname   =   "SET_METER_GAS_VALVE_STATE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_PRESSURE_REPORT_INTERVAL()
    local msgname   =   "SET_PRESSURE_REPORT_INTERVAL"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_SET_METER_CUSTOMERID()
    local msgname   =   "SET_METER_CUSTOMERID"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_OFLOW_DETECT_ENABLE()
    local msgname   =   "SET_OFLOW_DETECT_ENABLE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_OFLOW_DETECT_DURATION()
    local msgname   =   "SET_OFLOW_DETECT_DURATION"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_SET_PRESSURE_ALARM_LEVEL_LOW()
    local msgname   =   "SET_PRESSURE_ALARM_LEVEL_LOW"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_PRESSURE_ALARM_LEVEL_HIGH()
    local msgname   =   "SET_PRESSURE_ALARM_LEVEL_HIGH"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_OFLOW_DETECT_RATE()
    local msgname   =   "SET_OFLOW_DETECT_RATE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

function TestResponse:test_SET_LEAK_DETECT_RANGE()
    local msgname   =   "SET_LEAK_DETECT_RANGE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_SET_MANUAL_RECOVER_ENABLE()
    local msgname   =   "SET_MANUAL_RECOVER_ENABLE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------


function TestResponse:test_SET_METER_READING_VALUE()
    local msgname   =   "SET_METER_READING_VALUE"
    TestResponse:common_responses(msgname)
end
---------------------------------------------------------------------------------------------------

return TestResponse