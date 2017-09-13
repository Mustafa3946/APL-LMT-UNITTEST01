---------------------------------------------------------------------------------------------------
-- Unit testing for YL and Micom LORA ports
--------------------------------------------------------------------------------------------------- 
package.path = package.path .. ';sim/?.lua' -- works on Windows or Linux
package.path = package.path .. ';tst/?.lua' -- works on Windows or Linux

local bit       = require("bit")
local def       = require("src.defines")
local loradef   = require("src.loradef")
local fme       = require(def.module.fme)
local loraNic   = require("tst.test_loraNic")
local loraData  = require("tst.test_loraNicData")
local frag      = require("src.fragmentedMessage")
local json      = require("lib.dkjson.dkjson")
local luaunit   = require("tst.luaunit")


require(def.module.deviceMgr)
require("src.lorautils")

local LoraDataMirror = {}
local LoraNicList = {}

local eid1 = "12:34:56:78:00:00:00:00"
local eid2 = "78:56:43:21:00:00:00:00"

local devices = {}
print("FME instance: ", tostring(fme))

TestResponse    =   {}
local arg1            =   {}
local arg2            =   {}
local reportNumber    =   0
local reportCommand   =   ""

function TestResponse:testResponse()
    print("Test number  :   ", reportNumber, " Command name    :   ",  reportCommand)
    luaunit.assertEquals(arg1,arg2)
    --luaunit.assertStrMatches(arg1,arg2)
end


---------------------------------------------------------------------------------------------------
-- Catch all fme.sendmessage calls
local function sendmessageCallback(msg)
    local cid       =   msg["cid"]
    local eid       =   msg["eid"]
    local payload   =   msg["payload"]
    if msg["TYPE"] == "L1" then
        LoraNicList[eid].handleLoraMessage(msg)
    end
    if msg.error_details ~= nil then
        reportNumber                =   reportNumber    +   1
        reportCommand               =   msg.msgname
        arg1                        =   msg.error_details
        arg2                        =   "MP_STATUS_SUCCESS"
        luaunit.LuaUnit.verbosity   =   2
        local runner                =   luaunit.LuaUnit.new()
        --runner:setOutputType("tap")
        runner:setOutputType("junit")
        --os.exit( runner:runSuite() )
        runner:runSuite("-v","-n", "report") 

    end

end

---------------------------------------------------------------------------------------------------
local function tableLen(tab)
    local len = 0
    for _, obj in pairs(tab) do
        len = len + 1
    end
    
    return len
end

---------------------------------------------------------------------------------------------------
-- Catch all fme.sendmessage calls
local function getmessageCallback(msg)
    if msg ~= nil then
        local cid = msg["cid"]
        local eid = msg["eid"]
        local payload = msg["payload"]
    end
end

---------------------------------------------------------------------------------------------------
-- Catch all fme.sendmessage calls
local function testDoneCallback()
    local messages = fme.getMessageLog()
    
    print()
end

---------------------------------------------------------------------------------------------------
local function mkPacket(endpoint, tracknum, msgid, bytesAfterCmd)
    local packet = ""
    if endpoint <= 7 and tracknum <= 31 then
        local prefix = bit.lshift(endpoint, 5) + tracknum
        packet = string.format("%02x", prefix) .. LoraUtils.msgidToNicCmd(msgid) .. bytesAfterCmd
    end
    
    return packet
end

---------------------------------------------------------------------------------------------------
local dummyTracknum = 0
local function getTracknum()
    local tracknum = dummyTracknum
    dummyTracknum = dummyTracknum + 1
    
    return tracknum
end

---------------------------------------------------------------------------------------------------
local function init(eid, bundleName)
    fme.sim.push_controlStart(eid, bundleName)
    LoraDataMirror[eid] = loraData.new(eid)
    LoraNicList[eid] = loraNic.new(fme, eid)
end

---------------------------------------------------------------------------------------------------
local function pushRandomMessages(number)
    local eidList = {}
    eidList[1] = eid1
    eidList[2] = eid2
    local midStart  = def.msgid.GET_METER_SUMMATION_DELIVERED
    local midEnd    = def.msgid.GET_METER_GAS_VALVE_STATE
    for i = 1, number do
        local eidIndex = math.random(1, 2)
        local eid = eidList[eidIndex]
        local msgid = math.random(midStart, midEnd)
        fme.sim.push_fmsRequest(eid, msgid, def.name[msgid],  nil)
    end
