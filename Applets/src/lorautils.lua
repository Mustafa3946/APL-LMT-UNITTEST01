-- ------------------------------------------------------------------------------------------------
-- Purpose: LoRa Utils
--
-- Details:
--
-- Copyright Statement:
-- Copyright © 2016 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored,
-- transcribed in an information retrieval system, translated into -- any language, or transmitted
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise,
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
-- ------------------------------------------------------------------------------------------------
local bit = require("bit")
local loradef = require("src.loradef")
local def = require("src.defines")

LoraUtils = {}

---------------------------------------------------------------------------------------------------
LoraUtils.printTable = function(tab)
    for name, value in pairs(tab) do
        local output = string.format("%-20s", name)
        print("    ", output, " = ", value)
    end    
end

---------------------------------------------------------------------------------------------------
LoraUtils.stringToHexAscii = function(str)
    local hexAscii = ""
    for index = 1, str:len() do
        hexAscii = hexAscii .. string.format("%02x", string.byte(str:sub(index, index)))
    end
    
    return hexAscii
end

---------------------------------------------------------------------------------------------------
LoraUtils.hexAsciiToString = function(hexAscii)
    local int, frac = math.modf(hexAscii:len()/2)
    local str = ""
    local hexCpy = hexAscii
    if frac == 0 then
        while hexCpy:len() >= 2 do
            local num = tonumber(hexCpy:sub(1, 2), 16)
            str = str .. string.char(num)
            hexCpy = hexCpy:sub(3)
        end
    else
        print("Error:  hex ascii odd length")
    end
    
    return str
end

---------------------------------------------------------------------------------------------------
-- leNumber is a little endian number
LoraUtils.littleEndianNumToHex = function(leNumber, bytes)
    local result = 0
    local bytearray = {}
    for byteNum = 1, bytes do
        bytearray[byteNum] = bit.band(0xFF, bit.rshift(leNumber, (byteNum-1)*8))
    end
    
    for byteNum = 1, bytes do
        result = result + bit.lshift(bytearray[byteNum], (bytes - byteNum)*8)
    end    
     
    local formatStr = "%0" .. tostring(bytes*2) .. "x"
    local valueHex = string.format(formatStr, result)
    
    return valueHex
end

---------------------------------------------------------------------------------------------------
-- leHexBytes is a little endian number represented as hexascii.
-- return a big endian hexascii.
LoraUtils.leHexToBeHex = function(leHexBytes)
    local beHex = ""
    local hexSize = string.len(leHexBytes)
    -- process only if even number
    local num, rem = math.modf(hexSize, 2)
    if rem == 0 then
        local leIndex = hexSize - 1
        while leIndex > 0 do
            local hexByte = string.sub(leHexBytes, leIndex, leIndex + 1)
            beHex = beHex .. hexByte
            leIndex = leIndex - 2
        end
    end
    
    return beHex
end

---------------------------------------------------------------------------------------------------
-- leHexBytes is a little endian number represented as hexascii.
-- return a big endian number
LoraUtils.leHexToBeNum = function(leHexBytes)
    local beHex = LoraUtils.leHexToBeHex(leHexBytes)
    return tonumber(beHex, 16)
end

---------------------------------------------------------------------------------------------------
-- The cmd byte may have bit 8 set if it is a fragmented cmd
-- The actual cmd 
LoraUtils.removeFragBitFromCmdByte= function(cmdByte)
    local cmd = cmdByte
    local isFrag = false
    if  cmd >= loradef.CMD_FRAGMENT_BIT then
        cmd = cmd - loradef.CMD_FRAGMENT_BIT
        isFrag = true
    end
    
    return cmd, isFrag
end

---------------------------------------------------------------------------------------------------
LoraUtils.msgidToNicCmd = function(msgid)
    local cmd = ""
    local msgname = def.name[msgid]
    -- 5-8 bit in the header contains endpoint
    local endpoint = bit.rshift(loradef.endpoint[msgname],5)
    if msgid ~= nil then
            print("Endpoint : ", endpoint)
            cmd = msgid - ( endpoint * 100 )
    end

    return cmd
end

