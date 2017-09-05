---------------------------------------------------------------------------------------------------
-- Unit testing for YL and Micom LORA ports
---------------------------------------------------------------------------------------------------   
local responses = require("src.responses")
local bit       = require("bit")
local def       = require("src.defines")
local loradef   = require("src.loradef")
require(def.module.deviceMgr)
local fme = require(def.module.fme)
fme.open()

require("src.main")

---------------------------------------------------------------------------------------------------
-- Initial setup stuff
---------------------------------------------------------------------------------------------------
local eid = "123"
DeviceMgr.addDevice(eid)

local dummyTracknum = 0
local m_requestTestResults = {}

---------------------------------------------------------------------------------------------------
local function getTracknum()
    local tracknum = dummyTracknum
    dummyTracknum = dummyTracknum + 1
    
    return tracknum
end

---------------------------------------------------------------------------------------------------
local function mkPacket(endpoint, tracknum, msgid, bytesAfterCmd)
    local packet = ""
    if endpoint <= 7 and tracknum <= 31 then
        local prefix = bit.lshift(endpoint, 5) + tracknum
        packet = string.format("%02x", prefix) .. DeviceMgr.msgidToNicCmd(msgid) .. bytesAfterCmd
    end
    
    return packet
end

---------------------------------------------------------------------------------------------------
local function mkFmsRequest(msgid)
    local msg = {}
    msg["eid"]      =  eid  
    msg["msgname"]  =  def.name[msgid]
    msg["msgid"]    =  msgid
    msg["TYPE"]     = "MS"
    
    return msg
end

---------------------------------------------------------------------------------------------------
local function testRequest(cmd, paramPayload, extraParams)
    local success = false
    
    local msg = mkFmsRequest(cmd)
    if type(extraParams) == "table" then 
        for name, value in pairs(extraParams) do
            msg[name] = value
        end
    end
    DeviceMgr.processLoraRequest(msg) 
    local sent, seq = fme.peek()
    local sentLora = sent["payload"]
    local expLora = mkPacket(loradef.ENDPOINT_METERING, seq, cmd, paramPayload)
    if not string.match(sentLora, expLora) then
        m_requestTestResults[def.name[cmd]] = "Request: FAIL"
    else
        m_requestTestResults[def.name[cmd]] = "Request: PASS"
    end    
end

---------------------------------------------------------------------------------------------------
local function printTestResults()
    for name, result in pairs(m_requestTestResults) do
        print(string.format("%-50s %s", name, result))
    end
end

---------------------------------------------------------------------------------------------------
local function testFMSRequests()
    -----------------------------------------------------------------------------------------------
    -- Test downstream messages with no params
    for _, msgid in pairs(def.msgid) do
        if loradef.reqParams[msgid] == nil then
            testRequest(msgid, "", nil)
        end
    end
   
    -----------------------------------------------------------------------------------------------
    -- Test downstream messages with params   
    local extraParams         = {}
    extraParams["time"] = 1234
    local timeHex = string.format("%04x", extraParams["time"])
    testRequest(def.msgid.SET_METER_TIME, timeHex, extraParams) 
    extraParams         = {}    
    
    extraParams["location"] = 1
    extraParams["value"]    = 2
    testRequest(def.msgid.SET_METER_STATUS, "", extraParams)
end

---------------------------------------------------------------------------------------------------
local function testFMSResponses()
    -----------------------------------------------------------------------------------------------
    -- Unsolicited METER_SUMMATION_DELIVERED
    local respmsg = {}
    respmsg["eid"] = eid
    respmsg["payload"] = mkPacket(loradef.ENDPOINT_METERING, getTracknum(), def.msgid.METER_SUMMATION_DELIVERED, "0001020304")
    local nicPayload = string.sub(respmsg["payload"], 5)
    DeviceMgr.processAndSendUnsolicitedToSwitch( respmsg, def.msgid.METER_SUMMATION_DELIVERED, nicPayload)

    -----------------------------------------------------------------------------------------------
    -- Unsolicited METER_CURRENT_PRESSURE
    respmsg["payload"] = mkPacket(loradef.ENDPOINT_METERING, getTracknum(), def.msgid.METER_CURRENT_PRESSURE, "0001020304")
    nicPayload = string.sub(respmsg["payload"], 5)
    DeviceMgr.processAndSendUnsolicitedToSwitch( respmsg, def.msgid.METER_CURRENT_PRESSURE, nicPayload)
end