end

---------------------------------------------------------------------------------------------------
-- Push one fragment out of a bigger message into the incoming message queue to test frag timeout
local function pushIncomingFragment(eid)
    local msg = {}
    msg["eid"]  =  eid
    msg["TYPE"] = "L1"
    msg["payload"] = "4faf2100213078c21c1f28"
    
    fme.sim.push(msg)
end

---------------------------------------------------------------------------------------------------
-- This test exercises a particular case that was reported by System Test.
local function testShutoffAssembly()  
    local frags = {}
    
    table.insert(frags, {TYPE = "L1", eid=eid1, payload="4faf2100213078c21c1f28"})
    table.insert(frags, {TYPE = "L1", eid=eid1, payload="4faf2100213078c21c1f28"}) -- duplicate first fragment
    table.insert(frags, {TYPE = "L1", eid=eid1, payload="4fff2111041d30f4633f1d"})
    table.insert(frags, {TYPE = "L1", eid=eid1, payload="4fff2111041d30f4633f1d"}) -- duplicate
    table.insert(frags, {TYPE = "L1", eid=eid1, payload="4ffe211b2c683f1d29f473"})
    table.insert(frags, {TYPE = "L1", eid=eid1, payload="4ffd21871f298894871f29"})
    table.insert(frags, {TYPE = "L1", eid=eid1, payload="4ffc2168a4881f29e8ab88"})
    table.insert(frags, {TYPE = "L1", eid=eid1, payload="4ffb211f2120e5252021d4"})
    table.insert(frags, {TYPE = "L1", eid=eid1, payload="4f7a21e52520"})
 
    local result = "4f2f" .. "00213078c21c1f28" .. "11041d30f4633f1d" .. 
    "1b2c683f1d29f473" .. "871f298894871f29" .. "68a4881f29e8ab88" .. 
    "1f2120e5252021d4" .. "e52520"
 
    -- Now test the reassembly
    local dev = require("src.device")
    local device = dev.new(1, eid1)

    local isFragment, isCompleteMsg, completedMsg
    local pass = false
    for index, pkt in pairs(frags) do 
        isCompleteMsg, completedMsg = device.processLoraIncoming(pkt)
        if isCompleteMsg then
            if completedMsg == result then
                pass = true
                break
            end
        end
    end
    
    return pass -- It's a pass if we can assemble it and it matches
end

---------------------------------------------------------------------------------------------------
local function test_unsolicitedPressureGet()
    local nicmsg = {}
    nicmsg["TYPE"]  = "L1"
    nicmsg["eid"] = eid1

    -- Unsolicited GET_METER_PRESSURE
    nicmsg["payload"] = "40" .. "02" .. "0001030402"
    fme.sim.push(nicmsg)
end

---------------------------------------------------------------------------------------------------
local function toReverseHexAsciiBytes(number, numChars)
    local formatStr = "%0" .. tostring(numChars) .. "x"
    local hexAscii = string.format(formatStr, number)
    local revHexAscii = ""
    for idx = string.len(hexAscii), 1, -2 do
        revHexAscii = revHexAscii .. string.sub(hexAscii, idx-1, idx)
    end
    
    return revHexAscii
end

---------------------------------------------------------------------------------------------------
local function pushLoRaMsg(eid, cmd, payload)
    local nicmsg = {}
    nicmsg["TYPE"]  = "L1"
    nicmsg["eid"] = eid
    
    local pktId = LoraNicList[eid].getNextPktId()
    local status = 0
    nicmsg["payload"] = LoraUtils.mkRspPkt(loradef.ENDPOINT_METERING, pktId, cmd, status, payload)
    fme.sim.push(nicmsg)      
end

