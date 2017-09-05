---------------------------------------------------------------------------------------------------
-- Purpose: Controller
--
-- Author:  Alan Barker
--
-- Details:
--
-- Copyright Statement:
-- Copyright © 2016 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored, 
-- transcribed in an information retrieval system, translated into any language, or transmitted 
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise, 
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
---------------------------------------------------------------------------------------------------

local defs  = require("defines")
local utils = require("fs-debug-utils")
local json  = require(defs.module.json)
local JsonSchema = {}
JsonSchema.schema = nil

---------------------------------------------------------------------------------------------------
JsonSchema.loadSchema = function(schemaFileName)
    local schemaFile = io.open(schemaFileName, "r")
    local schema = nil

    if schemaFile then
        local schemaTxt = schemaFile:read("*all")
        schema = json.decode(schemaTxt)
    end
    
    return schema
end

---------------------------------------------------------------------------------------------------
-- Compare an incoming json table to a schema
-- Return true if all the required fields are present
-- Works for only a flat json file, not multilevel tables
JsonSchema.validateTable = function(params, schemaTable)
    local ok
    for _, requiredName in pairs(schemaTable["required"]) do
        ok = false
        for propertyName, property in pairs(schemaTable["properties"]) do
            if requiredName == propertyName then
                if property["type"] == "object" then
                    ok = JsonSchema.validateTable(property, schemaTable["properties"][propertyName])
                else
                    ok = true
                    break
                end
            end
        end
    end
        
    return ok
end

---------------------------------------------------------------------------------------------------
-- recursive function for creating a json table from a json schema
-- The created table has the basic structure of the target table with named properties assigned 
-- their "type" string.
JsonSchema.createTableFrom = function(schemaTable)
    local newTab = {}
    for propertyName, property in pairs(schemaTable["properties"]) do
        if property["type"] == "object" then
            newTab[propertyName] = JsonSchema.createTableFrom(property)
        elseif property["enum"] ~= nil then
            newTab[propertyName] = "enum"
        else
            newTab[propertyName] = property["type"]
        end
    end
    
    return newTab
end

---------------------------------------------------------------------------------------------------
-- Works for only a flat json file, not multilevel tables
JsonSchema.validate = function(params, schemaTable)
    local ok = false
    if JsonSchema.schema ~= nil then
        ok = JsonSchema.validateTable(params)
    end
    
    return ok
end

return JsonSchema