---------------------------------------------------------------------------------------------------
-- The cmd byte may have bit 8 set if it is a fragmented cmd
-- The actual cmd 
LoraUtils.getMsgidFromNicCmd = function(wholeMsg)
    local endpoint = LoraUtils.getEndpoint(wholeMsg)
    local cmd = LoraUtils.getCmdFromResponse(wholeMsg)    
    local msgid =""
    if cmd ~= nil then
            print("Endpoint : ", endpoint)
            msgid = cmd + ( endpoint * 100 )
            -- unsolicited METER_SUMMATION_DELIVERED and response of GET_METER_SUMMATION_DELIVERED are the same message
            if msgid == 201 then
                msgid = 204
            end
            -- unsolicited METER_CURRENT_PRESSURE and response of GET_METER_CURRENT_PRESSURE are the same message
            if msgid == 202 then
                msgid = 205
            end            
    end
    
    return msgid
end

-----------------------------------------------------------------------------------------------
-- Set a value in a nested table.
-- Will write only to the tip of a table path, not intermediate points (ie cannot destroy the tab).
-- Will not add new paths to the table.
-- Exploits the fact that when a table is assigned to a variable in Lua, that variable becomes
--  a reference to the table.
-- Param "tab" is the table.
-- Second "param" is a vararg which is expected to be structured as follows:
--  The last value in the vararg must be the value itself.
--  The preceding values match the indices of the table, in order.
-- Eg:  to set the value in a table structure self.summation.value to 2, call:
--  self.setTabVal(table, "summation", "value", 2)
LoraUtils.setTabVal = function(tab, ...)
    local args = {...}
    if type(...) == "table" then
        args = ... -- deal with variant: self.getTabVal(table, {"summation", "value"})
    end
    local thing = tab
    local last = nil
    local lastEntry = nil
    local value = nil
    for _, entry in pairs(args) do
        if type(thing[entry]) == "table" then
            thing = thing[entry]
            last = thing
        elseif thing[entry] ~= nil then
            lastEntry = entry
        else
            value = entry
        end
    end 
    
    --last[lastEntry] = value
end

LoraUtils.setTabValOld = function(tab, ...)
    local args = {...}
    if type(...) == "table" then
        args = ... -- deal with variant: self.getTabVal(table, {"summation", "value"})
    end
    local thing = tab
    local last = nil
    local lastEntry = nil
    local value = nil
    for _, entry in pairs(args) do
        if type(thing[entry]) == "table" then
            thing = thing[entry]
            last = thing
        elseif thing[entry] ~= nil then
            lastEntry = entry
        else
            value = entry
        end
    end 
    
    last[lastEntry] = value
end

-----------------------------------------------------------------------------------------------
-- Return a value in a nested table.
-- Exploits the fact that when a table is assigned to a variable in Lua, that variable becomes
--  a reference to the table.
-- Param "tab" is the table.
-- Second "param" is a vararg which is the "path" to the required part of the table.
-- Eg:  to get the value in a table structure self.summation.value, call:
--  self.getTabVal(table, "summation", "value")
--  Also copes with handing in a list as a table:
--  self.getTabVal(table, {"summation", "value"})
LoraUtils.getTabVal = function(tab, ...)
    local args = {...}
    if type(...) == "table" then
        args = ... -- deal with variant: self.getTabVal(table, {"summation", "value"})
    end
    local thing = tab
    local result = nil
    for index, val in pairs(args) do
        if type(thing[val]) == "table" then
            thing = thing[val]
        else
            result = thing[val]
        end
    end 

    return result
end 

---------------------------------------------------------------------------------------------------
-- Make an unfragmented request packet
-- ep/pktid, frag/cmd, status, payload
LoraUtils.mkReqPkt = function(endpoint, pktId, loracmd, payload)
    local packet = ""
    if endpoint <= 7 and pktId <= 31 then
        local loracmdStr = string.format("%02x", loracmd)
        local prefix = bit.lshift(endpoint, 5) + pktId
        packet = string.format("%02x", prefix) .. loracmdStr .. payload
    end
    
    return packet
end

