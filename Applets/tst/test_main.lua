---------------------------------------------------------------------------------------------------
-- Unit testing for YL and Micom LORA ports
--------------------------------------------------------------------------------------------------- 
package.path = package.path .. ';sim/?.lua' -- works on Windows or Linux
package.path = package.path .. ';tst/?.lua' -- works on Windows or Linux

local responses = require("src.responses")
local bit       = require("bit")
local def       = require("src.defines")
local loradef   = require("src.loradef")
local fme       = require(def.module.fme)
local loraNic   = require("tst.test_loraNic")
local loraData  = require("tst.test_loraNicData")
local frag      = require("src.fragmentedMessage")
local json      = require("lib.dkjson.dkjson")

require(def.module.deviceMgr)
require("src.lorautils")

local LoraDataMirror = {}
local LoraNicList = {}

local eid1 = "12:34:56:78:00:00:00:00"
local eid2 = "78:56:43:21:00:00:00:00"

local devices = {}
print("FME instance: ", tostring(fme))

---------------------------------------------------------------------------------------------------
-- Catch all fme.sendmessage calls
local function sendmessageCallback(msg)
    local cid = msg["cid"]
    local eid = msg["eid"]
    local payload = msg["payload"]
    if msg["TYPE"] == "L1" then
        LoraNicList[eid].handleLoraMessage(msg)
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
local function matchFMSRequestResponses(requests, responses)
    local match = false
    local allFound = true
    for cid, req in pairs(requests) do
        local resp = responses[cid]
        if resp ~= nil then
            if req.eid == resp.eid then
                if req.msgname == resp.msgname then

                    match = true
                else
                    allFound = false
                    break
                end
            else
                print("waaaa!")
            end
        end
    end

    if allFound then
        print()
    end
end

---------------------------------------------------------------------------------------------------
-- Catch all fme.sendmessage calls
local function getmessageCallback()

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
        fme.sim.push_fmsRequest(eid, msgid,   nil)
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
local function test_processGetMcMeterStatus()
    local nicmsg = {}
    nicmsg["TYPE"]  = "L1"
    nicmsg["eid"] = eid1
    local tbl = {}
    tbl["result_code"] = loradef.MP_STATUS_SUCCESS
    nicmsg["payload"] = mkPacket(loradef.ENDPOINT_METERING, getTracknum(), 4, "00010203")
    local nicPayload = string.sub(nicmsg["payload"], 5)
    local result = responses.processGetMcMeterStatus(tbl, nicPayload)
    
    return result
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
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_METER_SERIAL_NUMBER,   extras)
end

---------------------------------------------------------------------------------------------------
local function test_setReadingValue()
    local extras = {}
    extras["reading_value"]  = 1234
    fme.pushFmsRequest(eid1, def.msgid.SET_METER_READING_VALUE,   extras)
end

---------------------------------------------------------------------------------------------------
local function test_oflowEnable(state)
    local extras = {}
    extras["overflow_detect_enable"]  = state
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_OFLOW_DETECT_ENABLE, extras)
end

---------------------------------------------------------------------------------------------------
local function test_setEarthquake()
    local extras = {}
    extras["earthquake_sensor_state"]  = 33
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_EARTHQUAKE_SENSOR_STATE,   extras)
end

---------------------------------------------------------------------------------------------------
local function test_setPilot()
    local extras = {}
    extras["pilot_light_mode"]  = 1
    extras["pilot_flow_min"]    = 2
    extras["pilot_flow_max"]    = 3
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_PILOT_LIGHT_MODE,   extras)  
end

---------------------------------------------------------------------------------------------------
local function test_setMeterComms()
    local extras = {}
    extras["meter_comms_mode"] = 17
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_COMMS_MODE,   extras)      
end

---------------------------------------------------------------------------------------------------
local function test_setBattery()
    local extras = {}
    extras["battery_milliamp_hours_remaining"] = 17
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_NIC_BATTERY_LIFE,   extras)  
end

---------------------------------------------------------------------------------------------------
local function test_setGasValve(state)
    local extras = {}
    extras["valve_state"] = state
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_METER_GAS_VALVE_STATE, extras)
end

---------------------------------------------------------------------------------------------------
local function test_setSumReport(interval)
    local extras = {}
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_SUMMATION_REPORT_INTERVAL,    extras)
end

---------------------------------------------------------------------------------------------------
local function test_setPressureReport()
    local extras = {}
    extras["report_interval_mins"] = 0xcdab
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_PRESSURE_REPORT_INTERVAL,     extras)
end

---------------------------------------------------------------------------------------------------
local function test_setCustId()
    local extras = {}
    extras["customer_id"] = "01234567891234\n" -- 14 characters
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_METER_CUSTOMERID,     extras)
end

