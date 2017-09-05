---------------------------------------------------------------------------------------------------
-- Purpose: Main 
--
-- Copyright Statement:
-- Copyright © 2014 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored,
-- transcribed in an information retrieval system, translated into -- any language, or transmitted
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise,
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
-------------------------------------------------------------------------------------------------

local def       = require "src.defines"
local fme       = require(def.module.fme)
local loradef   = require("src.loradef")
require(def.module.deviceMgr)

--------------------------------------------------------------------------------------------------
-- main
--------------------------------------------------------------------------------------------------
local function main()
    local msg = nil
    local  msgTimeout = os.time() + def.REQ_MSG_CHECK_PERIOD_SECS
    def.fmeContext = fme.open()
    while true do
        msg = fme.getmessage(def.fmeContext)
        if msg ~= nil then	-- message available
            if msg["TYPE"]     == "MS" then
                pcall(DeviceMgr.processLoraRequest, msg)
            elseif msg["TYPE"] == "L1" then
                pcall(DeviceMgr.processLoraIncoming, msg)
            elseif msg["TYPE"] == "CONTROL_START" then
                DeviceMgr.addDevice(msg["eid"])
            elseif msg["TYPE"] == "CONTROL_STOP" then
                DeviceMgr.delDevice(msg["eid"])
            elseif msg["TYPE"] == "CONTROL_STOP_EXIT" then
                --clearall()
            else
                print("LUA APP VERSION:",def.LUA_APPLICATION_VERSION,"RECEIVED UNKNOWN MSG\n")
            end
        end
        if msg == nil then
            if msgTimeout <= os.time() then
                DeviceMgr.checkTimeoutMessage()
                msgTimeout = os.time() + def.REQ_MSG_CHECK_PERIOD_SECS
            else
                fme.sleep(1) 
            end
        end
    end
end

---------------------------------------------------------------------------------------------------
local function fatalerr()
  print(debug.traceback())
end
---------------------------------------------------------------------------------------------------
-- call main with xpcall, which catches fatal errors and calls dump to print out stack trace
---------------------------------------------------------------------------------------------------
print(xpcall(main, fatalerr))
