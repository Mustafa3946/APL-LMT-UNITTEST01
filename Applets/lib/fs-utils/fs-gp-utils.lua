---------------------------------------------------------------------------------------------------
-- Purpose: Utilities 
--
-- Author:  Alan Barker
--
-- Details: 
--
-- Copyright Statement:
-- Copyright © 2015 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored, 
-- transcribed in an information retrieval system, translated into -- any language, or transmitted 
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise, 
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
---------------------------------------------------------------------------------------------------

local onWindows = (os.getenv("OS") == "Windows_NT")
local bit  = require("bit")
require("os")
local dbUtils = require("lib.fs-utils.fs-debug-utils")

---------------------------------------------------------------------------------------------------
-- Taken from Programming in Lua, 2nd Ed, p142
-- means that this is used as a module:
-- local utils = require "utils"
-- utils.dbPrint(...)
local modname = ...
local M = {}
_G[modname] = M
package.loaded[modname] = M

M.logfile   = nil
M.errorfile = nil
M.LOG_FILE_ENABLED        = false
M.ERROR_LOG_FILE_ENABLED  = false
M.RESULT_CODE             = "result_code"
M.ERROR_DETAILS           = "error_details"
M.RESPONSE_OK             = 0
M.RESPONSE_ANYERR         = 0xFFFFFFFF
M.TIMEOUT_STRING          = "Timeout"
M.PARAM_MISSING           = "FCP Parameter Missing"

-----------------------------------------------------------------------------------------------
-- FCP Related
-----------------------------------------------------------------------------------------------
    -- Flags
M.FLAG_FRAMETYPE_RESP = 0x08
M.FLAG_RESP_REQ       = 0x04
M.FLAG_ACK_REQ        = 0x02
M.FLAG_DUP            = 0x01 

---------------------------------------------------------------------------------------------------
function M.fileExists(name)
   local f = io.open(name,"r")
   if f ~= nil then 
      io.close(f) 
      return true 
   else 
      return false 
   end
end

---------------------------------------------------------------------------------------------------
-- Returns time in seconds since Midnight 1 Jan 2000.  
-- The func os.time returns epoch time (secs sinc 1970)
function M.secsSinceY2000()
    local secsTo2000 = os.time{year=2000, month=1, day=1, hour=0}
    return os.time() - secsTo2000
end

---------------------------------------------------------------------------------------------------
-- return true if tab == {} or tab == nil
function M.isEmptyTable(tab)
    local isEmpty = true
    if tab ~= nil then
      isEmpty = next(tab) == nil
    end
    
    return isEmpty
end

---------------------------------------------------------------------------------------------------
-- Takes the eid string as an input and returns a unique string which is safe for Lua to use.
-- See FA-58, which discusses the filename limitations discovered on the hvc platform.
function M.eidToFileName(eid)
    local name = ""
    local c
    for i = 1, #eid do
        c = eid:sub(i,i)
        if c ~= ":" then
            local n = tonumber(c)
            if n == nil then
                -- it's a character
                name = name .. c
            else
                -- it's a character representation of a number
                -- Convert the number to a character with G=0, H=1, etc.
                name = name .. string.char(string.byte('G') + n)
            end
        end
    end
    
    return name
end

---------------------------------------------------------------------------------------------------
-- Returns a table which represents the bits in the 16 bit word w, with the least significant 
-- bit being in table[1], MSB in table[16]
function M.toBitTable(w)
    local month = {}
    local temp = w
    for i = 1, 16 do
        local m = temp % 2
        temp = (temp - m)/2
        month[i] = m
    end
    
    return month
end

---------------------------------------------------------------------------------------------------
-- Returns a table which represents the bits in the 16 bit word w, with LSB in key "b0", and MSB in key "b15"
-- values will be either true or false
function M.toBitKeyTable(w)
    local bitTable = {}
    local temp = w
    for i = 1, 16 do
        local b = temp % 2
        temp = (temp - b) / 2
        local key = "b" .. tostring(i - 1)
        bitTable[key] = (b ~= 0)
    end
    return bitTable
end

---------------------------------------------------------------------------------------------------
-- Returns a bit mask based upon the bit numbers (0-31) provided.  all other bits will be zero.
function M.makeBitMask(...)
	local mask = 0
	for i,v in ipairs(arg) do
		local thisBit = 2 ^ v
		mask = mask + thisBit
	end
	return mask
