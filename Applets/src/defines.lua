-- --------------------------------------------------------------------------------------------
-- Purpose: LoRa Lua Application:  defines
--
-- Details:
--
-- Copyright Statement:
-- Copyright © 2014 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored, 
-- transcribed in an information retrieval system, translated into -- any language, or transmitted 
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise, 
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
-- --------------------------------------------------------------------------------------------

local T = {}
T.module = {}

T.module.os         = "os"
T.module.fme        = "fme"
T.module.deviceMgr  = "src.deviceMgr"
T.module.responses  = "src.responses"
T.module.loradef    = "src.loradef"
T.module.json       = "lib.dkjson.dkjson"

-- Global FME Context
T.fmeContext                    = nil

-- App Version
-- ------------------------------------------------------------------------------------------------
T.LUA_APPLICATION_VERSION       = "AppletVersionPH" -- Written by script into bundle
T.printAlive                    = 3600 
-- ------------------------------------------------------------------------------------------------
-- Switch side message IDs
-- ------------------------------------------------------------------------------------------------

T.initMsg = function(name, msgid)
    T.msgid[name] = msgid
    T.name[msgid] = name
end

---------------------------------------------------------------------------------------------------
-- msgid definitions below are FMS side IDs
---------------------------------------------------------------------------------------------------
-- Common commands-------------------------------- NIC cmd
T.msgid = {}

-- NIC endpoint commmands
T.msgid.GET_NIC_BATTERY_LIFE                = 101
T.msgid.SET_NIC_BATTERY_LIFE                = 102
T.msgid.GET_NIC_TIME                        = 103
T.msgid.SET_NIC_TIME_CORRECTION             = 104
T.msgid.GET_NIC_SCHEDULE                    = 105
T.msgid.SET_NIC_SCHEDULE                    = 106
T.msgid.GET_NIC_MODE                        = 107
T.msgid.SET_NIC_MODE                        = 108
T.msgid.GET_NIC_VERSION                     = 109


T.msgid.METER_SUMMATION_DELIVERED           = 201     
T.msgid.METER_CURRENT_PRESSURE              = 202
T.msgid.GET_METER_TYPE                      = 203     
T.msgid.GET_METER_SUMMATION_DELIVERED       = 204     
T.msgid.GET_METER_CURRENT_PRESSURE          = 205
T.msgid.GET_METER_GAS_VALVE_STATE           = 206
T.msgid.SET_METER_GAS_VALVE_STATE           = 207
T.msgid.GET_SUMMATION_REPORT_INTERVAL       = 208
T.msgid.SET_SUMMATION_REPORT_INTERVAL       = 209
T.msgid.GET_PRESSURE_REPORT_INTERVAL        = 210
T.msgid.SET_PRESSURE_REPORT_INTERVAL        = 211
T.msgid.METER_ALERT                         = 212     -- 0
--                                            16 to 30 currently unused
                                                    -- 31 Must not use
-- Yungloong commands---------------------------
T.msgid.GET_OFLOW_DETECT_ENABLE             = 232    -- 132
T.msgid.SET_OFLOW_DETECT_ENABLE             = 233
T.msgid.GET_OFLOW_DETECT_DURATION           = 234
T.msgid.SET_OFLOW_DETECT_DURATION           = 235
T.msgid.GET_OFLOW_DETECT_RATE               = 236
T.msgid.SET_OFLOW_DETECT_RATE               = 237
T.msgid.GET_PRESSURE_ALARM_LEVEL_LOW        = 238
T.msgid.SET_PRESSURE_ALARM_LEVEL_LOW        = 239
T.msgid.GET_PRESSURE_ALARM_LEVEL_HIGH       = 240
T.msgid.SET_PRESSURE_ALARM_LEVEL_HIGH       = 241
T.msgid.GET_LEAK_DETECT_RANGE               = 242
T.msgid.SET_LEAK_DETECT_RANGE               = 243
T.msgid.GET_MANUAL_RECOVER_ENABLE           = 244
T.msgid.SET_MANUAL_RECOVER_ENABLE           = 245
T.msgid.GET_METER_FIRMWARE_VERSION          = 246
T.msgid.GET_METER_SHUTOFF_CODES             = 247
-- Micom commands-------------------------------
T.msgid.GET_METER_READING_VALUE             = 248
T.msgid.SET_METER_READING_VALUE             = 249  
T.msgid.GET_METER_STATUS                    = 250 
T.msgid.SET_METER_STATUS                    = 251 
T.msgid.GET_METER_CUSTOMERID                = 252     
T.msgid.SET_METER_CUSTOMERID                = 253        
T.msgid.GET_METER_TIME                      = 258        
T.msgid.SET_METER_TIME                      = 259        
T.msgid.SET_CONFIG_CENTER_SHUTDOWN          = 260            
T.msgid.SET_CONFIG_DISABLE_CENTER_SHUTDOWN  = 261
T.msgid.GET_PROTOCOL_VERSION                = 262
--T.msgid.unused                            = 263
-- Yung Loong commands again -------------------
T.msgid.GET_METER_SERIAL_NUMBER             = 264
T.msgid.SET_METER_SERIAL_NUMBER             = 265
T.msgid.GET_ELECTRIC_QNT_VALUE              = 266
T.msgid.GET_COMMS_MODE                      = 267
T.msgid.SET_COMMS_MODE                      = 268
T.msgid.GET_PILOT_LIGHT_MODE                = 269
T.msgid.SET_PILOT_LIGHT_MODE                = 270
T.msgid.GET_EARTHQUAKE_SENSOR_STATE         = 271
T.msgid.SET_EARTHQUAKE_SENSOR_STATE         = 272
-- Common commands again -----------------------


