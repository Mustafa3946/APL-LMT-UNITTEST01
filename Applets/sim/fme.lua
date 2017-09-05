---------------------------------------------------------------------------------------------------
-- Module:  FME emulator
--
-- Purpose: 
--  Allow Apps to be exercised on a platform other than the actual Gateway without any modification.
--  Supports all "real" fme functions.
--  Contains it's own message queue into which messages can be inserted.
--
-- Author:  Alan Barker
---------------------------------------------------------------------------------------------------

local bit       = require("bit")
local socket    = require("socket") -- for time functions
math.randomseed(os.time())

-- simulate a global vminfo usually supplied by the FME core
vminfo = {}
vminfo["gwEID"]       = "0g00000000000001"
vminfo["appEID"]      = "0a00000000000000"
vminfo["instanceEID"] = "0a00000000000001"
vminfo["qname"]       = "/VM-1"
vminfo["devpath"]     = "devs"
vminfo["apppath"]     = "apps"
vminfo["appname"]     = "SimulationApp"

local fme                   = {}
fme.sim                     = {}
fme.sim.internal            = {}
fme.sim.internal.fifo       = {}
fme.sim.internal.callbacks  = {}
-- CID = Correlation ID, 16 bits incrementing per device, assigned by FMS to Requests
-- sent by App in Response.  Zero if Unsolicited.
fme.sim.internal.cid        = 1 
fme.sim.internal.tracknum   = 1
-- Unlike the FME, support only one "VM".  Return a "context" which is a random number which is used 
-- in functions here which accept it as a parameter to check the actual App is actually supplying it
-- at the appropriate time.
fme.sim.internal.context    = math.random(1, 2^16-1)
fme._ERROR_PREFIX           = "Emulated FME error: "
fme.sim.internal.callback_getmessage    = nil
fme.sim.internal.callback_sendmessage   = nil
fme.sim.internal.callback_sleep         = nil
fme.sim.internal.callback_msleep        = nil
fme.sim.internal.callback_testdone      = nil
fme.sim.internal.callback_simerror      = nil
fme.sim.internal.callbacknames = 
{
    getmessage  = true,
    sendmessage = true,
    sleep       = true,
    msleep      = true,
    testdone    = true,
    simerror    = true
}
fme.sim.internal.callbacks["getmessage"]    = fme.sim.internal.callback_getmessage
fme.sim.internal.callbacks["sendmessage"]   = fme.sim.internal.callback_sendmessage
fme.sim.internal.callbacks["sleep"]         = fme.sim.internal.callback_sleep
fme.sim.internal.callbacks["msleep"]        = fme.sim.internal.callback_msleep
fme.sim.internal.callbacks["testdone"]      = fme.sim.internal.callback_testdone
fme.sim.internal.callbacks["simerror"]      = fme.sim.internal.callback_simerror
fme.sim.internal.isOpen                     = false

---------------------------------------------------------------------------------------------------
-- Standard fme API calls.
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
function fme.open()
    fme.sim.internal.isOpen = true
    
    return fme.sim.internal.context
end

---------------------------------------------------------------------------------------------------
-- Intercept the FMEs sendmessage command, log what is passing through and call back the test code
-- if a callback is registered.
function fme.sendmessage(context, msg)
    if fme.sim.internal.isOpen then
        if type(context) ~= "number" then
            local errmsg = fme._ERROR_PREFIX .. " sendmessage:  context param wrong type " .. type(context)
            fme.sim.internal.doCallback("simerror", errmsg)
        elseif context == fme.sim.internal.context then
            fme.sim.internal.doParamChecks(msg)
        else
            print(fme._ERROR_PREFIX .. " sendmessage:  context param does not match")
            os.exit()
        end
    else
        
    end
    
    msg["tracknum"] = fme.sim.internal.getTracknum()
    
    fme.sim.internal.doCallback("sendmessage", msg)
    
    return {tracknum = msg["tracknum"]}
end

---------------------------------------------------------------------------------------------------
-- Intercept the FMEs getmessage command, log what is passing through and call back the test code
-- if a callback is registered.
function fme.getmessage(context)
    if context == fme.sim.internal.context then
        local msg = fme.sim.internal.pop()
        if msg ~= nil then
            if msg["TYPE"] == "MS" then
                msg["cid"] = fme.sim.internal.getCid() -- Pretend to be the FMS by assign a cid on arrival
            elseif msg["TYPE"] == "SIM_TEST_END" then
                fme.sim.internal.doCallback("testdone")     
            end
        end
        
        fme.sim.internal.doCallback("getmessage", msg)
        
        return msg
    else
        local errmsg = fme._ERROR_PREFIX .. " sleep:  param 1 (context = " .. tostring(context) .. ") does not match that returned by fme.open()"
        fme.sim.internal.doCallback("simerror", errmsg)          
    end