---------------------------------------------------------------------------------------------------
-- This tests a new scheme to filter out duplicate summation events with a rolling counter
local function test_unsolicitedSummationWithEvt()
    local nicmsg = {}
    nicmsg["TYPE"]  = "L1"
    nicmsg["eid"] = eid1
    local evt, summation    = 1, 1; pushLoRaMsg(eid1, 1, LoraNicList[eid1].mkMeterSumDeliveredPayload(summation, evt))
    -- same event, different value, should still be rejected
    evt, summation          = 1, 2; pushLoRaMsg(eid1, 1, LoraNicList[eid1].mkMeterSumDeliveredPayload(summation, evt))
    -- new event, different value, should pass
    --[[
    evt, summation          = 2, 2; pushLoRaMsg(eid1, 1, LoraNicList[eid1].mkMeterSumDeliveredPayload(summation, evt))
    -- Now send an alert
    nicmsg["payload"] = "40000001"; fme.sim.push(nicmsg)  -- A Yung Loong alert
    -- new event, should pass
    evt, summation          = 3, 2; pushLoRaMsg(eid1, 1, LoraNicList[eid1].mkMeterSumDeliveredPayload(summation, evt))
    -- new event, different value, should pass
    evt, summation          = 4, 2; pushLoRaMsg(eid1, 1, LoraNicList[eid1].mkMeterSumDeliveredPayload(summation, evt))  
    nicmsg["payload"] = "40000001"; fme.sim.push(nicmsg)  -- Another Yung Loong alert
    -- same event, should be discarded
    evt, summation          = 4, 2; pushLoRaMsg(eid1, 1, LoraNicList[eid1].mkMeterSumDeliveredPayload(summation, evt))
    --]]
end

---------------------------------------------------------------------------------------------------
local function test_ylAlert(code)
    local nicmsg = {}
    nicmsg["TYPE"]  = "L1"
    nicmsg["eid"] = eid1
    --                  hdr     cmd     type    alert data
    nicmsg["payload"] = "40" .. "00" .. "00" .. string.format("%02x", code)
    fme.sim.push(nicmsg)
end


---------------------------------------------------------------------------------------------------
local function test_getMeterShutoff()
    fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_SHUTOFF_CODES, nil)
end

---------------------------------------------------------------------------------------------------
local function test_processUnsolicitedSummation()
    local nicmsg = {}
    nicmsg["TYPE"]  = "L1"
    nicmsg["eid"] = eid1
    nicmsg["msgid"]     = def.msgid.GET_METER_SUMMATION_DELIVERED
    nicmsg["msgname"]   = def.name[nicmsg["msgid"]]
    nicmsg["payload"] = "40040001020304" 
    fme.sim.push(nicmsg)
end

---------------------------------------------------------------------------------------------------
local function test_processAlert(meter, alertType, micomDetails)
    local nicmsg = {}
    nicmsg["TYPE"]  = "L1"
    nicmsg["eid"] = eid1
    nicmsg["msgname"]  = "METER_ALERT"
    nicmsg["msgid"]    = 1
    if micomDetails == nil then
        nicmsg["payload"] = "4000" .. string.format("%02x", meter) .. string.format("%02x", alertType)
    else
        nicmsg["payload"] = "4000" .. string.format("%02x", meter) .. string.format("%02x", alertType) .. micomDetails
    end
    fme.sim.push(nicmsg)
end

---------------------------------------------------------------------------------------------------
local function test_duplicateFirstFragment(eid)
    local nicmsg = {}
    nicmsg["TYPE"]  = "L1"
    nicmsg["eid"] = eid
    nicmsg["payload"] = "58af0100299c423d202908" 
    fme.sim.push(nicmsg)
    fme.sim.push(nicmsg)
end

---------------------------------------------------------------------------------------------------
local function test_setSerial()
    local extras = {}
    extras["meter_serial_number"]  = "9876543210"
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_METER_SERIAL_NUMBER, def.name[def.msgid.SET_METER_SERIAL_NUMBER],  extras)
end

---------------------------------------------------------------------------------------------------
local function test_setReadingValue()
    local extras = {}
    extras["reading_value"]  = 1234
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_METER_READING_VALUE, "SET_METER_READING_VALUE", extras)
end

---------------------------------------------------------------------------------------------------
local function test_oflowEnable(state)
    local extras = {}
    extras["overflow_detect_enable"]  = state
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_OFLOW_DETECT_ENABLE, "SET_OFLOW_DETECT_ENABLE", extras)
end

---------------------------------------------------------------------------------------------------
local function test_setEarthquake()
    local extras = {}
    extras["earthquake_sensor_state"]  = 33
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_EARTHQUAKE_SENSOR_STATE, "SET_EARTHQUAKE_SENSOR_STATE",  extras)
end

---------------------------------------------------------------------------------------------------
local function test_setPilot()
    local extras = {}
    extras["pilot_light_mode"]  = 1
    extras["pilot_flow_min"]    = 2
    extras["pilot_flow_max"]    = 3
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_PILOT_LIGHT_MODE, "SET_PILOT_LIGHT_MODE",  extras)  
end