end

---------------------------------------------------------------------------------------------------
-- Currently the vminfo is formatted inconsistently "aabb...  with the message aa:bb...
function M.getColonEid(eid)     
    local e = string.sub (eid, 0, 23)
    if string.find(e, ":") then
        return e -- assume it's formatted correctly
    else
        return e:sub(1, 2)  .. ":" .. e:sub(3, 4) ..   ":" .. e:sub(5, 6) ..   ":" .. e:sub(7, 8) .. ":" ..
               e:sub(9, 10) .. ":" .. e:sub(11, 12) .. ":" .. e:sub(13, 14) .. ":" .. e:sub(15, 16)
        
    end
end

---------------------------------------------------------------------------------------------------
function M.printFmeMsgRx(level, msg)
    M.dbSafePrint(level, string.format("SW => FM [CID=%04X] %s", msg["cid"], msg["msgid"]))
end

---------------------------------------------------------------------------------------------------
function M.printFmeMsgTx(level, msg)
    M.dbSafePrint(level, string.format("SW <= FM [CID=%04X] %s", msg["cid"], msg["msgid"]))
end

local t0 = M.secsSinceY2000()
---------------------------------------------------------------------------------------------------
function M.tick(n)  -- seconds 
    if M.secsSinceY2000() - t0 >= n then
        t0 = M.secsSinceY2000()
        return true
    else
        return false
    end
end

---------------------------------------------------------------------------------------------------
function M.utcDay()
    local currDateTable = os.date("*t", os.time())
    return currDateTable["day"] 
end

---------------------------------------------------------------------------------------------------
function M.utcMonth()
    local currDateTable = os.date("*t", os.time())
    return currDateTable["month"]    
end

---------------------------------------------------------------------------------------------------
function M.utcMinsPastMidnight()
    local currDateTable = os.date("*t", os.time())
    return currDateTable["hour"]*60 + currDateTable["min"]   
end

---------------------------------------------------------------------------------------------------
function M.toBool(value)
    return value == 1 or value == true   
end

---------------------------------------------------------------------------------------------------
function M.tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

---------------------------------------------------------------------------------------------------
-- add all of the attributes in attrList to m and return that table
function M.mergeAttributes(m, attrList)
    for i, t in pairs(attrList) do
        m[i] = t
    end
    
    return m
end

---------------------------------------------------------------------------------------------------
-- Returns true if module "name" is available to be loaded
-- Useful for run time code selection of debug modules.
function M.moduleIsAvailable(name)
    if package.loaded[name] then
        return true
    else
        for _, searcher in ipairs(package.searchers or package.loaders) do
            local loader = searcher(name)
            if type(loader) == 'function' then
                package.preload[name] = loader
                return true
            end
        end
    
        return false
    end
end

---------------------------------------------------------------------------------------------------
function M.mkRspFromMsg(mIn, extraflags)
    local mOut = {}
    mOut["TYPE"]    = "MS"
    if extraflags ~= nil then
        mOut["flags"]   = M.FLAG_FRAMETYPE_RESP + extraflags
    else
        mOut["flags"]   = M.FLAG_FRAMETYPE_RESP
    end
    mOut["msgname"] = mIn["msgname"]
    mOut["eid"]     = mIn["eid"]
    if mIn["cid"] < 0x00010000 then
        mOut["cid"] = mIn["cid"]
    else -- it's a scheduled unsolicited message so set the CID to zero
        mOut["cid"] = 0
    end
       
    return mOut
end

---------------------------------------------------------------------------------------------------
function M.mkUnsolicitedRsp(msgid, msgname, eid, extraflags)
    local mOut = {}
    mOut["TYPE"]    = "MS"
    mOut["flags"]   = M.FLAG_FRAMETYPE_RESP + M.FLAG_ACK_REQ
    if extraflags ~= nil then
        mOut["flags"] = mOut["flags"] + extraflags
    end
    mOut["msgid"]   = msgid
    mOut["msgname"] = msgname
    mOut["eid"]     = eid
    mOut["cid"]     = 0
       
    return mOut
end