end

---------------------------------------------------------------------------------------------------
-- Call fme.sim.internal.callback_sleep if it has been registered by an fme.sim.registerCallback_sleep(callback) call,
-- then actually sleep for the specified seconds.
function fme.sleep(secs)
    if type(secs) == "number" then
        fme.sim.internal.doCallback("sleep")
        socket.sleep(secs)
    else
        local errmsg = fme._ERROR_PREFIX .. " sleep:  param 1 (secs) is not a number " .. type(secs)
        fme.sim.internal.doCallback("simerror", errmsg)
    end
end

---------------------------------------------------------------------------------------------------
function fme.msleep(millisecs)
    if type(millisecs) == "number" then
        fme.sim.internal.doCallback("msleep")
        socket.sleep(millisecs/1000)
    else
        local errmsg = fme._ERROR_PREFIX .. " sleep:  param 1 (millisecs) is not a number " .. type(millisecs)
        fme.sim.internal.doCallback("simerror", errmsg)           
    end        
end

---------------------------------------------------------------------------------------------------
function fme.gettimefloat()
    local timems = socket.gettime()
    return timems
end

---------------------------------------------------------------------------------------------------
function fme.gettimems()
    local timefloat = socket.gettime()
    local int, frac = math.modf(timefloat)
    int, frac = math.modf(frac*1000)
    return frac
end

---------------------------------------------------------------------------------------------------
-- Utilities not implemented in the real fme.
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
function fme.sim.registerCallback(name, callback)
    local errmsg = nil
    local prefix = fme._ERROR_PREFIX .. "fme.sim.registerCallback "
    if type(name) ~= "string" then
        errmsg =  prefix .. "param 1 (name) is not a string = " .. type(name)
    elseif type(callback) ~= "function" then
        errmsg = prefix .. "param 2 (callback) is not a function = " .. type(callback)       
    elseif fme.sim.internal.callbacknames[name] == nil then
        errmsg = fme._ERROR_PREFIX .. "fme.sim.registerCallback param 1 (" .. name ") is not a valid callback"            
    else
        fme.sim.internal.callbacks[name] = callback
    end
    
    if errmsg ~= nil then
        fme.sim.internal.crashAndBurn(errmsg)  
    end
end

---------------------------------------------------------------------------------------------------
function fme.sim.push_fmsRequest(eid, msgid, msgname, extraParams)
    local PREFIX = fme._ERROR_PREFIX .."pushFmsRequest"
    if eid == nil then
        print(PREFIX .. ": " .. "param 1 (eid) is nil")
        os.exit()
    elseif type(msgid) ~= "number" then
        print(PREFIX .. ": " .. "param 2 (msgid) must be a number")
        os.exit()        
    elseif type(msgname) ~= "string" then
        print(PREFIX .. ": " .. "param 3 (msgname) must be a string")
        os.exit() 
    elseif extraParams ~= nil and type(extraParams) ~= "table" then
        print(PREFIX .. ": " .. "optional param 4 (extraparms) must be a table if supplied")
        os.exit()
    end
    
    local msg = {}
    msg["TYPE"]     = "MS"
    msg["eid"]      = eid
    msg["msgname"]  = msgname
    msg["msgid"]    = msgid

    if type(extraParams) == "table" then
        for name, value in pairs(extraParams) do
            msg[name] = value
        end
    end
    
    fme.sim.push(msg)
end

---------------------------------------------------------------------------------------------------
function fme.sim.push_controlStart(eid, bundleName)
    if type(eid) ~= "string" then
        print(fme._ERROR_PREFIX .. "fme._pushControlStart param 1 (eid) is not a string = " .. type(eid))
        os.exit()
    elseif type(bundleName) ~= "string" then
        print(fme._ERROR_PREFIX .. "fme._pushControlStart param 2 (bundleName) is not a string = " .. type(bundleName))
        os.exit()        
    end
    
    local msg = {}
    msg["TYPE"]             = "CONTROL_START"    
    msg["eid"]              =  eid
    msg["DeviceBundleName"] = bundleName

    fme.sim.push(msg)