-- --------------------------------------------------------------------------------------------
-- Message id to message name
-- --------------------------------------------------------------------------------------------
T.name = {}
T.name[T.msgid.METER_SUMMATION_DELIVERED]               = "METER_SUMMATION_DELIVERED"     
T.name[T.msgid.METER_CURRENT_PRESSURE]                  = "METER_CURRENT_PRESSURE"
T.name[T.msgid.METER_ALERT]                             = "METER_ALERT"
T.name[T.msgid.GET_METER_TYPE]                          = "GET_METER_TYPE"
T.name[T.msgid.GET_METER_SUMMATION_DELIVERED]           = "GET_METER_SUMMATION_DELIVERED"
T.name[T.msgid.GET_METER_CURRENT_PRESSURE]              = "GET_METER_CURRENT_PRESSURE"
T.name[T.msgid.GET_METER_GAS_VALVE_STATE]               = "GET_METER_GAS_VALVE_STATE"   
T.name[T.msgid.SET_METER_GAS_VALVE_STATE]               = "SET_METER_GAS_VALVE_STATE"  
T.name[T.msgid.GET_SUMMATION_REPORT_INTERVAL]           = "GET_SUMMATION_REPORT_INTERVAL"  
T.name[T.msgid.SET_SUMMATION_REPORT_INTERVAL]           = "SET_SUMMATION_REPORT_INTERVAL"
T.name[T.msgid.GET_PRESSURE_REPORT_INTERVAL]            = "GET_PRESSURE_REPORT_INTERVAL" 
T.name[T.msgid.SET_PRESSURE_REPORT_INTERVAL]            = "SET_PRESSURE_REPORT_INTERVAL" 
T.name[T.msgid.GET_NIC_VERSION]                         = "GET_NIC_VERSION"
T.name[T.msgid.GET_NIC_BATTERY_LIFE]                    = "GET_NIC_BATTERY_LIFE"
T.name[T.msgid.SET_NIC_BATTERY_LIFE]                    = "SET_NIC_BATTERY_LIFE"
T.name[T.msgid.SET_NIC_TIME_CORRECTION]                 = "SET_NIC_TIME_CORRECTION"
T.name[T.msgid.GET_NIC_TIME]                            = "GET_NIC_TIME"
T.name[T.msgid.GET_NIC_SCHEDULE]                        = "GET_NIC_SCHEDULE"
T.name[T.msgid.SET_NIC_SCHEDULE]                        = "SET_NIC_SCHEDULE"
T.name[T.msgid.GET_NIC_MODE]                            = "GET_NIC_MODE"
T.name[T.msgid.SET_NIC_MODE]                            = "SET_NIC_MODE"