---------------------------------------------------------------------------------------------------
function M.mkUnsolicitedErrRsp(msgid, msgname, eid, extraflags)
    local mOut = {}
    mOut["TYPE"]    = "MS"
    mOut["flags"]   = M.FLAG_FRAMETYPE_RESP + M.FLAG_ACK_REQ
    if extraflags ~= nil then
        mOut["flags"] = mOut["flags"] + extraflags
    end
    mOut["msgid"]   = msgid
    mOut["msgname"] = msgname
    mOut["eid"]     = eid
    mOut["cid"]     = 0
    mOut["result_code"] = M.RESPONSE_ANYERR
       
    return mOut
end

---------------------------------------------------------------------------------------------------
function M.mkErr(msg, errStr)
    msg[M.RESULT_CODE] = M.RESPONSE_ANYERR
    msg[M.ERROR_DETAILS] = tostring(msg["msgname"]) .. ":" .. tostring(errStr)
    M.logErr(1, msg[M.ERROR_DETAILS])
    
    return msg
end

---------------------------------------------------------------------------------------------------
function M.mkTimeoutResponse(fm, m)
    M.dbSafePrint(1, string.format("SW <= FME:        %s: Error: timeout", m["msgname"]))
    M.printTable(m)
         
    return M.mkErr(fm, m, M.TIMEOUT_STRING)
end

---------------------------------------------------------------------------------------------------
-- An attribute was missing, so send an error back to the FME. 
function M.mkBadParamResponse(fm, m, errStr)
    M.dbSafePrint(1, string.format("SW <= FME:        %s: Error:  param(s) missing", m["msgname"])) 
    local m2 = M.mkErr(fm, m, M.PARAM_MISSING .. ": " .. tostring(errStr))
    M.printTable(m2)
                      
    return m2 
end

---------------------------------------------------------------------------------------------------
function M.mkSuccessResponse(msg)
    M.dbSafePrint(1, string.format("SW <= FME:%10s: Success", msg["msgname"]))  
    local resp = {}
    resp["TYPE"]    = msg["TYPE"]
    resp["msgname"] = msg["msgname"]
    resp["msgid"]   = msg["msgid"]
    resp["eid"]     = msg["eid"]
    resp["cid"]     = msg["cid"]
    
    resp[M.RESULT_CODE] = M.RESPONSE_OK
    
    return resp
end

