---------------------------------------------------------------------------------------------------
-- Purpose: Abstract Device class
--
-- Author:  Alan Barker
--
-- Details: An instance of this is created by DeviceMgr when a new device is discovered, and placed into 
--          a list.
--         It:
--            * holds device data, 
--            * accepts incoming FCP and remote device messages and passes them to the appropriate handler
--            * maintains and monitors list of outstanding FCP messages
--            * times out FCP messages without responses
--
-- Copyright Statement:
-- Copyright © 2015 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored, 
-- transcribed in an information retrieval system, translated into any language, or transmitted 
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise, 
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
---------------------------------------------------------------------------------------------------

local def       = require("src.defines")
local fme       = require(def.module.fme)
local loradef   = require("src.loradef")
local responses = require(def.module.responses)
local bit       = require("bit")
local FragMgr   = require("src.FragmentedMessageMgr")
--local utils     = require("lib.fs-utils.fs-gp-utils")

require("src.lorautils")

local Device = {}
Device.PAYLOAD_IDX_START = 5
Device.tid = 0
Device.timeCorrectionThreshold = 120

---------------------------------------------------------------------------------------------------
-- Get the next pachet id for this device
Device.getNextPktId = function()
    Device.tid  = Device.tid + 1
    if Device.tid >= 32 then
        Device.tid = 0
    end

    return Device.tid
end