---------------------------------------------------------------------------------------------------
local function test_getMeterType_1()
    local tbl = {}
    tbl["result_code"] = loradef.MP_STATUS_SUCCESS
    local bytesAfterCmd = "000102"
    responses.processGetMeterType(tbl, bytesAfterCmd)
end

---------------------------------------------------------------------------------------------------
local function test_getMeterType_2(eid)
    fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_TYPE,     nil)
    
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
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_NIC_TIME_CORRECTION,   extras)  
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

    fme.sim.push_fmsRequest(eid1, def.msgid.SET_METER_STATUS, extras)
end

local function test_setNicTime()
    local extras = {}
    extras["nic_time"] = os.time() - 130
    fme.sim.push_fmsRequest(eid1, def.msgid.SET_NIC_TIME,   extras)  
end

---------------------------------------------------------------------------------------------------
--
---------------------------------------------------------------------------------------------------
local bundleName = "SomeBundle"
init(eid1, bundleName)
init(eid2, bundleName)

fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_READING_VALUE, "GET_METER_READING_VALUE", nil)
--fme.pushFmsRequest(eid1, def.msgid.SET_CONFIG_DISABLE_CENTER_SHUTDOWN, nil)
--fme.pushFmsRequest(eid1, def.msgid.SET_CONFIG_CENTER_SHUTDOWN, nil)
--test_getMeterType_2(eid1)
--pushIncomingFragment(eid1)
--for code = 0x01, 0x63 do
--    test_ylAlert(code)
--end
--fme.sim.push_fmsRequest(eid1, def.msgid.GET_METER_STATUS,                nil)
--test_setMeterStatus()
--test_unsolicitedPressureGet()
--test_unsolicitedSummationWithEvt()
--test_processGetMcMeterStatus()
--testShutoffAssembly()
--test_processUnsolicitedSummation()
--test_processAlert(loradef.YUNGLOONG_LORA_ALERT, 2)           
--test_setSerial()
--test_setReadingValue()
--test_duplicateFirstFragment(eid1)

--test_setEarthquake()
--test_setPilot()
--test_setMeterComms()

--test_setNicTime()
--test_setBattery()
--test_setNicTimeCorrection()
--test_setGasValve(1)
--test_setGasValve(0)
--test_setSumReport(1234)
--test_setPressureReport()
--test_setCustId()
--test_oflowEnable(1)
--test_oflowEnable(0)
--fme.pushFmsRequest(eid1, def.msgid.GET_OFLOW_DETECT_ENABLE,         nil) 
--fme.pushFmsRequest(eid1, def.msgid.GET_OFLOW_DETECT_ENABLE,         nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_OFLOW_DETECT_ENABLE,         nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_OFLOW_DETECT_DURATION,       nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_OFLOW_DETECT_DURATION,       nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_PROTOCOL_VERSION,            nil) 
--fme.pushFmsRequest(eid1, def.msgid.GET_METER_SERIAL_NUMBER,         nil)  
--fme.pushFmsRequest(eid1, def.msgid.GET_METER_SERIAL_NUMBER,         nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_EARTHQUAKE_SENSOR_STATE,     nil) 
--fme.pushFmsRequest(eid1, def.msgid.GET_PILOT_LIGHT_MODE,            nil)             
--fme.pushFmsRequest(eid1, def.msgid.GET_COMMS_MODE,                  nil)              
--fme.pushFmsRequest(eid1, def.msgid.GET_ELECTRIC_QNT_VALUE,          nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_NIC_BATTERY_LIFE,            nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_METER_SUMMATION_DELIVERED,   nil)
--fme.pushFmsRequest(eid2, def.msgid.GET_METER_TYPE,                  nil)
--fme.pushFmsRequest(eid2, def.msgid.GET_METER_SUMMATION_DELIVERED,   nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_METER_CURRENT_PRESSURE,      nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_METER_GAS_VALVE_STATE,       nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_SUMMATION_REPORT_INTERVAL,   nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_PRESSURE_REPORT_INTERVAL,    nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_METER_GAS_VALVE_STATE,       nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_SUMMATION_REPORT_INTERVAL,   nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_PRESSURE_REPORT_INTERVAL,    nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_METER_CUSTOMERID,            nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_NIC_TIME,                    nil)
--fme.pushFmsRequest(eid1, def.msgid.GET_NIC_VERSION,                 nil)
--pushRandomMessages(100)

--local respmsg = {}
--responses.processGetNicVersion(respmsg, 22, "000102034205060747")

--fme.sim.push_controlStop(eid2)
--fme.sim.push_controlStop(eid1)
--fme.sim.push_testEnd()


fme.sim.registerCallback("sendmessage", sendmessageCallback)
fme.sim.registerCallback("getmessage",  getmessageCallback)
fme.sim.registerCallback("testdone",    testDoneCallback)

require("src.main")