---------------------------------------------------------------------------------------------------
function M.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[M.deepcopy(orig_key)] = M.deepcopy(orig_value)
        end
        setmetatable(copy, M.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

---------------------------------------------------------------------------------------------------
-- Trim whitespace from either end of s
function M.trim(str)
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

---------------------------------------------------------------------------------------------------
-- if s = "from=world, to=Lua", returns a table t["from"] = "world", t["to"] = "Lua"
-- "words" are all alphanumerics plus underscore plus dash.
-- Whitespace is allowed within values but not keys
-- Whitespace is trimmed from the start and end of the value
function M.getKeyValueTable(str)
    local tab = nil
    if str ~= nil then
        tab = {}                  
        -- Pattern matching example:  the set all alphanumeric, _, - [%w_%-] repeated 1 or more times [%w_%-]+
        -- the chars "*", "-", "+", & "?" are repetition operators and must be preceded by %.
        for k, v in string.gmatch( str, "([%w%-_;:]+):([%s%w%-_;:]+)" ) do
            local tk = M.trim(k)
            tab[tk] = M.trim(v)
        end
    end
    
    return tab
end

---------------------------------------------------------------------------------------------------
-- if s = "from=world, to=Lua", returns a table t["from"] = "world", t["to"] = "Lua"
-- "words" are all alphanumerics plus underscore plus dash.
-- Whitespace is allowed within values but not keys
-- Whitespace is trimmed from the start and end of the value
function M.split(inputstr, sep)
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

-----------------------------------------------------------------------------------------------
-- return a little endian byte table, from a hexascii string, index starting at 1
M.makeLEByteTable = function(hexascii)
    local byteTable = {}
    local bytes = math.floor(string.len(hexascii)/2)
    for byteIndex = 1, bytes do
        local strIndex = 1 + (byteIndex - 1)*2
        byteTable[byteIndex] = tonumber(string.sub(hexascii, strIndex, strIndex + 1), 16)
    end
    
    return byteTable
end

-----------------------------------------------------------------------------------------------
-- return a reversed byte table, indexed from 1
M.reverseByteTable = function(byteTable)
    local newIndex = 1
    local reversedTable = {}
    for index = #byteTable, 1, -1 do
        reversedTable[newIndex] = byteTable[index]
        newIndex = newIndex + 1
    end
    
    return reversedTable
end

-----------------------------------------------------------------------------------------------
-- return a big endian byte table made from a hexascii string, LSB = index 1
M.makeBEByteTable = function(hexascii)
    local leByteTable = M.makeLEByteTable(hexascii)
    
    return M.reverseByteTable(leByteTable)
end

-----------------------------------------------------------------------------------------------
-- return the nth byte from the hexascii string.
-- Big endian, ie MSB is leftmost and starts at 1.
M.getByte = function(hexascii, byteNumber)
    local startIndex = 2*(byteNumber - 1) + 1

    return tonumber( string.sub(hexascii, startIndex, startIndex + 1), 16 )
end

-----------------------------------------------------------------------------------------------
-- return the nth byte from the hexascii string.
-- Big endian, ie MSB is leftmost and starts at 1.
M.getWord = function(hexascii, byteNumber)
    local startIndex = 2*(byteNumber - 1) + 1

    return tonumber( string.sub(hexascii, startIndex, startIndex + 3), 16 )
end

-----------------------------------------------------------------------------------------------
-- get the state of a bit from a big endian hexascii formatted string.  
-- As the hexascii string reads from left to right, the leftmost byte is the most significant
-- byte, and the rightmost byte is the least significant byte.
-- bitNum 0 is the least significant bit of the least significant byte.
M.getBit = function(hexascii, bitNum)
    -- first break the hexascii into an array of nibbles, big endian nibble order
    local nibbles = {}
    local numNibs = string.len(hexascii)
    for nib = 1, numNibs do
        local chNum = numNibs - nib + 1
        nibbles[nib - 1] = string.sub(hexascii, chNum, chNum)
    end
    
    -- now calculate which nibble and bit in the nibble the bitNum is in
    local bitInNib = math.fmod(bitNum, 4)
    local nibNum = math.floor(bitNum/4)
    bitInNib = math.floor(bitInNib)
    nibNum = math.floor(nibNum)
    local theBit = 0
    if nibbles[nibNum] ~= nil and nibbles[nibNum] ~= "0" then
        local theNib = nibbles[nibNum]
        local theNum = tonumber(theNib, 16)
        theBit = bit.band(bit.rshift(theNum, bitInNib), 1)
    end
    
    return theBit
end

---------------------------------------------------------------------------------------------------
M.reverseHexAsciiBytes = function(hexascii)
    local byteLen = hexascii:len()
    local result = ""

    for index = 1, byteLen, 2 do
        result = hexascii:sub(index, index + 1) .. result
    end

    return result
end

---------------------------------------------------------------------------------------------------
local test_reverseHexAsciiBytes = function()
    local result = M.reverseHexAsciiBytes("010203040506070809")
    
    print(result)
end

--test_reverseHexAsciiBytes()

---------------------------------------------------------------------------------------------------
M.sendAppStartedMessage = function(context, fme, alertId, alertName)  
    local eid = vminfo["gwEID"]
    if eid == nil then
        M.dbSafePrint(1, " vminfo does not contain appEID")
    else
        local msg = M.mkUnsolicitedRsp(alertId, alertName, eid)
        msg["alert_type"]     = 0
        msg["alert_time"]     = M.secsSinceY2000()
        msg["alert_details"]  = "Lua App " .. vminfo["instanceEID"] .. " is started"
        msg["eid"]            = eid

        M.dbSafePrint(1, "SW <= FME:        ", msg["eid"], " GW_ALERT unsolicited (app started)")
        fme.sendmessage(context, msg)
    end
end

---------------------------------------------------------------------------------------------------
-- Here specifically as an equivalent to the Matlab function of the same name
---------------------------------------------------------------------------------------------------
M.strcmp = function(str1, str2)  
    local result = 0
    if str1 == str2 then
        result = 1
    end
end

---------------------------------------------------------------------------------------------------
-- Munge gp utils and dbg utils together
---------------------------------------------------------------------------------------------------
for k,v in pairs(dbUtils) do M[k] = v end