---------------------------------------------------------------------------------------------------
Device.new = function(context, eid)
    local self      = {}
    self.context    = context
    self.eid        = eid
    self.tid        = 0
    self.requests   = {}
    self.lastNicMsg = ""
    self.lastSumEvt = ""
    self.last       = {}
    self.last.cmd   = "NULL"
    self.counterMSD = 0     -- this counts number of METER_SUMMATION_DELIVERED msg 
    print("New device ", eid)

    self.fragMgr   = FragMgr.new(Device.getNextPktId)

    -----------------------------------------------------------------------------------------------
    -- hdr, cmd, mask(3), status(3)
    self.processSetMcMeterStatusReq = function(msg, payload)
        local loc = msg["location"]
        if loradef.SET_MICOM_METERSTATUS_MASK[loc] ~= nil then
            local val = msg["value"] 
            payload = payload .. loradef.SET_MICOM_METERSTATUS_MASK[loc]
            if val == 1 then
                payload = payload .. loradef.SET_MICOM_METERSTATUS_MASK[loc]
            elseif val == 0 then
                payload = payload .."000000"
            else
                -- TODO:  this is an error:  report to FMS ?
            end
        end

        return payload
    end

    ---------------------------------------------------------------------------------------------------
    self.processSetMcMeterCustIdReq = function(msg)
        local txfrags, firstPktId, seq
        local custId = LoraUtils.trim(msg["customer_id"]) -- remove whitespace
        if custId:len() == 14 then
            local custIdHex = LoraUtils.stringToHexAscii(custId)
            local reqmsg = {}
            reqmsg["TYPE"]      = "L1"        
            reqmsg["msgid"]     = msg["msgid"]
            reqmsg["msgname"]   = msg["msgname"]
            reqmsg["eid"]       = msg["eid"]
            reqmsg["cid"]       = msg["cid"]
            reqmsg["payload"]   = custId
            txfrags, firstPktId, seq = self.fragMgr.sendAsFragments(reqmsg, custIdHex)
        else
            local err = "Error: customer_id not 14 chars"
            print(err)
            msg["result_code"] = def.RESPONSE_ANYERR
            msg["error_details"] = err
            fme.sendmessage(def.fmeContext, msg)
        end

        return txfrags, firstPktId, seq
    end

    ---------------------------------------------------------------------------------------------------
    -- Serial number is received from the FMS as a string.
    -- Must be converted to an array of hexascii bytes for transmission.
    self.processSetYLSetSerialNumReq = function(reqmsg)
        print("meter_serial_number (before enc) :   ",reqmsg["meter_serial_number"])
        local serial = LoraUtils.trim(reqmsg["meter_serial_number"])
        if serial:len() > 14 then -- TODO:  probably shoud send en error message to the FMS
            serial = string.sub(serial, 1, 14)
        end
        local encSerial = ""
        local chrByte
        while serial:len() > 0 do
            chrByte = string.byte(serial:sub(1,1))
            encSerial = encSerial .. string.format("%02x", chrByte)
            serial = serial:sub(2) -- chop off 1st char
        end
        print("meter_serial_number (after enc)  :   ",encSerial)
        return self.fragMgr.sendAsFragments(reqmsg, encSerial)
    end

    ---------------------------------------------------------------------------------------------------
    self.addParams = function (msg, payload)
        local params = loradef.reqParams[msg["msgid"]][1]
        local paramIdx = 2
        for i=1, params do
            local paramname = loradef.reqParams[msg["msgid"]][paramIdx]
            local pval  = msg[paramname]
            local plen  = loradef.reqParams[msg["msgid"]][paramIdx + 1]
            if plen == 1 then
                payload = payload .. string.format ( "%02x",pval )
            elseif plen == 2 then   
                local rval = string.format ("%04x",pval )
                payload = payload .. string.sub (rval, 3, 4) .. string.sub (rval, 1, 2)
            elseif  plen == 4 then
                local rval = string.format ("%08x", pval )
                payload = payload .. string.sub (rval, 7, 8) .. string.sub (rval, 5, 6) .. string.sub (rval, 3, 4) .. string.sub (rval, 1, 2) 
            else
                payload = payload .. string.format("%x", pval)
            end

            paramIdx = paramIdx + 2
        end

        return msg, payload
    end

    ---------------------------------------------------------------------------------------------------
    self.processLoraRequest = function(msg)
        local eid   = msg["eid"]
        local cid   = msg["cid"]
        local msgid = msg["msgid"]
        local msgname = msg["msgname"]
        print("FMS=>App:", msgname, " EID ", eid)
        LoraUtils.printTable(msg)
        local payload = ""

        -- Construct Header
        -- Generate a transaction id (tid) number
        -- Note that if the message is fragmented, tid and payload are constructed again,
        -- a side effect of not quite cleaning up some rather ugly code inherited from someone else.
        local tid = Device.getNextPktId()
        if loradef.endpoint[msgname] ~= nil then
            payload = payload .. string.format("%02x", (tid + loradef.endpoint[msgname])) -- TODO: Review ???
        else
            print("FMS=>App: Endpoint for ", msgname, "not declared")
        end        

        -- Construct Meter payload
        -- Generate the command
        -- check the request has any params .
        local cmd = LoraUtils.msgidToNicCmd(msgid)
        payload = payload .. string.format("%02x", cmd)

        if msg["msgname"] == "SET_SUMMATION_REPORT_INTERVAL" then
            if msg["report_interval_mins"] == nil then
                -- TODO: send err resp to FMS
                print("Error: missing param - bail")
                return
            end
        end

        if msg["msgname"] == "SET_PRESSURE_REPORT_INTERVAL" then
            if msg["report_interval_mins"] == nil then
                -- TODO: send err resp to FMS
                print("Error: missing param - bail")
                return
            end
        end
        
        if msg["msgname"]     == "SET_METER_CUSTOMERID" then
            local txfrags, firstPktId, seq = self.processSetMcMeterCustIdReq(msg) -- a fragmented message
            if txfrags ~= nil then
                self.addReqMessage(cid, firstPktId, cmd, msg, payload)
            end
        elseif msg["msgname"] == "SET_METER_SERIAL_NUMBER" then
            local txfrags, firstPktId, seq = self.processSetYLSetSerialNumReq(msg) -- a fragmented message
            if txfrags ~= nil then
                self.addReqMessage(cid, firstPktId, cmd, msg, payload)
            end
        elseif msg["msgname"] == "SET_METER_STATUS" then
            payload = self.processSetMcMeterStatusReq(msg, payload)
            self.addAndSendReqMessage(cid, tid, cmd, msg, payload)
        elseif msg["msgname"] == "SET_METER_TIME" then
            msg["time"] = msg["time"] - def.J2000_CONSTANT
            msg, payload = self.addParams(msg, payload)
            self.addAndSendReqMessage(cid, tid, cmd, msg, payload)
        else
            -- check if need to add any params 
            if loradef.reqParams[msgid] ~= nil then
                msg, payload = self.addParams(msg, payload)
            end    

            -- Store the message on device request queue with command id as index.
            self.addAndSendReqMessage(cid, tid, cmd, msg, payload)
        end
    end

    ---------------------------------------------------------------------------------------------------
    -- We may receive duplicate packets because of retrties.
    -- We may also receive pushed summation messages which are from the same sample taken at the NIC,
    -- and we also want to filter out those.  To deal with this the NIC now sends an event number in
    -- the summation message which changes only when the NIC collects a new sample.
    -- TODO:  time this out ?    
    self.isDuplicate = function(wholeNicMsg)
        local duplicate = false
        local cmd = LoraUtils.getCmdFromResponse(wholeNicMsg)
        local endpoint = LoraUtils.getEndpoint(wholeNicMsg)
        local msgid = cmd + (endpoint * 100 )
        if cmd ~= nil then
            if cmd == 1 then -- meter summation delivered cmd
                duplicate = (self.lastSumEvt == LoraUtils.getEvtNum(wholeNicMsg))
                self.lastSumEvt = LoraUtils.getEvtNum(wholeNicMsg)
            else
                duplicate = (self.lastNicMsg == wholeNicMsg)
            end
        end

        return duplicate
    end

    ---------------------------------------------------------------------------------------------------
    self.matchRequest = function(wholeMsg)
        local matchedCid = nil
        local tid = LoraUtils.getPktId(wholeMsg)
        local cmd = LoraUtils.getCmdFromResponse(wholeMsg)
        -- run thru msg list to find a match
        for cid, req in pairs(self.requests) do
            if req.tid == tid then
                if req.cmd == cmd then
                    matchedCid = cid
                    break
                else
                    print("Warning:  matched seqno but not cmd")
                end
            end
        end

        return matchedCid
    end

    self.nic_cmd_GET_METER_SUMMATION_DELIVERED = 1
    ---------------------------------------------------------------------------------------------------
    self.processLoraIncoming = function(loramsg)
        local eid = loramsg["eid"]
        local wholeNicPkt = loramsg["payload"]
        local isFragment, isCompleteMsg, wholeMsg
        if wholeNicPkt ~= nil then
            local endpoint = LoraUtils.getEndpoint(wholeNicPkt)
            if endpoint == loradef.ENDPOINT_METERING or endpoint == loradef.ENDPOINT_NIC then
                -- Just try to handle it as a fragment first
                -- If NOT a fragmented message the wholeMsg == wholeNicPkt
                isFragment, isCompleteMsg, wholeMsg = self.fragMgr.handleFragmentMsg(wholeNicPkt)

                if isCompleteMsg then
                    -- Hacky way of discarding duplicate packets
                    -- for GET_METER_SUMMATION_DELIVERED check if the NIC requires time correction
                    local nicCmd = LoraUtils.getCmdFromResponse(wholeMsg)
                    if  endpoint == loradef.ENDPOINT_METERING then
                        if nicCmd == self.nic_cmd_GET_METER_SUMMATION_DELIVERED then
                            --counts METER_SUMMATION_DELIVERED msgs
                            self.counterMSD     =   ( self.counterMSD % 5 ) + 1 
                            print("App<=NIC: ", eid, "  msg counter for METER_SUMMATION-DELIVERED : ", self.counterMSD)
                            -- checks nic time once in every 5 msgs
                            if self.counterMSD % 5 == 1 then
                                self.timeCorrection(loramsg)
                            end                        
                        end
                        if self.isDuplicate(wholeMsg) then
                            print("App<=NIC: ", eid, " ", loramsg["payload"], " is a duplicate message, discarding")
                            return 0
                        else
                            print("App<=NIC: ", eid, " ", loramsg["payload"], " is a complete message")                   
                        end
                    end

                    -- record this one to check for multipath duplicates
                    -- TODO:  maybe a problem for fragmented messages ?
                    self.lastNicMsg = wholeMsg

                    -- Check if a request to this message exists.
                    local cid = self.matchRequest(wholeMsg)
                    if cid ~= nil then
                        -- Process the response for a request.
                        self.processAndSendResponseToSwitch(wholeMsg, cid)
                        self.requests[cid] = nil
                    else
                        self.processAndSendUnsolicitedToSwitch(loramsg)
                    end
                else
                    print("App<=NIC: ", eid, " ", loramsg["payload"], " fragment")
                end
            else
                print("Info:  ignoring messages from endpoint ", tostring(endpoint), " in payload ", tostring(wholeNicPkt))
            end
        else
            print("App<=NIC: ", eid, " no payload found")
        end 


        -- return these values to support unit testing
        return isCompleteMsg, wholeMsg
    end

    ---------------------------------------------------------------------------------------------------
    self.processAndSendResponseToSwitch = function(respmsg, cid)
        -- Decode the payload and send the response to switch.
        print(self.requests[cid].req.msgname)
        local reqmsg = self.requests[cid].req
        local msgid = reqmsg.msgid
        local rsptbl, bytesAfterCmd = responses.extractRspData(respmsg)
        if responses.processRsp[msgid] ~= nil then
            rsptbl = responses.processRsp[msgid](rsptbl, bytesAfterCmd, respmsg)
        else
            rsptbl = responses.processSetCmdResponse(rsptbl, bytesAfterCmd, respmsg)
        end

        responses.sendLoraResponseToSwitch(reqmsg, rsptbl)
    end

    ---------------------------------------------------------------------------------------------------
    self.processAndSendUnsolicitedToSwitch = function(respmsg)
        local wholeNicPkt = respmsg["payload"]
        local cmd = LoraUtils.getCmdFromResponse(wholeNicPkt)
        --local msgid = LoraUtils.getMsgidFromNicCmd(cmd)
        local msgid = LoraUtils.getMsgidFromNicCmd(wholeNicPkt)
        local rsptbl, bytesAfterCmd = responses.extractRspData(wholeNicPkt)
        if responses.processRsp[msgid] ~= nil then
            rsptbl = responses.processRsp[msgid](rsptbl, bytesAfterCmd, respmsg)
            if rsptbl == nil then
                return 0
            end
            rsptbl["TYPE"] = "MS"            
            rsptbl["msgid"]     = msgid
            rsptbl["msgname"]   = def.name[msgid]            
            rsptbl["cid"]       = 0
            rsptbl["flags"]     = def.FLAG_FRAMETYPE_RESP + def.FLAG_ACK_REQ
            if rsptbl["result_code"] == nil then
                rsptbl["result_code"] = 0
            end
            rsptbl["eid"] = respmsg["eid"]
            print("FMS<=App: ", rsptbl["eid"], " CID ", rsptbl["cid"], " ", rsptbl["msgname"])
            LoraUtils.printTable(rsptbl)
            fme.sendmessage(def.fmeContext, rsptbl) -- FMS msg: unsolicited to 
        else
            rsptbl = responses.processSetCmdResponse(respmsg, bytesAfterCmd)
            print("Error:  unknown command ", tostring(cmd), " received from NIC ", tostring(respmsg["eid"]))
            -- TODO:  send an error to the FMS ?
        end
    end

    ---------------------------------------------------------------------------------------------------
    self.addReqMessage = function(cid, tid, cmd, msg, payload)
        if self.requests == nil then
            self.requests = {}
        end

        if self.requests[cid] == nil then
            self.requests[cid] = {}
        end

        self.requests[cid].req      = msg
        self.requests[cid].payload  = payload
        self.requests[cid].tid      = tid
        self.requests[cid].cmd      = cmd
        self.requests[cid].timeout = def.DEFAULT_LORA_TIMEOUT_SECS + os.time()
    end

    ---------------------------------------------------------------------------------------------------
    self.addAndSendReqMessage = function(cid, tid, cmd, msg, payload)
        self.addReqMessage(cid, tid, cmd, msg, payload)

        -- Send the message to FME , which will send down to the LoRa device
        local reqmsg = {}
        reqmsg["TYPE"]      = "L1"
        reqmsg["msgid"]     = msg["msgid"]
        reqmsg["msgname"]   = msg["msgname"]
        reqmsg["eid"]       = msg["eid"]
        reqmsg["cid"]       = msg["cid"]  -- this is purely for unit test framework purposes
        reqmsg["payload"]   = payload
        print("App=>LoRa:", reqmsg["msgname"], " EID ", reqmsg["eid"])
        LoraUtils.printTable(reqmsg)
        fme.sendmessage(def.fmeContext, reqmsg) -- L1 msg: processLoraRequest
    end

    self.mkNicMsg   = function(endpoint, cmd, payload)
        local packet = ""
        local pktId = Device.getNextPktId()
        local cmdStr = string.format("%02x", cmd - (100 * endpoint) )
        local prefix = bit.lshift(endpoint, 5) + pktId
        packet = string.format("%02x", prefix) .. cmdStr .. payload  

        return packet
    end

    self.pushLoRaMsg = function(eid, cmd, payload)
        local nicmsg        = {}
        nicmsg["TYPE"]      = "L1"
        nicmsg["eid"]       = eid
        nicmsg["msgname"]   = "SET_NIC_TIME_CORRECTION"
        local nic_endpoint  = bit.rshift(loradef.endpoint[def.name[cmd]],5)
    nicmsg["payload"]   = self.mkNicMsg(nic_endpoint, cmd, payload)
    print("App=>NIC: ", eid, " ", "correction payload : ", payload)
    LoraUtils.printTable(nicmsg)
    fme.sendmessage(def.fmeContext, nicmsg) -- L1 msg: processLoraRequest
