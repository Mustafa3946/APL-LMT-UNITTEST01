-- --------------------------------------------------------------------------------------------
-- Purpose: LoRa Lua Application:  lora Responses
--
-- Details:
--
-- Copyright Statement:
-- Copyright © 2014 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored, 
-- transcribed in an information retrieval system, translated into -- any language, or transmitted 
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise, 
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
-- --------------------------------------------------------------------------------------------

local def       = require "src.defines"
local fme       = require(def.module.fme)
local loradef   = require(def.module.loradef)
local json      = require (def.module.json)
local bit       = require("bit")

local Responses = {}

local PAYLOAD_IDX_SEQ_START     = 1
local PAYLOAD_IDX_SEQ_END       = 2

local SEQ_MASK  = 0x1F  -- lower 5 bits of prefix byte
local EP_MASK   = 0xE0  -- upper 3 bits of prefix byte

---------------------------------------------------------------------------------------------------
local function getBitOfPos ( value, pos)  -- Value is number
   local onebit = 0
   while ( pos > 0 ) do
    onebit = math.fmod(value,2)
    value  = ( value - onebit ) / 2
    pos    = pos -1
  end
  return onebit
end

---------------------------------------------------------------------------------------------------
Responses.getSeqnoFromResponse = function(wholeNicPkt)   
    return tonumber(string.sub(wholeNicPkt , 3, 4), 16) -- TODO:  fix magic #s
end

---------------------------------------------------------------------------------------------------
Responses.getMsgidFromResponse = function(payload)
    local cmd = LoraUtils.getCmdFromResponse(payload)
    local msgid = cmd
    if cmd <= 31 then
        msgid = cmd + 1
    end
    
    return msgid
end

---------------------------------------------------------------------------------------------------
function Responses.extractRspData(wholeNicMsg)
    local bytesAfterCmd = string.sub(wholeNicMsg, 5)
    local tbl = {}
    tbl["result_code"] = tonumber(string.sub(bytesAfterCmd, 1, 2), 16)
    tbl["error_details"] = loradef.ERROR_DETAILS[tbl["result_code"]]
    
    return tbl, bytesAfterCmd
end

---------------------------------------------------------------------------------------------------
function SendAckToLoraDevice(eid, wholeNicMsg, status)
    local cmd = LoraUtils.getCmdFromResponse(wholeNicMsg)
    --local msgid = LoraUtils.getMsgidFromNicCmd(cmd)
    local msgid = LoraUtils.getMsgidFromNicCmd(wholeNicMsg)
    local ackmsg = {}
    ackmsg["msgid"]     = msgid
    ackmsg["TYPE"]      = "L1"
    ackmsg["msgname"]   = def.name[msgid]
    ackmsg["eid"]       = eid
    ackmsg["payload"]   = ""
    local seqno         = Responses.getSeqnoFromResponse(wholeNicMsg)
    --print("Seq = ", seqno)
    local bitseq        = bit.band(seqno, SEQ_MASK)
    local bitep         = loradef.METER_APP_CMD
    local prefix        = bit.bor(bitep, bitseq)
    local strCmd        = string.format ( "%02x", cmd )
    local strStatus     = string.format("%02x", status)
    ackmsg["payload"]   = string.format("%02x", prefix) .. strCmd .. strStatus
    fme.sendmessage(def.fmeContext, ackmsg) -- L1 msg:  ACK
end

