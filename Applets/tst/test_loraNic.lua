-- --------------------------------------------------------------------------------------------
-- Purpose: Simple behavioural model of a LoRa NIC for Unit Testing purposes.
--
-- Details: Uses loraNicData "object" to store that written/read values.
--
-- Copyright Statement:
-- Copyright © 2016 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored,
-- transcribed in an information retrieval system, translated into -- any language, or transmitted
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise,
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
-- --------------------------------------------------------------------------------------------

local def       = require "src.defines"
local fme       = require(def.module.fme)
local loradef   = require("src.loradef")
local device    = require("src.device")
local data      = require("tst.test_loraNicData")
local frag      = require("src.fragmentedMessage")
local FragMgr   = require("src.FragmentedMessageMgr")
local bit       = require("bit")

require("src.lorautils")

local LoraNic = {} -- table storing the functions performing device operations

---------------------------------------------------------------------------------------------------
LoraNic.new = function(fme, eid)
    local self = {}
    
    self.status = 0
    self.fme = fme
    self.eid = eid
    self.data = data.new()
    self.pktId = 0
 
    self.battery = {}
    self.version = {}
    self.summation = {}
    self.summation.schedule = {}
    self.pressure = {}
    self.pressure.schedule = {}
    self.custid = {}
    self.serial = {}

    ---------------------------------------------------------------------------------------------------
    self.toReverseHexAsciiBytes = function(number, numChars)
        local formatStr = "%0" .. tostring(numChars) .. "x"
        local hexAscii = string.format(formatStr, number)
        local revHexAscii = ""
        for idx = string.len(hexAscii), 1, -2 do
            revHexAscii = revHexAscii .. string.sub(hexAscii, idx-1, idx)
        end
        
        return revHexAscii
    end

    ---------------------------------------------------------------------------------------------------
    -- Used to generate TIDs for spontaneously generated messages
    self.getNextPktId = function()
        if self.pktId > 0x1F then
            self.pktId = 0
        end

        return self.pktId
    end
 
    ---------------------------------------------------------------------------------------------------
    -- Used to generate TIDs for spontaneously generated messages
    self.mkMeterSumDeliveredPayload = function(summation, evtCtr)
        local revSum = self.toReverseHexAsciiBytes(summation, 8)
        local readingByte = string.format("%02x", bit.lshift(evtCtr, 6))
        local timeDiff = 655
        local timeAtNic = string.sub(string.format("%x",(os.time() + timeDiff)),1,6) 
        --for testing purpose
        timeAtNic = "67be5959"  
        return revSum .. readingByte .. timeAtNic
    end
 
    ---------------------------------------------------------------------------------------------------
    self.serial.getValueHex = function()
        local value = self.data.getParam("serial", "value")

        return LoraUtils.stringToHexAscii(value)
    end

    ---------------------------------------------------------------------------------------------------
    self.getElecQ = function()
        return "2008"
    end
    ---------------------------------------------------------------------------------------------------

    self.getNicSchedule = function()
        return "045F011C"
    end
    ---------------------------------------------------------------------------------------------------

    self.getNicMode = function()
        return "010403020101"
    end

    ---------------------------------------------------------------------------------------------------
    self.getCommsMode = function()
        return "69"
    end

    ---------------------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------------------
    self.getPilotLightMode = function()
        return "010203"
    end

    ---------------------------------------------------------------------------------------------------
    self.getEarthquake = function()
        return "33"
    end

    ---------------------------------------------------------------------------------------------------
    self.getStatus = function()
        local status = self.data.status
        local leHexStatus = LoraUtils.littleEndianNumToHex(status, 3)
        return leHexStatus
    end

    ---------------------------------------------------------------------------------------------------
    self.getType = function()
        local YL_TYPE_DATA = "0000"
        local MC_TYPE_DATA = "010F"
        return MC_TYPE_DATA
    end

    ---------------------------------------------------------------------------------------------------
    self.enable = 1
    self.getOflowEnable = function()
        if self.enable == 1 then
            self.enable = 0
        else
            self.enable = 1
        end
        return string.format("%02x", self.enable)
    end

    ---------------------------------------------------------------------------------------------------
    self.flowDuration = 1
    self.getOflowDuration = function()
        self.flowDuration = self.flowDuration + 1
        
        return string.format("%04x", self.flowDuration)
    end

    ---------------------------------------------------------------------------------------------------
    self.getCustId = function()
        local customerId = "01234567891234"
        local customerIdHex = LoraUtils.stringToHexAscii(customerId)
        return customerIdHex
    end

    ---------------------------------------------------------------------------------------------------
    self.getMCProtocol = function()
        return string.format("%02x%02x", string.byte("A"), string.byte("B"))
    end

    ---------------------------------------------------------------------------------------------------
    self.summation.getValueHex = function()
        local value = self.data.getParam("summation", "value")
        local valueHex = LoraUtils.littleEndianNumToHex(value, 4)
        -- Now increase the summation value
        self.data.setParam("summation", "value", value + 3)

        return valueHex
    end

    ---------------------------------------------------------------------------------------------------
    self.battery.getValueHex = function()
        local value = self.data.getParam("battery", "life")
        local valueHex = LoraUtils.littleEndianNumToHex(value, 2)

        return valueHex
    end

    ---------------------------------------------------------------------------------------------------
    self.version.getValueHex = function()
        local value = self.data.getParam("version", "value")
        local valueHex = LoraUtils.littleEndianNumToHex(value, 8)

        return valueHex
    end

    ---------------------------------------------------------------------------------------------------
    self.summation.schedule.getValueHex = function()
        local schedule = self.data.getParam("summation", "schedule", "value")
        return LoraUtils.littleEndianNumToHex(schedule, 2)
    end

    ---------------------------------------------------------------------------------------------------
    self.summation.schedule.setValueHex = function(hexValue)
        self.data.setParam("summation", "schedule", "value", hexValue)
        
        return ""
    end

    ---------------------------------------------------------------------------------------------------
    self.setSerial = function(hexValue)
        local serialStr = LoraUtils.hexAsciiToString(hexValue)
        print("NIC:  serial number set to \"" .. serialStr .. "\"")
        
        return ""
    end

    ---------------------------------------------------------------------------------------------------
    self.pressure.getValueHex = function()
        local value = self.data.getParam("pressure", "value")
        local valueHex = LoraUtils.littleEndianNumToHex(value, 4)
        -- Now increase the value
        self.data.setParam("pressure", "value", value + 5)
        
        print("NIC: current pressure = ", value)

        return valueHex
    end

    ---------------------------------------------------------------------------------------------------
    self.pressure.schedule.getValueHex = function()
        local value = self.data.getParam("pressure", "schedule", "value")
        --return LoraUtils.littleEndianNumToHex(value, 2)
        return "0f0a"
    end 
 
     ---------------------------------------------------------------------------------------------------
    self.custid.getValueHex = function()
        return self.data.getParam("custid", "value")
    end 
 
    ---------------------------------------------------------------------------------------------------
    self.processIncomingNicMsg = function(cmdByte, wholeMsg)
        local payload = ""
        if wholeMsg:len() > 4 then
            payload = wholeMsg:sub(5)
        end
        local endpoint, pktId, cmd = self.extractHeaderParams(wholeMsg)
        local msgid = cmd + (endpoint * 100 )
        local data = ""
        
        -- If no function is defined the response is just hdr + cmd + status
        if self.commandFunc[msgid] ~= nil then
            data = self.commandFunc[msgid](payload)
        end
        
        return data
    end 
 
    ---------------------------------------------------------------------------------------------------
    self.extractHeaderParams = function(wholePkt)
        local prefixStr = string.sub(wholePkt, 1, 2)
        local prefix    = tonumber(prefixStr, 16)
        local endpoint  = bit.rshift(bit.band(prefix, 0xE0), 5)
        local pktId     = bit.band(prefix, 0x1F)
        local cmdStr    = string.sub(wholePkt, 3, 4)
        local cmd       = tonumber(cmdStr, 16)
        
        return endpoint, pktId, cmd
    end
 
    self.firstFragId = nil
 
    ---------------------------------------------------------------------------------------------------
    -- Take in a sent Lora message and formulate a response
    self.handleLoraMessage = function(msg)
        local wholePkt = msg["payload"]
        local isFragment, isCompleteMsg, wholeMsg = self.fragMgr.handleFragmentMsg(wholePkt)
        local endpoint, pktId, cmd = self.extractHeaderParams(wholeMsg)
        if isFragment and self.firstFragId == nil then
            self.firstFragId = pktId
        end
        
        if isCompleteMsg then
            local rspPayload = self.processIncomingNicMsg(cmd, wholeMsg)
            local eid = msg["eid"]
            self.pushLoraResponse(eid, endpoint, pktId, cmd, rspPayload)
            self.firstFragId = nil
        end
    end
 
    ---------------------------------------------------------------------------------------------------
    -- Responses from the NIC have a 3 byte preamble:  ep/tid, cmd, status bytes.
    self.rspPayloadBelowFragLimit = function(hexasciiPayload)
        local below = true
        if hexasciiPayload ~= nil then
            below = (string.len(hexasciiPayload)/2) + 3 <= frag.PKT_BYTES_MAX
        end
        
        return below
    end
 
    ---------------------------------------------------------------------------------------------------
    self.getPktId = function()
        return self.tid
    end
    
    ---------------------------------------------------------------------------------------------------
    self.pushLoraResponse = function(eid, endpoint, rxPktId, cmd, rspPayload)
        local msg = {}
        msg["TYPE"]     = "L1"
        msg["eid"]      = eid
        if self.rspPayloadBelowFragLimit(rspPayload) then
            msg["payload"] = LoraUtils.mkRspPkt(endpoint, rxPktId, cmd, self.status, rspPayload)
            self.fme.sim.push(msg)
        else
            local statusStr = string.format("%02x", self.status)
            -- Send all the fragments back with the same pktId
            self.tid = rxPktId
            local fragments = self.fragMgr.makeTxFrags(self.getPktId, endpoint, cmd, statusStr .. rspPayload)
            local index = 1
            while fragments[index] ~= nil do             
                msg["payload"]  = fragments[index]
                self.fme.sim.push(msg)
                print("App<=NIC: ", self.eid, " ", fragments[index], " NIC emulator pushed fragment to queue")
                index = index + 1
            end
        end
    end

    ---------------------------------------------------------------------------------------------------
    self.getNicTime     = function()
        local timeVar   = os.time()
        --local nic_time  = string.format("%08x",timeVar)
        local nic_time  = LoraUtils.littleEndianNumToHex(timeVar,4)
        return nic_time
    end

    self.getNicVersion     = function()
        local status                   = "00"
        local nic_bootloader_version   = "01007747"
        local nic_application_version  = "01007747"
        local rsp_payload              = status .. nic_bootloader_version .. nic_application_version
        
        return rsp_payload
    end
    
    self.getNicSchedule     = function()
        return "3e244444"
    end
    
    self.getNicBatteryLife     = function()
        local status                   = "00"
        local battery_milliamp_hours_remaining   = "0201"
        local rsp_payload              = status .. battery_milliamp_hours_remaining
        
        return rsp_payload
    end

    -- Note that although it is the NIC command that is received, that cmd is translated
    -- into the corresponding FMS side msgid because that is what we have defines for.
    self.commandFunc = {}
    self.commandFunc[def.msgid.GET_METER_SUMMATION_DELIVERED]    = self.summation.getValueHex
    self.commandFunc[def.msgid.GET_SUMMATION_REPORT_INTERVAL]    = self.summation.schedule.getValueHex 
    self.commandFunc[def.msgid.SET_SUMMATION_REPORT_INTERVAL]    = self.summation.schedule.setValueHex 
    self.commandFunc[def.msgid.GET_METER_CURRENT_PRESSURE]       = self.pressure.getValueHex
    self.commandFunc[def.msgid.GET_PRESSURE_REPORT_INTERVAL]     = self.pressure.schedule.getValueHex
    self.commandFunc[def.msgid.GET_METER_SERIAL_NUMBER]          = self.serial.setValueHex
    self.commandFunc[def.msgid.SET_METER_SERIAL_NUMBER]          = self.setSerial
    self.commandFunc[def.msgid.GET_ELECTRIC_QNT_VALUE]           = self.getElecQ
    self.commandFunc[def.msgid.GET_COMMS_MODE]                   = self.getCommsMode
    self.commandFunc[def.msgid.GET_PILOT_LIGHT_MODE]             = self.getPilotLightMode
    self.commandFunc[def.msgid.GET_EARTHQUAKE_SENSOR_STATE]      = self.getEarthquake
    self.commandFunc[def.msgid.GET_PROTOCOL_VERSION]             = self.getMCProtocol
    self.commandFunc[def.msgid.SET_METER_STATUS]                 = self.setStatus
    self.commandFunc[def.msgid.GET_METER_STATUS]                 = self.getStatus
    self.commandFunc[def.msgid.GET_METER_TYPE]                   = self.getType
    self.commandFunc[def.msgid.GET_OFLOW_DETECT_ENABLE]          = self.getOflowEnable
    self.commandFunc[def.msgid.GET_OFLOW_DETECT_DURATION]        = self.getOflowDuration
    self.commandFunc[def.msgid.GET_METER_CUSTOMERID]             = self.getCustId
    self.commandFunc[def.msgid.SET_NIC_TIME_CORRECTION]          = self.setNicTimeCorrection
    self.commandFunc[def.msgid.GET_NIC_TIME]                     = self.getNicTime
    self.commandFunc[def.msgid.GET_NIC_VERSION]                  = self.getNicVersion
    self.commandFunc[def.msgid.GET_NIC_SCHEDULE]                 = self.getNicSchedule
    self.commandFunc[def.msgid.SET_NIC_SCHEDULE]                 = self.setNicSchedule
    self.commandFunc[def.msgid.GET_NIC_MODE]                     = self.getNicMode
    self.commandFunc[def.msgid.SET_NIC_MODE]                     = self.setNicMode
    self.commandFunc[def.msgid.GET_NIC_BATTERY_LIFE]             = self.getNicBatteryLife
    self.commandFunc[def.msgid.SET_METER_CUSTOMERID]             = self.setMeterCustomerID
    
    self.dataDef = {}                   -- table path,                  type,       bytes,   default value
    self.dataDef["summation.value"]     = {"summation.value",           "uint32",   4,      0}
    self.dataDef["summation.schedule"]  = {"summation.schedule.value",  "uint32",   2,      0}
    self.dataDef["pressure.value"]      = {"pressure.value",            "uint32",   4,      0}
    self.dataDef["pressure.schedule"]   = {"pressure.schedule.value",   "uint32",   2,      0}
    self.dataDef["pressure.alarms.low"] = {"pressure.alarms.low",       "uint32",   1,      0}
    
    self.getValTab = {}                                                  
    --self.getValTab[def.msgid.GET_METER_SUMMATION_DELIVERED]    = self.dataDef["summation.value"]
    --self.getValTab[def.msgid.GET_SUMMATION_REPORT_INTERVAL]     = self.dataDef["summation.schedule"]
    self.getValTab[def.msgid.GET_METER_CURRENT_PRESSURE]       = self.dataDef["pressure.value"]
    self.getValTab[def.msgid.GET_PRESSURE_REPORT_INTERVAL]      = self.dataDef["pressure.schedule"]
    self.getValTab[def.msgid.GET_PRESSURE_ALARM_LEVEL_LOW]  = self.dataDef["pressure.alarms.low"]
    self.getValTab[def.msgid.GET_PRESSURE_ALARM_LEVEL_HIGH] = self.dataDef["pressure.alarms.high"]   
    --[[
    self.getValTab[def.msgid.GET_METER_CUSTOMERID]         = "custid"
    self.getValTab[def.msgid.GET_NIC_BATTERY_LIFE]         = "nic.battery.life"
    self.getValTab[def.msgid.GET_NIC_VERSION]                  = "nic.version"
    self.getValTab[def.msgid.GET_METER_GAS_VALVE_STATE]        = "valve.state"
    self.getValTab[def.msgid.GET_OFLOW_DETECT_ENABLE]       = "oflow.detect.enable"
    self.getValTab[def.msgid.GET_OFLOW_DETECT_DURATION]     = "oflow.detect.duration"
    self.getValTab[def.msgid.GET_OFLOW_DETECT_RATE]         = "oflow.detect.rate"
    self.getValTab[def.msgid.GET_LEAK_DETECT_RANGE]         = "oflow.detect.range"
    self.getValTab[def.msgid.GET_MANUAL_RECOVER_ENABLE]     = "manual.recoverenable"
    self.getValTab[def.msgid.GET_METER_FIRMWARE_VERSION]          = "nic.firmware.version"
    self.getValTab[def.msgid.GET_METER_SHUTOFF_CODES]        = "shutoff.codes"
    self.getValTab[def.msgid.GET_METER_SERIAL_NUMBER]             = "serial.number"
    self.getValTab[def.msgid.GET_ELECTRIC_QNT_VALUE]   = "electricq.value"
    self.getValTab[def.msgid.GET_COMMS_MODE]                = "comms.mode"
    self.getValTab[def.msgid.GET_PILOT_LIGHT_MODE]          = "pilotlight.mode"   
    self.getValTab[def.msgid.GET_EARTHQUAKE_SENSOR_STATE]   = "earthquake.state"
    self.getValTab[def.msgid.GET_METER_READING_VALUE]       = "mc.meter.reading"
    self.getValTab[def.msgid.GET_METER_STATUS]              = "mc.meter.status"
    self.getValTab[def.msgid.GET_METER_CUSTOMERID]         = "mc.meter.custid"   
    self.getValTab[def.msgid.GET_METER_TYPE]                   = "meter.type"
    self.getValTab[def.msgid.GET_METER_TIME]                = "mc.meter.time"
    self.getValTab[def.msgid.GET_PROTOCOL_VERSION]          = "mc.protocol.version"
    self.getValTab[def.msgid.GET_COMMS_MODE]                = "YL.comms.mode"
    self.getValTab[def.msgid.GET_PILOT_LIGHT_MODE]          = "YL.pilotlight.mode"
    ]]--
 
    self.initData = function(msgid, index)
        self.getValTab[msgid] = self.dataDef[index]
        self.data.set(self.dataDef[index])
    end
 
    self.initData(def.msgid.GET_METER_SUMMATION_DELIVERED,      "summation.value")
    self.initData(def.msgid.GET_SUMMATION_REPORT_INTERVAL,       "summation.schedule")
    self.initData(def.msgid.GET_METER_CURRENT_PRESSURE,         "pressure.value")
    self.initData(def.msgid.GET_PRESSURE_ALARM_LEVEL_LOW,    "pressure.alarms.low")
    
    --self.setValTab[def.msgid.SET_PRESSURE_REPORT_INTERVAL]      = "pressure.schedule"
    --self.setValTab[def.msgid.SET_SUMMATION_REPORT_INTERVAL]     = "summation.schedule"
 
     ---------------------------------------------------------------------------------------------------
     --[[
    self.processIncomingNicMsgNew = function(cmdByte)
        --local valueHex = string.format("%02x", self.status)
        local msgid = LoraUtils.getMsgidFromNicCmd(cmdByte)
        local data = ""
        
        if self.getValTab[msgid] ~= nil then
            data = self.data.get(self.getValTab[msgid])
        end
        
        return data
    end 
    --]]
    --self.processIncomingNicMsgNew(4)
 
 --[[
 T.msgid.SET_CONFIG_DISABLE_CENTER_SHUTDOWN   = 61
 T.msgid.SET_CONFIG_CENTER_SHUTDOWN           = 60   
 T.msgid.SET_METER_CUSTOMERID                = 53   
 T.msgid.SET_METER_STATUS                     = 51 
 T.msgid.SET_METER_TIME                       = 59   
 T.msgid.SET_METER_READING_VALUE              = 49  
 T.msgid.SET_EARTHQUAKE_SENSOR_STATE          = 72
 T.msgid.SET_PILOT_LIGHT_MODE                 = 70
 T.msgid.SET_MANUAL_RECOVER_ENABLE      = 45
 T.msgid.SET_LEAK_DETECT_RANGE          = 43
 T.msgid.SET_PRESSURE_ALARM_LEVEL_HIGH  = 41
T.msgid.SET_COMMS_MODE                       = 68 
T.msgid.SET_PRESSURE_ALARM_LEVEL_LOW   = 39 
 T.msgid.SET_METER_SERIAL_NUMBER                    = 65
T.msgid.SET_OFLOW_DETECT_RATE          = 37 
 T.msgid.SET_OFLOW_DETECT_DURATION      = 35
T.msgid.SET_OFLOW_DETECT_ENABLE        = 33 
 
  T.msgid.METER_ALERT                   = 1
T.msgid.SET_METER_GAS_VALVE_STATE     = 8
T.msgid.SET_NIC_BATTERY_LIFE        = 15
 ]]--
 
    self.fragMgr = FragMgr.new(self.getNextPktId)
 
    return self
end

return LoraNic