end

self.timeCorrection = function(msg)
    -- Report from NIC contains MSB 3 bytes of timestamp
    -- therefore, the average time between 00 to FF has been considered 

    local extras         =  {}
    local payload        =  ""
    local timeApprox     =  string.sub(msg.payload,#msg.payload-7,#msg.payload)
    timeApprox           =  LoraUtils.leHexToBeHex(timeApprox)
    --retrieving relevant values only 
    local lastByte       =  string.sub(timeApprox,#timeApprox-1,#timeApprox)
    lastByte             =  string.format("%02x",bit.lshift(tonumber(lastByte,16),2)%256)
    timeApprox           =  string.sub(timeApprox,1,#timeApprox-2) .. lastByte
    local delta          =  os.time() - tonumber(timeApprox,16)  
    if math.abs(delta) > Device.timeCorrectionThreshold then
        print("App=>NIC: ", msg["eid"], " ", "correction delta : ", delta )
        extras["delta"]   = delta
        extras["ackFlag"] = "00"
        local rval        = string.format ("%08x", extras["delta"])
        rval              = LoraUtils.leHexToBeHex(rval)
        payload           = rval --.. extras["ackFlag"]

        self.pushLoRaMsg(msg["eid"], def.msgid.SET_NIC_TIME_CORRECTION, payload)
    end
end

---------------------------------------------------------------------------------------------------
self.checkTimeoutMessage = function ()
    if self.requests ~= nil then
        for cid, obj in pairs(self.requests) do
            local msg = obj.req
            if self.requests[cid].timeout <= os.time() then
                -- return timeout to the message and delete it from the device message queue.
                local rspmsg = {}
                rspmsg["TYPE"]          = msg["TYPE"]                       
                rspmsg["msgid"]         = msg["msgid"]
                rspmsg["msgname"]       = msg["msgname"]
                rspmsg["cid"]           = msg["cid"]
                rspmsg["eid"]           = msg["eid"]                        
                rspmsg["flags"]         = def.FLAG_FRAMETYPE_RESP + def.FLAG_ACK_REQ
                rspmsg["result_code"]   = loradef.MP_STATUS_NO_RESPONSE_FROM_NIC
                rspmsg["error_details"] = loradef.ERROR_DETAILS[loradef.MP_STATUS_NO_RESPONSE_FROM_NIC]
                print("FMS<=App: ", msg["eid"], " CID ", msg["cid"], rspmsg["msgname"], " Timeout ")
                LoraUtils.printTable(rspmsg) 
                fme.sendmessage(def.fmeContext, rspmsg) -- FMS msg:  timeout
                -- clear the message.
                self.requests[cid] = nil
            end
        end
    end

    self.fragMgr.checkTimeouts()
end

self.tid = 0
---------------------------------------------------------------------------------------------------
self.getTransactionId = function ()
    if self.tid >= 0x37 then -- 5 bits
        self.tid = 0
    end

    self.tid = self.tid + 1

    return self.tid
end

-----------------------------------------------------------------------------------------------
local mt = self

-- WRITE NEW __index AND __newindex TO METATABLE
setmetatable(self, mt)
-----------------------------------------------------------------------------------------------

return self
end

return Device