---------------------------------------------------------------------------------------------------
local function test_setMeterComms()
    local extras = {}
    extras["meter_comms_mode"] = 17
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_COMMS_MODE, "SET_COMMS_MODE",  extras)      
end

---------------------------------------------------------------------------------------------------
local function test_setBattery()
    local extras = {}
    extras["battery_milliamp_hours_remaining"] = 17
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_NIC_BATTERY_LIFE, "SET_NIC_BATTERY_LIFE",  extras)  
end

---------------------------------------------------------------------------------------------------
local function test_setGasValve(state)
    local extras = {}
    extras["valve_state"] = state
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_METER_GAS_VALVE_STATE, def.name[def.msgid.SET_METER_GAS_VALVE_STATE], extras)
end

---------------------------------------------------------------------------------------------------
local function test_setSumReport(interval)
    local extras = {}
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_SUMMATION_REPORT_INTERVAL, "SET_SUMMATION_REPORT_INTERVAL",   extras)
end

---------------------------------------------------------------------------------------------------
local function test_setPressureReport()
    local extras = {}
    extras["report_interval_mins"] = 0xcdab
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_PRESSURE_REPORT_INTERVAL,  "SET_PRESSURE_REPORT_INTERVAL",   extras)
end

---------------------------------------------------------------------------------------------------
local function test_setCustId()
    local extras = {}
    extras["customer_id"] = "01234567891234\n" -- 14 characters
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_METER_CUSTOMERID, def.name[def.msgid.SET_METER_CUSTOMERID],  extras)
end


---------------------------------------------------------------------------------------------------
local function test_getMeterType_2(eid)
    fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_TYPE,  "GET_METER_TYPE",   nil)
    
    local nicmsg = {}
    nicmsg["TYPE"]  = "L1"
    nicmsg["eid"] = eid
    local header = bit.lshift(loradef.ENDPOINT_METERING, 5) + 1
    nicmsg["payload"] = string.format("%02x", header) .. "03000102" 
    fme.sim.push(nicmsg)    
end

local function test_setNicTimeCorrection()
    local extras = {}
    extras["delta"] = 18
    --extras["ackFlag"] = "00"
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_NIC_TIME_CORRECTION, "SET_NIC_TIME_CORRECTION",  extras)  
end

---------------------------------------------------------------------------------------------------
local function test_setMeterStatus()
    local extras = {}
    --[[
    local statusTab = {} 
    statusTab["low_pressure_shutdown_bypass"] = 0
    statusTab["safety_duration_bypass"] = 0
    statusTab["flow_rate_exceeded_warning"] = 1
    statusTab["oscillation_detection_shutdown_bypass"] = 0
    statusTab["type_of_time_extension"] = 0
    statusTab["call_for_periodic_meter_reading"] = 0
    statusTab["low_voltage_call"] = 0
    statusTab["max_ind_flow_rate_exceeded_shutdown_bypass"] = 0
    statusTab["pressure_monitor"] = 0
    statusTab["call_for_load_survey"] = 0
    statusTab["pilot_flame_register"] = 0
    statusTab["write_protect"] = 0
    statusTab["conduct_load_survey"] = 1
    statusTab["safety_duration"] = 0
    statusTab["internal_pipe_leakage_timer_B1"] = 0
    statusTab["internal_pipe_leakage_timer_B2"] = 0
    statusTab["tot_max_flow_rate_exceeded_shutdown_bypass"] = 0
    statusTab["c_line"] = 1
    statusTab["low_voltage_shutdown_warning"] = 1
    statusTab["internal_pipe_leakage_warning_display_bypass"] = 1
    statusTab["internal_pipe_leakage_pressure_monitor"] = 0
    statusTab["safety_duration_start_time"] = 1
    statusTab["B_line_selection"] = 0
 
    extras["status"] = json.encode(statusTab)
    ]]--
    
    extras["location"]  = 3
    extras["value"]     = 0

    fme.sim.push_fmsRequest(eid1, def.msgid.SET_METER_STATUS, "SET_METER_STATUS", extras)
end

local function test_setNicTime()
    local extras = {}
    extras["schedule"] = os.time() - 130
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_NIC_TIME, "SET_NIC_TIME",  extras)  
end
---------------------------------------------------------------------------------------------------

