---------------------------------------------------------------------------------------------------
-- Purpose: Print Utilities 
--
-- Author:  Alan Barker
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
---------------------------------------------------------------------------------------------------

local M = {}
if __M == nil then
    __M = M
end
M.time = {}

M.DEBUG_ENABLED = false
M.DEBUG_ERR     = 3
M.DEBUG_WARN    = 2
M.DEBUG_INFO    = 1
M.DEBUG_NONE    = 0
M.DEBUG_LEVEL   = M.DEBUG_INFO

M.seperatorStar   = string.rep("*",100)
M.seperatorEqual  = string.rep("=",100)
M.seperatorDash   = string.rep("-",100)

---------------------------------------------------------------------------------------------------
function M.enableDebug()
    M.DEBUG_ENABLED = true
end

---------------------------------------------------------------------------------------------------
function M.disableDebug()
    M.DEBUG_ENABLED = false
end

---------------------------------------------------------------------------------------------------
function M.debugAllowed(atLevel)
    return M.DEBUG_ENABLED and tonumber(atLevel) ~= nil and M.DEBUG_LEVEL >= atLevel
end

---------------------------------------------------------------------------------------------------
function M.setDebugLevel(atLevel)
    if tonumber(atLevel) ~= nil then
        M.DEBUG_LEVEL = atLevel
    end
end

---------------------------------------------------------------------------------------------------
function M.getDebugLevel(atLevel)
    return M.DEBUG_LEVEL
end

---------------------------------------------------------------------------------------------------
function M.dbPrint(level, str)
    if M.debugAllowed(level) then
        print("[" .. vminfo["qname"] .. " " .. M.dateTimeStr() .. "] " .. tostring(str))
        if M.logfile ~= nil and M.LOG_FILE_ENABLED then
            M.logfile:write("[" .. vminfo["qname"] .. " " .. M.dateTimeStr() .. "] " .. tostring(str) .. "\n")
            M.logfile:flush()
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Craigs' platform independent solution for the vararg problem in dbSafePrint
-- If ... is "abc", "def", 1 then returns table {"abc", "def", 1, n = 3} 
-- where table[1] = "abc", table[2] = "def", etc and table["n"] = 3
function M.tablePack(...)
  return { n = select("#", ...), ... }
end

---------------------------------------------------------------------------------------------------
-- Use this function to print a debug string.
-- It is intended to defend against errors in which the Lua App can crash if an attempt to construct
-- a string with (say) nil arguments (for example because of a missing parameter), which may
-- cause Lua to crash.
-- It simply concatenates all the string versions of the arguments
function M.dbSafePrint(level, ...)
    if M.DEBUG_ENABLED and M.debugAllowed(level) then
        local args = M.tablePack(...)
        local str = ""
        for i, v in ipairs(args) do
            str = str .. tostring(v)
        end
        M.dbPrint(level, str)
    end   
end

---------------------------------------------------------------------------------------------------
function M.logErr(level, str)
    if M.debugAllowed(level) then
        if M.errorfile ~= nil and M.ERROR_LOG_FILE_ENABLED then
            M.errorfile:write("[" .. vminfo["qname"] .. " " .. M.dateTimeStr() .. "] Error: " .. tostring(str) .. "\n")
            M.errorfile:flush()
        else
            M.dbSafePrint(level, "errorlog.txt not open")
        end
        M.dbSafePrint(level, "Error: ", str)
    end   
end

---------------------------------------------------------------------------------------------------
function M.printBanner(dbglvl, str)
    M.dbSafePrint(dbglvl, M.seperatorDash)
    M.dbSafePrint(dbglvl, str)
    M.dbSafePrint(dbglvl, M.seperatorDash)
end