---------------------------------------------------------------------------------------------------
Responses.sendLoraResponseToSwitch = function(reqmsg, rsptbl)
    rsptbl["cid"]       = reqmsg["cid"]
    rsptbl["flags"]     = def.FLAG_FRAMETYPE_RESP + def.FLAG_ACK_REQ
    if rsptbl["result_code"] == nil then
        rsptbl["result_code"] = loradef.MP_STATUS_SUCCESS
    end
    rsptbl["TYPE"]      = "MS"
    rsptbl["eid"]       = reqmsg["eid"]
    rsptbl["msgname"]   = reqmsg["msgname"]
    rsptbl["msgid"]     = reqmsg["msgid"]
    print("FMS<=App: ", rsptbl["eid"], " CID ", rsptbl["cid"], " ", rsptbl["msgname"])
    for name, value in pairs(rsptbl) do
        local output = string.format("%-20s", name)
        print("    ", output, " = ", value)
    end  
    
    fme.sendmessage(def.fmeContext, rsptbl) -- FMS msg:  response from LoRa
end

---------------------------------------------------------------------------------------------------
function Responses.processSetCmdResponse (tbl, bytesAfterCmd)
    if string.len(bytesAfterCmd) ~= 2 then
        print("Error: wrong number of bytes in set response")
    end

    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetMcMeterTime(tbl, bytesAfterCmd) 
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        -- The time from the NIC is little endian, so here we reverse the byte order.
        tbl["time"] =  tonumber((string.sub(bytesAfterCmd, 9, 10) .. string.sub(bytesAfterCmd, 7, 8) .. 
                string.sub(bytesAfterCmd, 5, 6) .. string.sub(bytesAfterCmd, 3, 4)), 16)
        -- NIC time is Y2000 based, add offset to correct back to UTC.
        tbl["time"] = tbl["time"] + def.J2000_CONSTANT
    else
        tbl["time"] = 0
    end
    
    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetMcMeterCustIdRsp(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["customer_id"] = LoraUtils.hexAsciiToString(string.sub(bytesAfterCmd, 3))
    else
        tbl["customer_id"] = ""
    end

    return tbl
end

-------------------------------------------------------------------------------------------------
Responses.statusLabels = {}
local function initStatus( byteNo, bitNo, label)
    if Responses.statusLabels[byteNo] == nil then
        Responses.statusLabels[byteNo] = {}
    end
    
    Responses.statusLabels[byteNo][bitNo] = label
end

initStatus(0, 0, "c_line")
initStatus(0, 1, "flow_rate_exceeded_warning")
initStatus(0, 2, "low_pressure_shutdown_bypass")
initStatus(0, 3, "oscillation_detection_shutdown_bypass")
initStatus(0, 4, "internal_pipe_leakage_timer_B1")
initStatus(0, 5, "internal_pipe_leakage_timer_B2")
initStatus(0, 6, "internal_pipe_leakage_pressure_monitor")
-- bit 7 unused
initStatus(1, 0, "write_protect")
initStatus(1, 1, "B_line_selection")
initStatus(1, 2, "safety_duration_start_time")
initStatus(1, 3, "pressure_monitor")
initStatus(1, 4, "internal_pipe_leakage_warning_display_bypass")
initStatus(1, 5, "low_voltage_call")
initStatus(1, 6, "max_ind_flow_rate_exceeded_shutdown_bypass")
initStatus(1, 7, "tot_max_flow_rate_exceeded_shutdown_bypass")
initStatus(2, 0, "call_for_periodic_meter_reading")
initStatus(2, 1, "low_voltage_shutdown_warning")
initStatus(2, 2, "call_for_load_survey")
initStatus(2, 3, "conduct_load_survey")
initStatus(2, 4, "pilot_flame_register")
initStatus(2, 5, "type_of_time_extension")
initStatus(2, 6, "safety_duration")
initStatus(2, 7, "safety_duration_bypass")

---------------------------------------------------------------------------------------------------
-- hdr, cmd, status, Meter Status 0, Meter Status 1, Meter Status 2 (as per "LorRa Meter Protocol")
function Responses.processGetMcMeterStatus(tbl, bytesAfterCmd) 
    local status = {}
    local statusBytes = {}
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        -- Confirmed with Ranga that the status bytes are sent "little endian" ie LS byte first
        statusBytes[2] = tonumber(string.sub(bytesAfterCmd, 7, 8))
        statusBytes[1] = tonumber(string.sub(bytesAfterCmd, 5, 6))
        statusBytes[0] = tonumber(string.sub(bytesAfterCmd, 3, 4))
        for statByte = 0, 2 do
            for statBit = 0, 7 do
                if Responses.statusLabels[statByte][statBit] ~= nil then
                    local theByte = statusBytes[statByte]
                    local label = Responses.statusLabels[statByte][statBit]
                    local shift = bit.rshift(theByte, statBit)
                    local mask = bit.band(shift, 1)
                    if mask == 1 then
                        status[label] = 1
                    else
                        status[label] = 0
                    end
                end
            end
        end
        
        tbl["status"] = json.encode(status) 
    else
        tbl["status"] = ""
    end
    
    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetMcMeterReadingValue(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["reading_value"] =  tonumber( -- TODO:  consider using littleEndianNumToHex
            string.sub(bytesAfterCmd, 9, 10) .. 
            string.sub(bytesAfterCmd, 7, 8)  .. 
            string.sub(bytesAfterCmd, 5, 6)  .. 
            string.sub(bytesAfterCmd, 3, 4), 16)
    else
        tbl["reading_value"] = 0
    end
    
    tbl["timestamp"] = os.time()
    
    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processMicomMeterAlert(respmsg, msgid, payload)
    local BASE = def.ALERT_BASE_MC
    local pIdx = 1
    local MAX_MICOM_ALERT_LEN = 4 
    local MAX_MICOM_ALERT_BITMAP_LEN = 8
    for i =1, MAX_MICOM_ALERT_LEN do
        local alertByte = 0
        alertByte = tonumber(string.sub(payload, pIdx , pIdx + 1), 16)
        pIdx = pIdx + 2
        for j=1,MAX_MICOM_ALERT_BITMAP_LEN do 
            local val = getBitOfPos (alertByte, j) -- TODO: consider using "bit"
            if val == 1 then
                -- Some bits are sent by the NIC but are undefined, so don't send them.
                if loradef.MICOM_ALERT[i] ~= nil and loradef.MICOM_ALERT[i][j] ~= nil then
                    local rsptbl = {}
                    rsptbl["msgid"]         = msgid
                    rsptbl["TYPE"]          = "MS"
                    rsptbl["msgname"]       = def.name[msgid]
                    rsptbl["cid"]           = 0
                    rsptbl["flags"]         = def.FLAG_FRAMETYPE_RESP + def.FLAG_ACK_REQ
                    rsptbl["eid"]           = respmsg["eid"]
                    rsptbl["alert_type"]    = bit.bor(BASE, loradef.MICOM_ALERT[i][j].code)
                    --rsptbl["alert_details"] = loradef.MICOM_ALERT[i][j].detail
                    rsptbl["alert_time"]    = os.time()
                    print("APP => FMS:", rsptbl["msgname"], " EID:", rsptbl["eid"], " alert_details: ", rsptbl["alert_details"])
                    print("Micom Alert: ", string.format("%06X", rsptbl["alert_type"]))
                    fme.sendmessage(def.fmeContext,rsptbl) -- FMS Alert
                end
            end
        end
    end
end
  
---------------------------------------------------------------------------------------------------
-- This function handles alerts from both YL and Micom Meters.
-- alertMeterType determines whether it is YL or MC.
-- bytesAfterCmd:
--  MC:  1 byte
--  YL:  4 bytes
function Responses.processMeterAlert(tbl, bytesAfterCmd, nicmsg)
    --local tbl = LoraUtils.deepcopy(rsptbl)
    local alertMeterType = tonumber(string.sub(bytesAfterCmd, 1, 2), 16)
    local cmd = LoraUtils.getCmdFromResponse(nicmsg["payload"])
    --local msgid = LoraUtils.getMsgidFromNicCmd(cmd)
    local msgid = LoraUtils.getMsgidFromNicCmd(nicmsg["payload"])
    local nibLen = string.len(bytesAfterCmd)
    if alertMeterType == loradef.YUNGLOONG_LORA_ALERT then
        if nibLen == 4 then
            -- Need to prefix old ZB cluster ID to match old alerts
            local alertByte = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
            local alertCode = bit.bor(def.ALERT_BASE_YL, alertByte)
            print("Yung Loong Alert: ", string.format("%06X", alertCode))
            if loradef.YL_ALERT[alertByte] ~= nil then
                tbl["alert_type"]       = alertCode
                -- Turns out this is inserted by FMS
                --tbl["alert_details"]    = loradef.YL_ALERT[alertByte]
            else
                tbl["alert_type"]       = alertCode
                tbl["alert_details"]    = "unknown alert"
            end
            
            tbl["alert_time"] = os.time()            
        else
            print("Error: number of bytes after YL Alert cmd = ", nibLen, " is not 2")
        end            
    elseif alertMeterType == loradef.MICOM_LORA_ALERT then
        if nibLen == 10 then
            tbl = Responses.processMicomMeterAlert(nicmsg, msgid, string.sub(bytesAfterCmd, 3)) -- Just send the micom alert data from payload
        else
            print("Error: number of bytes after Micom Alert cmd = ", nibLen, " is not 5")
        end
    else
        print("Error: alertMeterType = ", alertMeterType, " is unknown")
    end

    --SendAckToLoraDevice(nicmsg["eid"], nicmsg["payload"], loradef.MP_STATUS_SUCCESS)

    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetMeterType(tbl, bytesAfterCmd)
    local data = ""
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        local manufacturerCode = string.sub(bytesAfterCmd, 3, 4)
        local manfStr = ""
        if manufacturerCode == "00" then
            manfStr = "YungLoong"
        elseif manufacturerCode == "01" then
            manfStr = "Micom"
        end
        tbl["manufacturer"] = manfStr
        tbl["model_id"] = tonumber(string.sub(bytesAfterCmd, 5, 6), 16)
    end
    
    return tbl   
end

---------------------------------------------------------------------------------------------------
-- This handles both requested and unrequested meter summation messages coming from the NIC
function Responses.getMeterSummationCommon(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["summation_delivered"] = tonumber(
            string.sub(bytesAfterCmd, 9, 10) .. 
            string.sub(bytesAfterCmd, 7, 8)  .. 
            string.sub(bytesAfterCmd, 5, 6)  .. 
            string.sub(bytesAfterCmd, 3, 4), 16)
    else
        tbl["summation_delivered"] = 0
    end
    
    tbl["timestamp"] = os.time()
    
    return tbl
end

---------------------------------------------------------------------------------------------------
-- This handles a requested meter summation.  In the requested case no ACK is send back to the NIC.
function Responses.processGetMeterSummation(tbl, bytesAfterCmd)
    return Responses.getMeterSummationCommon(tbl, bytesAfterCmd)
end

---------------------------------------------------------------------------------------------------
-- This handles an unrequested (or unsolicited) meter pressure
-- The difference between the requested and unrequested is the latter sends an ACK back to the NIC.
function Responses.processMeterPressureCommon(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        if string.len(bytesAfterCmd) == 10 then
        tbl["current_pressure"] = tonumber(
            string.sub(bytesAfterCmd, 9, 10) .. 
            string.sub(bytesAfterCmd, 7, 8) .. 
            string.sub(bytesAfterCmd, 5, 6) .. 
            string.sub(bytesAfterCmd, 3, 4), 16)
        elseif string.len(bytesAfterCmd) == 6 then
        tbl["current_pressure"] = tonumber(
            string.sub(bytesAfterCmd, 5, 6) .. 
            string.sub(bytesAfterCmd, 3, 4), 16)
        end
    else
        tbl["current_pressure"] = 0
    end
    
    tbl["timestamp"] = os.time()
    
    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetMeterPressure(tbl, bytesAfterCmd)
    return Responses.processMeterPressureCommon(tbl, bytesAfterCmd)
end

---------------------------------------------------------------------------------------------------
function Responses.processGetMeterValveState(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["valve_state"] = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
    else
        tbl["valve_state"] = 0
    end

    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetMeterSummationSchedule(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["report_interval_mins"] = tonumber((string.sub(bytesAfterCmd, 5, 6) .. string.sub(bytesAfterCmd, 3, 4)), 16)
    end
    
    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetNicBatLife(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["battery_milliamp_hours_remaining"] = LoraUtils.leHexToBeNum(string.sub(bytesAfterCmd, 3))
    end
    
    return tbl
end

Responses.buildType = {}
Responses.buildType[0x42] = "STB"
Responses.buildType[0x44] = "DEV"
Responses.buildType[0x47] = "STG"

---------------------------------------------------------------------------------------------------
function Responses.processGetNicVersion(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        local bv = {}
        local av = {}
        bv["major"]    = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
        bv["minor"]    = tonumber(string.sub(bytesAfterCmd, 5, 6), 16)
        bv["build"]    = tonumber(string.sub(bytesAfterCmd, 7, 8), 16)
        bv["type"]     = tonumber(string.sub(bytesAfterCmd, 9, 10), 16)
        local bType = "UNK"
        if Responses.buildType[bv["type"]] ~= nil then
            bType = Responses.buildType[bv["type"]]
        end
        tbl["nic_bootloader_version"] = string.format("%s.%s.%s-%s", bv["major"], bv["minor"], bv["build"], tostring(bType))
        av["major"]     = tonumber(string.sub(bytesAfterCmd, 11, 12), 16)
        av["minor"]     = tonumber(string.sub(bytesAfterCmd, 13, 14), 16)
        av["build"]     = tonumber(string.sub(bytesAfterCmd, 15, 16), 16)
        av["type"]      = tonumber(string.sub(bytesAfterCmd, 17, 18), 16)
        if Responses.buildType[av["type"]] ~= nil then
            bType = Responses.buildType[av["type"]]
        end
        tbl["nic_application_version"] = string.format("%s.%s.%s-%s", av["major"], av["minor"], av["build"], tostring(bType))
    else
        tbl["nic_application_version"] = ""
    end
    
    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetMeterPressureSchedule(tbl, bytesAfterCmd) 
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        if bytesAfterCmd:len() >= 6 then
            tbl["report_interval_mins"] = tonumber((string.sub(bytesAfterCmd, 5, 6) .. string.sub(bytesAfterCmd, 3, 4)), 16)
        end
    else
        tbl["report_interval_mins"] = 0
    end
    
    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlOflowEnable(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["overflow_detect_enable"] = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
    end
    
    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlOflowDuration(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["overflow_detect_duration"] = tonumber(string.sub(bytesAfterCmd, 5, 6) .. string.sub(bytesAfterCmd, 3, 4), 16)
    end

    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlOflowRate(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["overflow_detect_flowrate"] = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
    else
        tbl["overflow_detect_flowrate"] = 0
    end

    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlPressureAlarmLow(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["pressure_alarm_level_low"] = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
    else
        tbl["pressure_alarm_level_low"] = 0
    end

    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlPressureAlarmHigh(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["pressure_alarm_level_high"] = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
    else
        tbl["pressure_alarm_level_high"] = 0
    end

    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlLeakDetectRange(tbl, bytesAfterCmd) 
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["leak_detect_range"] = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
    else
        tbl["leak_detect_range"] = 0
    end
    
    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlManualRecoverEnable(tbl, bytesAfterCmd) 
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["manual_recover_enable"] = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
    else
        tbl["manual_recover_enable"] = 0
    end

    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlFirmwareVersion(tbl, bytesAfterCmd)
    local version = ""
    local i = 3
    local len = 0
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        len = string.len(bytesAfterCmd)
        while i <=len do
            local v = tonumber(string.sub(bytesAfterCmd, i , i+1), 16)
            version = version .. string.char(v)
            i = i + 2
        end

        tbl["version"] = version
    else
        tbl["version"] = "0"
    end
    
    return tbl
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlShutoffcodes(tbl, bytesAfterCmd)
    local shutoffcodes = {}
    local i = 3
    local len = 0
    local j = 1
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        len = string.len ( bytesAfterCmd )
        while i <=len do
            shutoffcodes[j] = {}
            shutoffcodes[j]["code"]  = tonumber(string.sub(bytesAfterCmd, i, i+1), 16)
            i = i + 2
            local tstamp = nil
            tstamp = string.sub(bytesAfterCmd, i , i + 7)  -- 4bytes
            shutoffcodes[j]["timestamp"] = tonumber(
                string.sub(tstamp, 7 , 8)  .. 
                string.sub(tstamp, 5 , 6) .. 
                string.sub(tstamp, 3 , 4) .. 
                string.sub(tstamp, 1,  2), 16)
            i = i + 8
            j = j + 1
        end
        tbl["shutoff_codes"] = json.encode(shutoffcodes )
    else
        tbl["shutoff_codes"] = ""
    end
    
    return tbl 
end

---------------------------------------------------------------------------------------------------
-- Serial number is a 10 byte string, but it's delivered to the app as hex ascii encoded bytes
-- So serial "ABC" => "414243"
function Responses.processGetYlSerialNumber(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        local encodedSerial = string.sub(bytesAfterCmd, 3)
        local serial = ""
        local chr = nil
        while encodedSerial:len() >= 2 do
            chr = string.char(tonumber(encodedSerial:sub(1, 2), 16))
            serial = serial .. chr
            encodedSerial = encodedSerial:sub(3) -- rem 2 hexascii chars
        end
        
        tbl["meter_serial_number"] = serial
    else
        tbl["meter_serial_number"] = ""
    end
    
    return tbl 
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlElecQtyVal(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        local valueStr = string.sub(bytesAfterCmd, 5, 6) .. string.sub(bytesAfterCmd, 3, 4)
        tbl["electric_quantity_value"] = tonumber(valueStr, 16)
    else
        tbl["electric_quantity_value"] = ""
    end 

    return tbl 
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlGetCommsMode(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["meter_comms_mode"] = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
    else
        tbl["meter_comms_mode"] = 0
    end 
    
    return tbl 
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlGetPilotLightMode(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["pilot_light_mode"] = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
        tbl["pilot_flow_min"]   = tonumber(string.sub(bytesAfterCmd, 5, 6), 16)
        tbl["pilot_flow_max"]   = tonumber(string.sub(bytesAfterCmd, 7, 8), 16)
    else
        tbl["pilot_light_mode"] = ""
        tbl["pilot_light_min"]  = ""
        tbl["pilot_light_max"]  = ""
    end
    
    return tbl 
end

---------------------------------------------------------------------------------------------------
function Responses.processGetYlEarthquakeSensorState(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["earthquake_sensor_state"] = tonumber(string.sub(bytesAfterCmd, 3, 4), 16)
    else
        tbl["earthquake_sensor_state"] = ""
    end 
    
    return tbl 
end

---------------------------------------------------------------------------------------------------
-- what arrives here as payload are hexascii bytes eg: "004142", where 00 is the status, and
-- "4142" are hexascii rep'n of character byte codes.  0x41 => "A", 0x42 = "B".
function Responses.processGetMcGetProtocolVersion(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        local msc = string.char(tonumber(string.sub(bytesAfterCmd, 3, 4), 16))
        local lsc = string.char(tonumber(string.sub(bytesAfterCmd, 5, 6), 16))
        tbl["protocol_version"] = msc .. lsc
    else
        tbl["protocol_version"] = ""
    end 
    
    return tbl 
end


---------------------------------------------------------------------------------------------------
local initMsg = function(name, msgid, params)
    table.sort(def.msgid)
    def.msgid[name] = msgid
    def.name[msgid] = name
    loradef.resParams[msgid] = params
end

function Responses.processSetNicTime(tbl, bytesAfterCmd)    
    --return tbl 
end

function Responses.processGetNicTime(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        --tbl["nic_time"] = tonumber(string.sub(bytesAfterCmd, 5, 12), 16)
        tbl["nic_time"] = tonumber(LoraUtils.leHexToBeHex(string.sub(bytesAfterCmd, 3, 10)),16)
    else
        tbl["nic_time"] = ""
    end 
    
    return tbl 
end


function Responses.processGetNicSchedule(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["day_mask"]                 = tonumber(string.sub(bytesAfterCmd, 3, 4),16)
        tbl["active_period_start_time"] = tonumber(string.sub(bytesAfterCmd, 5, 6),16)
        tbl["active_period_end_time"]   = tonumber(string.sub(bytesAfterCmd, 7, 8),16)
        tbl["modes"]                    = tonumber(string.sub(bytesAfterCmd, 9, 10),16)
    end 
    
    return tbl 
end

function Responses.processSetNicSchedule(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["day_mask"]                 = tonumber(string.sub(bytesAfterCmd, 3, 4),  16)
        tbl["active_period_start_time"] = tonumber(string.sub(bytesAfterCmd, 5, 6),  16)
        tbl["active_period_end_time"]   = tonumber(string.sub(bytesAfterCmd, 7, 8),  16)
        tbl["modes"]                    = tonumber(string.sub(bytesAfterCmd, 9, 10), 16)
    end
    
    return tbl 
end

function Responses.processGetNicMode(tbl, bytesAfterCmd)
    if tbl["result_code"] == loradef.MP_STATUS_SUCCESS then
        tbl["mode_id"]                = tonumber(string.sub(bytesAfterCmd, 3,  4 ),  16)
        tbl["MAC_polling_interval"]   = tonumber(LoraUtils.leHexToBeHex(string.sub(bytesAfterCmd, 5,  12)),  16)
        tbl["spreadFactor_confirmation"]       = tonumber(string.sub(bytesAfterCmd, 13, 14),  16)
    end 
    
    return tbl 
end


function Responses.processSetMeterSerialNumber(tbl, bytesAfterCmd)    
    return tbl 
end

function Responses.processSetMcMeterCustIdRsp(tbl, bytesAfterCmd)    
    return tbl 
end

--initMsg("GET_NIC_VERSION",            13, { 1, "nic_bootloader_version", "uint32", 8, "nic_application_version", "string" })
--initMsg("GET_METER_NIC_LIFE",   14, nil)
initMsg("SET_NIC_BATTERY_LIFE",   15, { 1, "battery_milliamp_hours_remaining", 2 })
---------------------------------------------------------------------------------------------------
--
---------------------------------------------------------------------------------------------------

Responses.processRsp = {}

-- Common Commands
Responses.processRsp[def.msgid.METER_SUMMATION_DELIVERED]       = Responses.processGetMeterSummation
Responses.processRsp[def.msgid.METER_CURRENT_PRESSURE]          = Responses.processGetMeterPressure
Responses.processRsp[def.msgid.METER_ALERT]                     = Responses.processMeterAlert
Responses.processRsp[def.msgid.GET_METER_TYPE]                  = Responses.processGetMeterType
Responses.processRsp[def.msgid.GET_METER_SUMMATION_DELIVERED]   = Responses.processGetMeterSummation
Responses.processRsp[def.msgid.GET_METER_CURRENT_PRESSURE]      = Responses.processGetMeterPressure
Responses.processRsp[def.msgid.GET_METER_GAS_VALVE_STATE]       = Responses.processGetMeterValveState
Responses.processRsp[def.msgid.GET_SUMMATION_REPORT_INTERVAL]   = Responses.processGetMeterSummationSchedule
Responses.processRsp[def.msgid.GET_PRESSURE_REPORT_INTERVAL]    = Responses.processGetMeterPressureSchedule
Responses.processRsp[def.msgid.GET_NIC_VERSION]                 = Responses.processGetNicVersion
Responses.processRsp[def.msgid.GET_NIC_BATTERY_LIFE]            = Responses.processGetNicBatLife
Responses.processRsp[def.msgid.SET_NIC_TIME_CORRECTION]         = Responses.processSetNicTime
Responses.processRsp[def.msgid.GET_NIC_TIME]                    = Responses.processGetNicTime
Responses.processRsp[def.msgid.GET_NIC_SCHEDULE]                = Responses.processGetNicSchedule
Responses.processRsp[def.msgid.SET_NIC_SCHEDULE]                = Responses.processSetNicSchedule
Responses.processRsp[def.msgid.GET_NIC_MODE]                    = Responses.processGetNicMode
Responses.processRsp[def.msgid.SET_NIC_MODE]                    = Responses.processSetNicMode

-- Yungloong commands
Responses.processRsp[def.msgid.GET_OFLOW_DETECT_ENABLE]         = Responses.processGetYlOflowEnable
Responses.processRsp[def.msgid.GET_OFLOW_DETECT_DURATION]       = Responses.processGetYlOflowDuration
Responses.processRsp[def.msgid.GET_OFLOW_DETECT_RATE]           = Responses.processGetYlOflowRate
Responses.processRsp[def.msgid.GET_PRESSURE_ALARM_LEVEL_LOW]    = Responses.processGetYlPressureAlarmLow
Responses.processRsp[def.msgid.GET_PRESSURE_ALARM_LEVEL_HIGH]   = Responses.processGetYlPressureAlarmHigh
Responses.processRsp[def.msgid.GET_LEAK_DETECT_RANGE]           = Responses.processGetYlLeakDetectRange
Responses.processRsp[def.msgid.GET_MANUAL_RECOVER_ENABLE]       = Responses.processGetYlManualRecoverEnable
Responses.processRsp[def.msgid.GET_METER_FIRMWARE_VERSION]      = Responses.processGetYlFirmwareVersion
Responses.processRsp[def.msgid.GET_METER_SHUTOFF_CODES]         = Responses.processGetYlShutoffcodes
Responses.processRsp[def.msgid.GET_METER_SERIAL_NUMBER]         = Responses.processGetYlSerialNumber
Responses.processRsp[def.msgid.GET_ELECTRIC_QNT_VALUE]          = Responses.processGetYlElecQtyVal
Responses.processRsp[def.msgid.GET_COMMS_MODE]                  = Responses.processGetYlGetCommsMode
Responses.processRsp[def.msgid.GET_PILOT_LIGHT_MODE]            = Responses.processGetYlGetPilotLightMode
Responses.processRsp[def.msgid.GET_EARTHQUAKE_SENSOR_STATE]     = Responses.processGetYlEarthquakeSensorState
Responses.processRsp[def.msgid.GET_PROTOCOL_VERSION]            = Responses.processGetMcGetProtocolVersion
Responses.processRsp[def.msgid.SET_METER_SERIAL_NUMBER]         = Responses.processSetMeterSerialNumber

-- Micom commands
Responses.processRsp[def.msgid.GET_METER_READING_VALUE]         = Responses.processGetMcMeterReadingValue        
Responses.processRsp[def.msgid.GET_METER_STATUS]                = Responses.processGetMcMeterStatus
Responses.processRsp[def.msgid.GET_METER_CUSTOMERID]            = Responses.processGetMcMeterCustIdRsp
Responses.processRsp[def.msgid.SET_METER_CUSTOMERID]            = Responses.processSetMcMeterCustIdRsp
Responses.processRsp[def.msgid.GET_METER_TIME]                  = Responses.processGetMcMeterTime

return Responses