local function test_setNicSchedule()
    local extras = {}
    extras["day_mask"]                 = 4  --"04"
    extras["active_period_start_time"] = 95 --"95"
    extras["active_period_end_time"]   = 1  --"01"
    extras["modes"]       = 28 --"28"
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_NIC_SCHEDULE, def.name[def.msgid.SET_NIC_SCHEDULE], extras)      
end

---------------------------------------------------------------------------------------------------

local function test_setNicMode()
    local extras = {}
    extras["mode_id"]                           = 1  --"04"
    extras["MAC_polling_interval"]              = 16909060 --"95"
    extras["spreadFactor_confirmation"]         = 1  --"01"
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_NIC_MODE, def.name[def.msgid.SET_NIC_MODE], extras)      
end

---------------------------------------------------------------------------------------------------
local function test_setOflowDetectDuration()
    local extras = {}
    extras["overflow_detect_duration"]          = 65297
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_OFLOW_DETECT_DURATION, def.name[def.msgid.SET_OFLOW_DETECT_DURATION], extras)      
end

---------------------------------------------------------------------------------------------------

local function test_setOflowDetectRate()
    local extras = {}
    extras["overflow_detect_flowrate"]          = 250
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_OFLOW_DETECT_RATE, def.name[def.msgid.SET_OFLOW_DETECT_RATE], extras)      
end

---------------------------------------------------------------------------------------------------

local function test_setPressureAlarmLevelLow()
    local extras = {}
    extras["pressure_alarm_level_low"]          = 250
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_PRESSURE_ALARM_LEVEL_LOW, def.name[def.msgid.SET_PRESSURE_ALARM_LEVEL_LOW], extras)      
end

---------------------------------------------------------------------------------------------------

local function test_setPressureAlarmLevelHigh()
    local extras = {}
    extras["pressure_alarm_level_high"]          = 250
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_PRESSURE_ALARM_LEVEL_HIGH, def.name[def.msgid.SET_PRESSURE_ALARM_LEVEL_HIGH], extras)      
end

---------------------------------------------------------------------------------------------------

local function test_setLeakDetectRange()
    local extras = {}
    extras["leak_detect_range"]                   = 250
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_LEAK_DETECT_RANGE, def.name[def.msgid.SET_LEAK_DETECT_RANGE], extras)      
end

---------------------------------------------------------------------------------------------------

local function test_setManualRecoverEnable()
    local extras = {}
    extras["manual_recover_enable"]          = 250
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_MANUAL_RECOVER_ENABLE, def.name[def.msgid.SET_MANUAL_RECOVER_ENABLE], extras)      
end

---------------------------------------------------------------------------------------------------
local function test_setMeterReadingValue()
    local extras = {}
    extras["reading_value"]          = 4279369489
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_METER_READING_VALUE, def.name[def.msgid.SET_METER_READING_VALUE], extras)      
end

---------------------------------------------------------------------------------------------------


local bundleName = "SomeBundle"
init(eid1, bundleName)
init(eid2, bundleName)

