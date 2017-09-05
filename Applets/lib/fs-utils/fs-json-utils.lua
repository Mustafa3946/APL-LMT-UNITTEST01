---------------------------------------------------------------------------------------------------
-- Purpose: fs-json-utils
--
-- Author:  Alan Barker
--
-- Details: Freestyle JSON Utilities

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
local json  = require(defs.module.json)
local utils = require(defs.module.utils)

local self = {}

---------------------------------------------------------------------------------------------------
self.getStructOld = function(schema)
  local result = {}
  for name, prop in pairs(schema) do
    if prop.type ~= nil then
      if prop.type == "object" then
        result[name] = self.getStruct(prop.properties)
      else
        result[name] = prop.type
      end
    else
      if prop.enum ~= nil then
        result[name] = "enum"
      end
    end
  end

  return result
end

---------------------------------------------------------------------------------------------------
self.getStructWithTestValues = function(schema)
  local result = {}
  for name, prop in pairs(schema) do
    if prop.type ~= nil then
      if prop.type == "object" then
        result[name] = self.getStructWithTestValues(prop.properties)
      else
        result[name] = prop.test_value
      end
    else
      if prop.enum ~= nil then
        result[name] = prop.test_value
      end
    end
  end

  return result
end

---------------------------------------------------------------------------------------------------
self.getStructWithDummyValues = function(schema)
  local result = {}
  for name, prop in pairs(schema) do
    --if name == "timestamp" then
    --    print()
    --end
    --print("Name:", name)
    if prop.type ~= nil then
      if prop.type == "object" then
        result[name] = self.getStructWithDummyValues(prop.properties)
      else
        if prop.type == "number" then
            if prop.test_value ~= nil then
                result[name] = prop.test_value
            else
                result[name] = prop.maximum
            end
        elseif prop.type == "string" then
            if prop.test_value ~= nil then
                result[name] = prop.test_value
            else
                result[name] = "empty"
            end
        elseif prop.type == "array" then
            if prop.items.enum ~= nil then
                if prop.test_value ~= nil then
                    result[name] = prop.test_value
                else      
                    result[name] = {}
                    for _, value in pairs(prop.items.enum) do
                        table.insert(result[name], value)
                    end
                end
            elseif prop.maxItems ~= nil then
                result[name] = {}
                for i = 1, prop.maxItems do
                    result[name][i] = prop.items.maximum
                end
            else 
                print("maxItems not found")
                os.exit()
            end
        else
            print("unknown prop.type")
            os.exit()
        end
      end
    else
      if prop.enum ~= nil then
        result[name] = prop.enum[1]
      end
    end
  end

  return result
end

---------------------------------------------------------------------------------------------------
self.schemaToStructure = function(schema)
  local struct = schema["properties"]
  local result = self.getStructWithDummyValues(struct)

  return result
end

---------------------------------------------------------------------------------------------------
self.loadSchema = function(fileName)
  local file = io.open(fileName)

  local data = file:read('*all')
  io.close(file)
  local schema = json.decode(data)
  
  return self.schemaToStructure(schema)
end

---------------------------------------------------------------------------------------------------
self.dumpJson = function(prefix, inname, outname, jsonTab, toFile)
    local jdfile = nil
    local file = nil
    if not toFile then
        print()
        print(prefix, inname)
    else
        local jdotPath = outname .. ".jdot"
        jdfile = io.open(jdotPath, "w")
        local jsonPath = outname .. ".json"
        file = io.open(jsonPath, "w")
    end
    utils.printTableRecursiveDots(jsonTab, "", jdfile)
    local jstr = json.encode(jsonTab)
    file:write(jstr)
    if jdfile ~= nil then
        io.close(jdfile)
    end

    if file ~= nil then
        io.close(file)
    end    
end

---------------------------------------------------------------------------------------------------
-- populate the json with reasonable values
self.populate = function(jsonTable)
  local result = {}
  for name, object in pairs(jsonTable) do
    if prop.type ~= nil then
      if prop.type == "object" then
        result[name] = self.getStruct(prop.properties)
      else
        result[name] = prop.type
      end
    else
      if prop.enum ~= nil then
        result[name] = "enum"
      end
    end
  end

  return result
end

return self
