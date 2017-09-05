-- --------------------------------------------------------------------------------------------
-- Purpose: LoRa NIC data model:  
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

local def       = require("src.defines")
local fme       = require(def.module.fme)
local loradef   = require("src.loradef")
require("src.lorautils")
local device    = require("src.device")
require("src.lorautils")

local LoraNicData = {} -- table storing the functions performing device operations

LoraNicData.new = function()
    local self = {}
    
    self.version = {}
    self.version.value = 0x0102034204050647
    self.battery = {}
    self.battery.life = 0x1234
    self.summation = {}
    self.summation.value = 0
    self.summation.schedule = {}
    self.summation.schedule.value = 1234
    self.pressure = {}
    self.pressure.value = 0
    self.pressure.schedule = {}
    self.pressure.schedule.value = 0
    self.custid = {}
    self.custid.value = "0102030405060708090a0b0c0d0e"
    self.format = {}
    self.serial = {}
    self.serial.value = "1234567890"
    self.status = 0x000001
    
    -----------------------------------------------------------------------------------------------
    -- arbitrarily write values within tables under "self"
    self.getParam = function(...)
        return LoraUtils.getTabVal(self, ...)
    end
    
    self.format["uint8"]    = "%02x"
    self.format["uint16"]   = "%04x"
    self.format["uint32"]   = "%08x"
    
    -----------------------------------------------------------------------------------------------
    -- 
    self.get = function(...)
        local args = ...
        local dotpath = args[1]
        local format = args[2]
        local size  = args[3]
        local splitPath = LoraUtils.split(dotpath, ".")
        local value = LoraUtils.getTabVal(self, splitPath)
        local resultHex = ""
        if self.format[format] ~= nil then
            resultHex = string.format(self.format[format], value)
        end
        
        return resultHex
    end
 
     -----------------------------------------------------------------------------------------------
    -- 
    self.set = function(...)
        local args = ...
        local dotpath = args[1]
        local format = args[2]
        local size  = args[3]
        local value = args[4]
        local splitPath = LoraUtils.split(dotpath, ".")
        table.insert(splitPath, #splitPath + 1, value) 
        LoraUtils.setTabVal(self, splitPath)
    end
 
    -----------------------------------------------------------------------------------------------
    self.setParam = function(...)
        LoraUtils.setTabVal(self, ...)
    end
 
    return self
end

return LoraNicData