--[[
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_GAS_VALVE_STATE,      "GET_METER_GAS_VALVE_STATE",        nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_SUMMATION_DELIVERED,  "GET_METER_SUMMATION_DELIVERED",    nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_OFLOW_DETECT_DURATION,      "GET_OFLOW_DETECT_DURATION",        nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_PROTOCOL_VERSION,           "GET_PROTOCOL_VERSION",             nil) 
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_SERIAL_NUMBER,        "GET_METER_SERIAL_NUMBER",          nil)  
fme.sim.push_fmsRequest(eid1, def.msgid.GET_EARTHQUAKE_SENSOR_STATE,    "GET_EARTHQUAKE_SENSOR_STATE",      nil) 
fme.sim.push_fmsRequest(eid1, def.msgid.GET_PILOT_LIGHT_MODE,           "GET_PILOT_LIGHT_MODE",             nil)             
fme.sim.push_fmsRequest(eid1, def.msgid.GET_COMMS_MODE,                 "GET_COMMS_MODE",                   nil)              
fme.sim.push_fmsRequest(eid1, def.msgid.GET_ELECTRIC_QNT_VALUE,         "GET_ELECTRIC_QNT_VALUE",           nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_NIC_BATTERY_LIFE,           "GET_NIC_BATTERY_LIFE",             nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_SUMMATION_DELIVERED,  "GET_METER_SUMMATION_DELIVERED",    nil)
fme.sim.push_fmsRequest(eid2, def.msgid.GET_METER_TYPE,                 "GET_METER_TYPE",                   nil)
fme.sim.push_fmsRequest(eid2, def.msgid.GET_METER_SUMMATION_DELIVERED,  "GET_METER_SUMMATION_DELIVERED",    nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_CURRENT_PRESSURE,     "GET_METER_CURRENT_PRESSURE",       nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_GAS_VALVE_STATE,      "GET_METER_GAS_VALVE_STATE",        nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_SUMMATION_REPORT_INTERVAL,  "GET_SUMMATION_REPORT_INTERVAL",    nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_PRESSURE_REPORT_INTERVAL,   "GET_PRESSURE_REPORT_INTERVAL",     nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_GAS_VALVE_STATE,      "GET_METER_GAS_VALVE_STATE",        nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_SUMMATION_REPORT_INTERVAL,  "GET_SUMMATION_REPORT_INTERVAL",    nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_PRESSURE_REPORT_INTERVAL,   "GET_PRESSURE_REPORT_INTERVAL",     nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_CUSTOMERID,           "GET_METER_CUSTOMERID",             nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_NIC_TIME,                   "GET_NIC_TIME",                     nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_NIC_VERSION,                "GET_NIC_VERSION",                  nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_OFLOW_DETECT_ENABLE,        "GET_OFLOW_DETECT_ENABLE",          nil) 
fme.sim.push_fmsRequest(eid1, def.msgid.SET_CONFIG_DISABLE_CENTER_SHUTDOWN, "SET_CONFIG_DISABLE_CENTER_SHUTDOWN", nil)
fme.sim.push_fmsRequest(eid1, def.msgid.SET_CONFIG_CENTER_SHUTDOWN,     "SET_CONFIG_CENTER_SHUTDOWN",       nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_OFLOW_DETECT_RATE,          "GET_OFLOW_DETECT_RATE",            nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_PRESSURE_ALARM_LEVEL_LOW,   "GET_PRESSURE_ALARM_LEVEL_LOW",     nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_PRESSURE_ALARM_LEVEL_HIGH,  "GET_PRESSURE_ALARM_LEVEL_HIGH",    nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_LEAK_DETECT_RANGE,          "GET_LEAK_DETECT_RANGE",            nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_MANUAL_RECOVER_ENABLE,      "GET_MANUAL_RECOVER_ENABLE",        nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_FIRMWARE_VERSION,     "GET_METER_FIRMWARE_VERSION",       nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_SHUTOFF_CODES,        "GET_METER_SHUTOFF_CODES",          nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_READING_VALUE,        "GET_METER_READING_VALUE",          nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_TIME,                 "GET_METER_TIME",                   nil)
fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_STATUS,               "GET_METER_STATUS",                 nil)
--]]

test_setEarthquake()
test_setMeterStatus()
--[[
test_getMeterType_2(eid1)
test_setMeterStatus()
test_unsolicitedPressureGet()
test_unsolicitedSummationWithEvt()
testShutoffAssembly()
test_processUnsolicitedSummation()
test_processAlert(loradef.YUNGLOONG_LORA_ALERT, 2)           
test_setSerial()
test_duplicateFirstFragment(eid1)

test_setPilot()
test_setMeterComms()

test_setNicMode()
test_setNicSchedule()
test_setBattery()
test_setNicTimeCorrection()
test_setGasValve(1)
test_setGasValve(0)
test_setSumReport(1234)
test_setPressureReport()
test_setCustId()
test_oflowEnable(1)
test_oflowEnable(0)
test_setOflowDetectDuration()
test_setOflowDetectRate()
test_setPressureAlarmLevelLow()
test_setPressureAlarmLevelHigh()
test_setLeakDetectRange()
test_setManualRecoverEnable()
test_setMeterReadingValue()

--local respmsg = {}
--responses.processGetNicVersion(respmsg, 22, "000102034205060747")

fme.sim.push_controlStop(eid2)
fme.sim.push_controlStop(eid1)
pushIncomingFragment(eid1)
for code = 0x01, 0x63 do
    test_ylAlert(code)
end
test_setReadingValue()
pushRandomMessages(100)
--]]

--fme.sim.push_testEnd()

fme.sim.registerCallback("sendmessage", sendmessageCallback)
fme.sim.registerCallback("getmessage",  getmessageCallback)
fme.sim.registerCallback("testdone",    testDoneCallback)

require("src.main")