---------------------------------------------------------------------------------------------------
function M.printTable(T)
    if T ~= nil and type(T) == "table" then
        local out
        for i, t in pairs(T) do
            if type(t) == "number" then
                out = string.format("%30s = %s", i, t)
            elseif type(t) == "string" then
                local CHUNK = 64
                if string.len(t) <= CHUNK then
                    out = string.format("%30s = %s", i, t)
                elseif string.len(t) <= 2*CHUNK then
                    local first  = string.sub(t, 1, CHUNK)
                    local second = string.sub(t, CHUNK + 1)
                    out = string.format("%30s = %s\n%59s%s", i, first, " ", second)
                else
                    local first  = string.sub(t, 1, CHUNK)
                    local second = string.sub(t, CHUNK + 1, 2*CHUNK)
                    local third  = string.sub(t, 2*CHUNK + 1)
                    out = string.format("%30s = %s\n%59s%s\n%59s%s", i, first, " ", second, " ", third)
                end                
            else
                out = string.format("%30s = %s", i, tostring(t))
            end
            M.dbSafePrint(1, out)
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Print anything - including nested tables
-- call this with your initial desired indent eg printTableRecursive(T, indent, done)
function M.printTableRecursive(tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    for key, value in pairs (tt) do
      io.write(string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        io.write(string.format("[%s] => table\n", tostring (key)));
        io.write(string.rep (" ", indent+4)) -- indent it
        --io.write("(\n");
        M.printTableRecursive (value, indent + 7, done)
        io.write(string.rep (" ", indent+4)) -- indent it
        --io.write(")\n");
      else
        io.write(string.format("[%s] => %s\n",
            tostring (key), tostring(value)))
      end
    end
  else
    io.write(tt .. "\n")
  end
end

---------------------------------------------------------------------------------------------------
-- Print anything - including nested tables
-- call with prefix = ""
-- produces output data.settings.actuals format (more compact)
function M.printTableRecursiveDots(element, prefix, file)
    local output
    if type(element) == "table" then
        for key, value in pairs (element) do
            if type (value) == "table" then
                if prefix ~= "" then
                    M.printTableRecursiveDots(value, prefix .. "." .. key, file)
                else
                    M.printTableRecursiveDots(value, key, file)
                end
            else
                if prefix ~= "" then
                    output = prefix .. "." .. key .. " = " .. tostring(value) .. "\n"
                else
                    output = key .. " = " .. tostring(value) .. "\n"
                end
                
                if file == nil then
                    io.write(output)
                else
                    file:write(output)
                end
            end
        end
    else
        if prefix ~= "" then
            output = prefix .. " = " .. element .. "\n"
            if file == nil then
                io.write(output)
            else
                file:write(output)
            end
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Print anything - including nested tables
-- call this with your initial desired indent eg printTableRecursive(T, indent, done)
function M.copyTableItems(td, ts, done)
  done = done or {}
  if type(ts) == "table" then
    for key, value in pairs (ts) do
      if td[key] ~= nil then
        if type (value) == "table" and not done [value] then
          done [value] = true
          M.copyTableItems(td[key], ts[key], done)
        else
          td[key] = value
        end
      end
    end
  else
    --io.write(tt .. "\n")
  end
end

---------------------------------------------------------------------------------------------------
-- Open a log file
function M.openLog()
    if M.LOG_FILE_ENABLED then
        M.dbSafePrint(1, "Opening log.txt")
        M.logfile = io.open("log.txt", "w")
    end
end

---------------------------------------------------------------------------------------------------
-- Open a log file
function M.openErrorLog()
    if M.ERROR_LOG_FILE_ENABLED then
        M.dbSafePrint(1, "Opening errorlog.txt")
        M.errorfile = io.open("errorlog.txt", "w")
    end
end

---------------------------------------------------------------------------------------------------
function M.printValueWithBanner(desc, value)
    local dbglvl = 1
    if value ~= nil then
        M.dbSafePrint(dbglvl, M.seperatorStar)
        if type(value) == "number" then
            M.dbSafePrint(dbglvl, desc, " = ", tostring(value), string.format(" = 0x%012X", value))
        else
            M.dbSafePrint(dbglvl, desc, " = ", tostring(value))
        end
        M.dbSafePrint(dbglvl, M.seperatorStar) 
    else
        M.dbSafePrint(dbglvl, M.seperatorStar)
        M.dbSafePrint(dbglvl, "Error:  ", desc, " Not Present")
        M.dbSafePrint(dbglvl, M.seperatorStar)       
    end
end

local m_lastTime  = os.time()
local m_startTime = os.time()
local m_lastTicks = 0
---------------------------------------------------------------------------------------------------
-- periodically print a line to the console purely to show the app is alive.
---------------------------------------------------------------------------------------------------
function M.printAlive(deviceMgr, secsToPrintalive, luaAppVersion)
    local currTime = os.time()
    local diffTime = currTime - m_lastTime
    if diffTime > secsToPrintalive then
        m_lastTime = os.time()

        M.dbSafePrint(1, M.seperatorDash)
        local runMins = (os.time() - m_startTime)/60     
        M.dbSafePrint(1, 
            tostring(vminfo["appname"]), 
            " V", 
            luaAppVersion,
            " curr ", 
            M.dateStr(),
            " ", vminfo["qname"], " ",
            " st ", m_startTime, ", ", 
            deviceMgr.deviceCount, " devs. Up ", 
            string.format("%.2f", runMins),  "min")
        M.dbSafePrint(1, M.seperatorDash)
    end  
    
    local printed = deviceMgr.printMessages()
    
    if printed then
        M.dbSafePrint(1, M.seperatorDash)  
    end
end

local m_startDate = os.date("%X, %x")
---------------------------------------------------------------------------------------------------
-- print a startup banner
function M.printStartupBanner(luaAppVersion)
    M.printBanner(1, 
        tostring(vminfo["appname"]) .. 
        " Version " .. 
        luaAppVersion .. 
        " start " .. 
        m_startDate .. 
        " App EID " .. 
        tostring(vminfo["instanceEID"]) )
end

---------------------------------------------------------------------------------------------------
function M.printWithBanner(dbglvl, s)
    M.dbSafePrint(dbglvl, M.seperatorStar)
    M.dbSafePrint(dbglvl, s)
    M.dbSafePrint(dbglvl, M.seperatorStar)    
end

---------------------------------------------------------------------------------------------------
function M.dateTimeStr()
    return os.date("%d/%m/%y %H:%M:%S")
end

---------------------------------------------------------------------------------------------------
function M.dateStr()
    return os.date("%d/%m/%y")
end

---------------------------------------------------------------------------------------------------
function M.timeStr()
    return os.date("%H:%M:%S")
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
M.sendAppStartedMessage = function(context, fme, alertId, alertName)  
    local eid = vminfo["gwEID"]
    if eid == nil then
        M.dbSafePrint(1, " vminfo does not contain appEID")
    else
        local msg = M.mkUnsolicitedRsp(alertId, alertName, eid)
        msg["alert_type"]     = 0
        msg["alert_time"]     = os.time()
        msg["alert_details"]  = "Lua App " .. vminfo["instanceEID"] .. " is started"
        msg["eid"]            = eid

        M.dbSafePrint(1, "SW <= FME:        ", msg["eid"], " GW_ALERT unsolicited (app started)")
        fme.sendmessage(context, msg)
    end
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
function M.mkErr(msg, errStr)
    M.dbSafePrint(M.DEBUG_INFO, string.format("SW <= FME:%10s: Error", msg["msgname"]))
    local resp = {}
    resp["msgname"] = msg["msgname"]
    resp["msgid"]   = msg["msgid"]    
    resp[M.RESULT_CODE] = M.RESPONSE_ANYERR
    resp[M.ERROR_DETAILS] = tostring(resp["msgname"]) .. ":" .. tostring(errStr)
    
    return resp
end

M.RESULT_CODE             = "result_code"
M.ERROR_DETAILS           = "error_details"
M.RESPONSE_OK             = 0
M.RESPONSE_ANYERR         = 0xFFFFFFFF

return __M