-- Yungloong message names
T.name[T.msgid.GET_OFLOW_DETECT_ENABLE]              = "GET_OFLOW_DETECT_ENABLE"   
T.name[T.msgid.SET_OFLOW_DETECT_ENABLE]              = "SET_OFLOW_DETECT_ENABLE"       
T.name[T.msgid.GET_OFLOW_DETECT_DURATION]            = "GET_OFLOW_DETECT_DURATION"   
T.name[T.msgid.SET_OFLOW_DETECT_DURATION]            = "SET_OFLOW_DETECT_DURATION"
T.name[T.msgid.GET_OFLOW_DETECT_RATE]                = "GET_OFLOW_DETECT_RATE"        
T.name[T.msgid.SET_OFLOW_DETECT_RATE]                = "SET_OFLOW_DETECT_RATE"         
T.name[T.msgid.GET_PRESSURE_ALARM_LEVEL_LOW]         = "GET_PRESSURE_ALARM_LEVEL_LOW"
T.name[T.msgid.SET_PRESSURE_ALARM_LEVEL_LOW]         = "SET_PRESSURE_ALARM_LEVEL_LOW" 
T.name[T.msgid.GET_PRESSURE_ALARM_LEVEL_HIGH]        = "GET_PRESSURE_ALARM_LEVEL_HIGH" 
T.name[T.msgid.SET_PRESSURE_ALARM_LEVEL_HIGH]        = "SET_PRESSURE_ALARM_LEVEL_HIGH" 
T.name[T.msgid.GET_LEAK_DETECT_RANGE]                = "GET_LEAK_DETECT_RANGE"       
T.name[T.msgid.SET_LEAK_DETECT_RANGE]                = "SET_LEAK_DETECT_RANGE"      
T.name[T.msgid.GET_MANUAL_RECOVER_ENABLE]            = "GET_MANUAL_RECOVER_ENABLE"     
T.name[T.msgid.SET_MANUAL_RECOVER_ENABLE]            = "SET_MANUAL_RECOVER_ENABLE"    
T.name[T.msgid.GET_METER_FIRMWARE_VERSION]           = "GET_METER_FIRMWARE_VERSION"        
T.name[T.msgid.GET_METER_SHUTOFF_CODES]              = "GET_METER_SHUTOFF_CODES" 
T.name[T.msgid.GET_METER_SERIAL_NUMBER]              = "GET_METER_SERIAL_NUMBER"
T.name[T.msgid.SET_METER_SERIAL_NUMBER]              = "SET_METER_SERIAL_NUMBER"
T.name[T.msgid.GET_ELECTRIC_QNT_VALUE]               = "GET_ELECTRIC_QNT_VALUE"
T.name[T.msgid.GET_COMMS_MODE]                       = "GET_COMMS_MODE"
T.name[T.msgid.SET_COMMS_MODE]                       = "SET_COMMS_MODE"
T.name[T.msgid.GET_PILOT_LIGHT_MODE]                 = "GET_PILOT_LIGHT_MODE"
T.name[T.msgid.SET_PILOT_LIGHT_MODE]                 = "SET_PILOT_LIGHT_MODE"
T.name[T.msgid.GET_EARTHQUAKE_SENSOR_STATE]          = "GET_EARTHQUAKE_SENSOR_STATE"
T.name[T.msgid.SET_EARTHQUAKE_SENSOR_STATE]          = "SET_EARTHQUAKE_SENSOR_STATE"  

-- Micom message names
T.name[T.msgid.GET_METER_READING_VALUE]                 = "GET_METER_READING_VALUE"           
T.name[T.msgid.SET_METER_READING_VALUE]                 = "SET_METER_READING_VALUE"     
T.name[T.msgid.GET_METER_STATUS]                        = "GET_METER_STATUS"    
T.name[T.msgid.SET_METER_STATUS]                        = "SET_METER_STATUS"    
T.name[T.msgid.GET_METER_CUSTOMERID]                    = "GET_METER_CUSTOMERID"        
T.name[T.msgid.SET_METER_CUSTOMERID]                    = "SET_METER_CUSTOMERID"           
T.name[T.msgid.GET_METER_TIME]                          = "GET_METER_TIME"          
T.name[T.msgid.SET_METER_TIME]                          = "SET_METER_TIME"           
T.name[T.msgid.SET_CONFIG_CENTER_SHUTDOWN]              = "SET_CONFIG_CENTER_SHUTDOWN"                
T.name[T.msgid.SET_CONFIG_DISABLE_CENTER_SHUTDOWN]      = "SET_CONFIG_DISABLE_CENTER_SHUTDOWN"
T.name[T.msgid.GET_PROTOCOL_VERSION]                    = "GET_PROTOCOL_VERSION"          

T.ALERT_BASE_YL = 0xFC8100
T.ALERT_BASE_MC = 0xFC8400
-----------------------------------------------------------------------------------------------
---- FCP Related
-------------------------------------------------------------------------------------------------
-- Flags
T.FLAG_FRAMETYPE_RESP                           = 0x08
T.FLAG_RESP_REQ                                 = 0x04
T.FLAG_ACK_REQ                                  = 0x02
T.FLAG_DUP                                      = 0x01
-- Other
T.RESPONSE_OK                                   = 0
T.RESPONSE_ANYERR                               = 0xFFFFFFFF
T.RESULT_CODE                                   = "result_code"
T.ERROR_DETAILS                                 = "error_details"
T.TIMEOUT_STRING                                = "Timeout"
T.PARAM_MISSING                                 = "FCP Parameter Missing"
T.J2000_CONSTANT                                = 946684800
T.REQ_MSG_CHECK_PERIOD_SECS                     = 60    -- Check for REQUEST timeouts with this period
T.FRAG_MSG_CHECK_PERIOD_SECS                    = 60    -- Check for FRAG timeouts with this period
T.INCOMING_FRAG_TIMEOUT                         = 35*60 -- Fragments are sent 1 per 15 secs, timeout > 127*15 ~= 32 mins
T.DEFAULT_LORA_TIMEOUT_SECS                     = 60*60 -- May go up to xxx_MSG_CHECK_PERIOD_SECS longer

-- ---------------------------------------------------------------------------------------------
-- Seperator 
-- ---------------------------------------------------------------------------------------------
T.seperatorEqual = string.rep("=",90)

return T