---------------------------------------------------------------------------------------------------
local function testLoraMessages()
    local msg = {}
    msg["eid"]      =  eid
    msg["tracknum"] =  0
    msg["TYPE"]     = "L1"
    
    local ylAlertCode = "00"
    local mcAlertCode = "01"
    local mcAlertData = "FF0000FF"
    local alertData = "01020304"
    local alertCode = mcAlertCode
    
    msg = mkFmsRequest(def.SET_CONFIG_CENTER_SHUTDOWN)
    --msg["payload"] = mkPacket(loradef.ENDPOINT_METERING, getTracknum(), def.METER_ALERT - 1, alertCode .. alertData)
    
    msg["payload"] = "4c000101a10800"  -- An actual Micom Alert
    DeviceMgr.processLoraIncoming(msg)
    
    alertData = "01a10800"
    msg["payload"] = mkPacket(loradef.ENDPOINT_METERING, getTracknum(), def.msgid.METER_ALERT - 1, mcAlertCode .. alertData)
    DeviceMgr.processLoraIncoming(msg)
    
    alertData = "01"
    msg["payload"] = mkPacket(loradef.ENDPOINT_METERING, getTracknum(), def.msgid.METER_ALERT - 1, ylAlertCode .. alertData)
    DeviceMgr.processLoraIncoming(msg)
    
    -----------------------------------------------------------------------------------------------
    -- Test duplicates
    msg["payload"] = mkPacket(loradef.ENDPOINT_METERING, getTracknum(), 16, "6666")
    DeviceMgr.processLoraIncoming(msg)
    DeviceMgr.processLoraIncoming(msg)
    msg["payload"] = mkPacket(loradef.ENDPOINT_METERING, getTracknum(), 16, "6666")
    DeviceMgr.processLoraIncoming(msg)
    
    -----------------------------------------------------------------------------------------------
    -- processGetMcMeterStatus test
    msg["payload"] = mkPacket(loradef.ENDPOINT_METERING, getTracknum(), 4, "00010203")
    local nicPayload = string.sub(msg["payload"], 5)
    local result = processGetMcMeterStatus(respmsg, def.msgid.GET_METER_STATUS, nicPayload)
    
    -----------------------------------------------------------------------------------------------
    -- Test processGetMcMeterTime
    local theTime = 100*1000
    local bigEnd = string.format("%08x", theTime)
    local littleEnd = string.sub(bigEnd, 7, 8) .. string.sub(bigEnd, 5, 6) .. string.sub(bigEnd, 3, 4) .. string.sub(bigEnd, 1, 2)
    local bytesAfterCmd = "00" .. littleEnd
    msg["payload"] = mkPacket(loradef.ENDPOINT_METERING, getTracknum(), def.msgid.GET_METER_TIME, bytesAfterCmd)
    nicPayload = string.sub(msg["payload"], 5)
    local outTab = processGetMcMeterTime(msg, def.msgid.GET_METER_TIME, nicPayload)
    if outTab["time"] ~= theTime then
        print("fail")
    end 
    
    msg["payload"] = "45AF00002180E25F1F2194"
    DeviceMgr.processLoraIncoming(msg)
    msg["payload"] = "45FF00FB5F1F1B4C16601F"
    DeviceMgr.processLoraIncoming(msg)
    msg["payload"] = "45FE001B741B601F1BAC2E"
    DeviceMgr.processLoraIncoming(msg)
    msg["payload"] = "45FD00601F1B3839601F1B"
    DeviceMgr.processLoraIncoming(msg)
    msg["payload"] = "45FC007448601F1B583661"
    DeviceMgr.processLoraIncoming(msg)
    msg["payload"] = "45FB001F1BA039611F21C0"
    DeviceMgr.processLoraIncoming(msg)
    msg["payload"] = "457A00DA631F"
    DeviceMgr.processLoraIncoming(msg)    
end

---------------------------------------------------------------------------------------------------
local function performMiscTests()
    -----------------------------------------------------------------------------------------------
    -- ACK messages
    for num = 1, 40 do
        SendAckToLoraDevice ( respmsg, cmd, status )
    end
    
    -----------------------------------------------------------------------------------------------
    -- Unit test of getSeqnoFromResponse and getEndpointFromResponse
    for sequence = 0, 31 do
        for endpoint = 0, 7 do
            -- Construct a pseudo response packet
            local payloadByte = bit.lshift(endpoint, 5) + sequence
            local payload = string.format("%02x", payloadByte)
            local rxseq = responses.getSeqnoFromResponse(payload)
            local ep = LoraUtils.getEndpoint(payload)
            if ep ~= endpoint then
                print("rxep ~= endpoint")    
            end
            if rxseq ~= sequence then
                print("rxseq ~= sequence")
            end
        end
    end    
end

---------------------------------------------------------------------------------------------------
local function testFragmentedMessages()
    local cmd, frag = LoraUtils.getCmdFromResponse( "42fe0029bc26a31f29844f" )
end

---------------------------------------------------------------------------------------------------
-- FMS messages
---------------------------------------------------------------------------------------------------
testFMSRequests()
testFMSResponses()

---------------------------------------------------------------------------------------------------
-- LORA messages
---------------------------------------------------------------------------------------------------
testLoraMessages()

---------------------------------------------------------------------------------------------------
-- Other stuff
---------------------------------------------------------------------------------------------------
testLoraMessages()

---------------------------------------------------------------------------------------------------
-- Other stuff
---------------------------------------------------------------------------------------------------
testFragmentedMessages()

printTestResults()

print("done")