end

---------------------------------------------------------------------------------------------------
function fme.sim.push_controlStop(eid)
    if type(eid) ~= "string" then
        print(fme._ERROR_PREFIX .. "fme._pushControlStop param 1 (eid) is not a string = " .. type(eid))
        os.exit()
    end
    
    local msg = {}
    msg["eid"]  =  eid
    msg["TYPE"] = "CONTROL_STOP"
  
    fme.sim.push(msg)
end

---------------------------------------------------------------------------------------------------
function fme.sim.push_testEnd()
    local msg = {}
    msg["TYPE"] = "SIM_TEST_END"
    
    fme.sim.push(msg)
end

---------------------------------------------------------------------------------------------------
function fme.sim.push(msg)
    if fme.sim.internal.fifo ~= nil then
        local msgcopy = fme.sim.internal.deepcopy(msg)
        table.insert(fme.sim.internal.fifo, msgcopy)
    else
        print(fme._ERROR_PREFIX .. "fme.open has not been called")
        os.exit()
    end
end

---------------------------------------------------------------------------------------------------
function fme.sim.internal.pop()    
    local msg = nil
    -- get the lowest index out of the table
    if table.maxn(fme.sim.internal.fifo) ~= 0 then
        msg = fme.sim.internal.fifo[1]
        table.remove(fme.sim.internal.fifo, 1)
    end

    return msg
end

---------------------------------------------------------------------------------------------------
function fme.sim.internal.getCid()
    local sentCid = fme.sim.internal.cid
    
    fme.sim.internal.cid = fme.sim.internal.cid + 1
    if fme.sim.internal.cid > 0xFFFF then
        fme.sim.internal.cid = 1
    end

    return sentCid
end

---------------------------------------------------------------------------------------------------
function fme.sim.internal.getTracknum()
    local sent = fme.sim.internal.tracknum
    
    fme.sim.internal.tracknum = fme.sim.internal.tracknum + 1
    if fme.sim.internal.tracknum > 2^16-1 then
        fme.sim.internal.tracknum = 1
    end

    return sent
end

---------------------------------------------------------------------------------------------------
function fme.sim.internal.doParamChecks(msg)
    local anyError = false
    if type(msg) ~= "table" then
        print(fme._ERROR_PREFIX .. "sendmessage: msg param type (" .. type(msg) .. ") is not table")
        os.exit()
    elseif msg["TYPE"] == nil then
        print(fme._ERROR_PREFIX .. "sendmessage: no TYPE param in msg")
        fme.sim.internal.printTable(msg)
        anyError = true
    elseif msg["eid"] == nil then
        print(fme._ERROR_PREFIX .. "sendmessage: no eid param in msg")
        fme.sim.internal.printTable(msg)
        anyError = true 
    end 
   
    if msg["TYPE"] == "MS" then
        if msg["cid"] == nil then
            print(fme._ERROR_PREFIX .. "sendmessage: no cid param in MS msg")
            fme.sim.internal.printTable(msg)
            anyError = true 
        end  
        
        if msg["msgname"] == nil then
            print(fme._ERROR_PREFIX .. "sendmessage: no msgname param in MS msg")
            fme.sim.internal.printTable(msg)
            anyError = true 
        end 
        
        if msg["msgid"] == nil then
            print(fme._ERROR_PREFIX .. "sendmessage: no msgid param in MS msg")
            fme.sim.internal.printTable(msg)
            anyError = true 
        end         
    end
    
    if anyError then
        os.exit()
    end
end

---------------------------------------------------------------------------------------------------
function fme.sim.internal.printTable(T)
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
            print(out)
        end
    end
end

---------------------------------------------------------------------------------------------------
function fme.sim.internal.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[fme.sim.internal.deepcopy(orig_key)] = fme.sim.internal.deepcopy(orig_value)
        end
        setmetatable(copy, fme.sim.internal.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    
    return copy
end

---------------------------------------------------------------------------------------------------
function fme.sim.internal.doCallback(name, param)
    local done = false
    if type(fme.sim.internal.callbacks[name]) == "function" then
        fme.sim.internal.callbacks[name](param)
        done = true
    elseif name == "simerror" then
        fme.sim.internal.crashAndBurn(param)
    end

    return done
end

---------------------------------------------------------------------------------------------------
function fme.sim.internal.crashAndBurn(param)
    print(fme._ERROR_PREFIX .. tostring(param))
    os.exit()
end

return fme