---------------------------------------------------------------------------------------------------
-- Make an unfragmented response packet
-- ep/pktid, frag/cmd, status, payload
LoraUtils.mkRspPkt = function(endpoint, pktId, loracmd, status, payload)
    local packet = ""
    if endpoint <= 7 and pktId <= 31 then
        local cmdStr = string.format("%02x", loracmd)
        local statusStr = string.format("%02x", status)
        local prefix = bit.lshift(endpoint, 5) + pktId
        packet = string.format("%02x", prefix) .. cmdStr .. statusStr .. payload
    end
    
    return packet
end

---------------------------------------------------------------------------------------------------
LoraUtils.getSeqid = function(wholeNicPkt)
    return tonumber(string.sub(wholeNicPkt, 5, 6), 16)
end

---------------------------------------------------------------------------------------------------
LoraUtils.getFragPayload = function(wholeNicPkt)
    return string.sub(wholeNicPkt, 7)
end

local PAYLOAD_IDX_CMD_START     = 3
local PAYLOAD_IDX_CMD_END       = 4
---------------------------------------------------------------------------------------------------
LoraUtils.getCmdFromResponse = function(wholeNicPkt)
    local cmdByte = LoraUtils.getCmdByte(wholeNicPkt)
    
    return LoraUtils.removeFragBitFromCmdByte(cmdByte)
end

---------------------------------------------------------------------------------------------------
LoraUtils.getCmdByte = function(wholeNicPkt)
    return tonumber(string.sub(wholeNicPkt, PAYLOAD_IDX_CMD_START, PAYLOAD_IDX_CMD_END), 16)
end

---------------------------------------------------------------------------------------------------
-- Get the event number from the summation NIC packet
-- It is in the upper two bits of the last byte
LoraUtils.getEvtNum = function(wholeNicPkt)
    local readingUpdateCtr = tonumber(string.sub(wholeNicPkt, 15, 16), 16)
    return bit.rshift(readingUpdateCtr, 6)
end


---------------------------------------------------------------------------------------------------
LoraUtils.getHdrByte = function(wholeNicPkt)
    return tonumber(string.sub(wholeNicPkt, 1, 2), 16)
end

---------------------------------------------------------------------------------------------------
-- Packet ID in header byte
LoraUtils.getPktId = function(wholeNicPkt)
    local hdr = LoraUtils.getHdrByte(wholeNicPkt)
    
    return bit.band(hdr, 0x1F)
end

---------------------------------------------------------------------------------------------------
LoraUtils.getEndpoint = function(wholeNicPkt)   
    local hdr = LoraUtils.getHdrByte(wholeNicPkt)
    return bit.rshift(hdr, 5)
    --return bit.rshift(wholeNicPkt, 5)
end

---------------------------------------------------------------------------------------------------
-- Get the status byte from the response packet
LoraUtils.getRspStatus = function(wholeNicPkt)
    return tonumber(string.sub(wholeNicPkt, 1 ,2), 16)
end

---------------------------------------------------------------------------------------------------
LoraUtils.isFragBitSet = function(wholeNicPkt)
    local cmdByte = LoraUtils.getCmdByte(wholeNicPkt)
    
    return (bit.band(cmdByte, 0x80) == 0x80)
end

---------------------------------------------------------------------------------------------------
-- if s = "from=world, to=Lua", returns a table t["from"] = "world", t["to"] = "Lua"
-- "words" are all alphanumerics plus underscore plus dash.
-- Whitespace is allowed within values but not keys
-- Whitespace is trimmed from the start and end of the value
function LoraUtils.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; local i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
      end
      
      return t
end

---------------------------------------------------------------------------------------------------
-- Trim whitespace from either end of s
function LoraUtils.trim(str)
    local trStr = ""
    local start = 0
    local finish = 0
    for idx = 1, str:len() do
        if str:byte(idx) > 32 then
            start = idx
            break
        end
    end
    
    for idx = str:len(), 1, -1 do
        if str:byte(idx) > 32 then
            finish = idx
            break
        end
    end
    
    if start > 0 and finish > 0 then
        trStr = str:sub(start, finish)
    end
    
    return trStr
end