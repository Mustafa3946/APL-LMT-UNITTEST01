-- --------------------------------------------------------------------------------------------
-- Purpose: LoRa Lua Application:  Instanciate LoRa devices and monitor transactions
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
-- --------------------------------------------------------------------------------------------

local def       = require "src.defines"
local fme       = require(def.module.fme)
local loradef   = require("src.loradef")
local device    = require("src.device")
require("src.lorautils")

DeviceMgr = {} -- table storing the functions performing device operations
DeviceMgr.totalDevicesAdded = 0
DeviceMgr.deviceList = {} -- table storing the devices and its message requests etc

---------------------------------------------------------------------------------------------------
DeviceMgr.addDevice = function(eid)
    if DeviceMgr.deviceList[eid] == nil then
        DeviceMgr.deviceList[eid] = device.new(eid)
        DeviceMgr.totalDevicesAdded   =  DeviceMgr.totalDevicesAdded  + 1        
        print(def.seperatorEqual)
        print("CONTROL_START: ", eid, DeviceMgr.totalDevicesAdded, " devices controlled")
        print(def.seperatorEqual)
    else
        print("CONTROL_START: ", eid, " device already controlled")
    end
end

---------------------------------------------------------------------------------------------------
DeviceMgr.delDevice = function ( eid )
    if DeviceMgr.deviceList[eid] ~= nil then
        DeviceMgr.deviceList[eid] = nil
        DeviceMgr.totalDevicesAdded = DeviceMgr.totalDevicesAdded  - 1
        print(def.seperatorEqual)
        print("CONTROL_STOP EID: ", eid, " ", DeviceMgr.totalDevicesAdded, " devices controlled")
        print(def.seperatorEqual)
    else
        print("CONTROL_STOP EID: ", eid, " unknown device")
    end
end

---------------------------------------------------------------------------------------------------
DeviceMgr.checkTimeoutMessage = function ()
    if DeviceMgr.deviceList ~= nil then
        for eid, device in pairs(DeviceMgr.deviceList) do
            device.checkTimeoutMessage()
        end
    end
end

---------------------------------------------------------------------------------------------------
DeviceMgr.processLoraRequest = function(msg)
    local eid = msg["eid"]
    DeviceMgr.deviceList[eid].processLoraRequest(msg)
end

---------------------------------------------------------------------------------------------------
DeviceMgr.processLoraIncoming = function(msg)
    local eid = msg["eid"]
    if eid ~= nil and DeviceMgr.deviceList[eid] ~= nil then
        DeviceMgr.deviceList[eid].processLoraIncoming(msg)
    end
end



