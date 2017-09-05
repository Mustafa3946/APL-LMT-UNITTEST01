-- --------------------------------------------------------------------------------------------
-- Purpose: LoRa Lua Application:  lora define
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

local onWindows = (os.getenv("OS") == "Windows_NT")
local def = require "src.defines"

local T = {}

local modname = ...
_G[modname] = T
package.loaded[modname] = T

T.MAX_LORA_PAYLOAD            = 22
T.MAX_FRAGMENT_LORA_PAYLOAD   = 16
T.CMD_FRAGMENT_BIT            = 128
T.LORA_COMMON_COMMAND_LAST_ID = 31

-- LORA FRAGMENT MASKS
T.FRAGMENT_1  = 0x7f
T.FRAGMENT_2  = 0x7e
T.FRAGMENT_3  = 0x7d
T.FRAGMENT_4  = 0x7c
T.FRAGMENT_5  = 0x7b
T.FRAGMENT_6  = 0x7a
T.FRAGMENT_7  = 0x79
T.FRAGMENT_8  = 0x78
T.FRAGMENT_9  = 0x77
T.FRAGMENT_10 = 0x76

-- LORA STATUS CODES
T.MP_STATUS_SUCCESS                    = 0
T.MP_STATUS_FAILURE                    = 1
T.MP_STATUS_UNAUTHORIZED               = 2
T.MP_STATUS_UNSUPPORTED_COMMAND        = 3
T.MP_STATUS_MALFORMED_COMMAND          = 4
T.MP_STATUS_HARDWARE_FAILURE           = 5
T.MP_STATUS_SOFTWARE_FAILURE           = 6
T.MP_STATUS_METER_NOT_ATTACHED         = 7
T.MP_STATUS_METER_COMMS_ERROR          = 8
T.MP_STATUS_NO_RESPONSE_FROM_NIC       = 100

T.ERROR_DETAILS                                    = {}
T.ERROR_DETAILS[T.MP_STATUS_SUCCESS]               = "MP_STATUS_SUCCESS"
T.ERROR_DETAILS[T.MP_STATUS_FAILURE]               = "MP_STATUS_FAILURE" 
T.ERROR_DETAILS[T.MP_STATUS_UNAUTHORIZED]          = "MP_STATUS_UNAUTHORIZED"
T.ERROR_DETAILS[T.MP_STATUS_UNSUPPORTED_COMMAND]   = "MP_STATUS_UNSUPPORTED_COMMAND"
T.ERROR_DETAILS[T.MP_STATUS_MALFORMED_COMMAND]     = "MP_STATUS_MALFORMED_COMMAND"
T.ERROR_DETAILS[T.MP_STATUS_HARDWARE_FAILURE]      = "MP_STATUS_HARDWARE_FAILURE"
T.ERROR_DETAILS[T.MP_STATUS_SOFTWARE_FAILURE]      = "MP_STATUS_SOFTWARE_FAILURE"
T.ERROR_DETAILS[T.MP_STATUS_METER_NOT_ATTACHED]    = "MP_STATUS_METER_NOT_ATTACHED"
T.ERROR_DETAILS[T.MP_STATUS_METER_COMMS_ERROR]     = "MP_STATUS_METER_COMMS_ERROR"
T.ERROR_DETAILS[T.MP_STATUS_NO_RESPONSE_FROM_NIC]  = "MP_STATUS_NO_RESPONSE_FROM_NIC"


-- LORA NIC ENDPOINTS
T.METER_UND_CMD                           = 0x80  -- To turn on 8th bit of the header
T.NIC_APP_CMD                             = 0x20  -- To turn on 5th bit of the header
T.METER_APP_CMD                           = 0x40  -- To turn on 6th bit of the header
--T.METER_MGT_CMD                           = 0x20  -- To turn on 5th bit of the header
T.ENDPOINT_NIC                            = 1     -- Endpoint for NIC 
T.ENDPOINT_METERING                       = 2     -- Endpoint for METER 

-- LORA METER ALERT TYPE.
T.YUNGLOONG_LORA_ALERT  = 0
T.MICOM_LORA_ALERT      = 1

-- Yung Loong Alerts
T.YL_ALERT = {}
T.YL_ALERT[0x01] = "Case Open"
T.YL_ALERT[0x02] = "Overflow"
T.YL_ALERT[0x03] = "Battery Low"
T.YL_ALERT[0x04] = "Little Leak"
T.YL_ALERT[0x05] = "regular timing to send DEG number out"
T.YL_ALERT[0x06] = "turn on gas meter"
T.YL_ALERT[0x07] = "remote request DEG"
T.YL_ALERT[0x08] = "remote shutoff valve success"
T.YL_ALERT[0x09] = "success to remote reset process"
T.YL_ALERT[0x0A] = "success to setup DEG at gas meter"
T.YL_ALERT[0x0B] = "setting failure"
T.YL_ALERT[0x0C] = "reset shut-off valve success"
T.YL_ALERT[0x0E] = "Success to SYNC timing"
T.YL_ALERT[0x0F] = "success to set up DEG response time"
T.YL_ALERT[0x10] = "little leak detecting"
T.YL_ALERT[0x11] = "flowing parameter and start shut off valve function"
T.YL_ALERT[0x12] = "setting forward SMS center number"
T.YL_ALERT[0x13] = "set up the SMS number for send message out"
T.YL_ALERT[0x14] = "state of external detector as CO detector"
T.YL_ALERT[0x15] = "state of external sensor"
T.YL_ALERT[0x16] = "GSM module Busy"
T.YL_ALERT[0x17] = "GSM module recovery function"
-- 0x18 not defined
T.YL_ALERT[0x19] = "GSM Reset"
T.YL_ALERT[0x1A] = "Check EEPROM"
T.YL_ALERT[0x1B] = "close valve by earthquake"
T.YL_ALERT[0x1C] = "over time parameter setting"
T.YL_ALERT[0x1D] = "trigger gas meter, because over time working"
T.YL_ALERT[0x1E] = "setting parameter at gas meter"
T.YL_ALERT[0x1F] = "close the valve, when pressure of gas is lower than default setting"
T.YL_ALERT[0x20] = "close the valve, when pressure of gas is higher than default setting"
T.YL_ALERT[0x21] = "close the valve after gas close then reset"
T.YL_ALERT[0x22] = "enter the testing mode and setting response message"
T.YL_ALERT[0x23] = "complete setting parameter"
-- 0x24 .. 0x27 not defined
T.YL_ALERT[0x28] = "close valve failure"
T.YL_ALERT[0x29] = "command to close the valve"
T.YL_ALERT[0x2A] = "fail to close the valve"
T.YL_ALERT[0x2B] = "fail to reset valve"
T.YL_ALERT[0x2C] = "shut off Magnetic interference"
T.YL_ALERT[0x2D] = "Shut off because Magetic reed switch broken"
T.YL_ALERT[0x2E] = "Magnetic Interference"
T.YL_ALERT[0x2F] = "check Magetic reed switch"
T.YL_ALERT[0x30] = "over close valve when gas over flow"
T.YL_ALERT[0x31] = "volume shutdown"
T.YL_ALERT[0x32] = "over-time shutdown"
T.YL_ALERT[0x33] = "shut down due to magnetic reed switch test"
T.YL_ALERT[0x34] = "link breakdown shut down"
T.YL_ALERT[0x35] = "value top-up shut down"
T.YL_ALERT[0x63] = "not on time to send data back by gas meter"

-- LORA MICOM ALERTS
T.MICOM_ALERT = {}
T.MICOM_ALERT[1] = {}
T.MICOM_ALERT[2] = {}
T.MICOM_ALERT[3] = {}
T.MICOM_ALERT[4] = {}

T.MICOM_ALERT[1][1] = { code = 0x14, detail = "Shutdown after disabled" }
T.MICOM_ALERT[1][2] = { code = 0x15, detail = "Test alarm activation" }
T.MICOM_ALERT[1][3] = { code = 0x16, detail = "Manual shutdown" }
T.MICOM_ALERT[1][4] = { code = 0x17, detail = "Flow rate exceeding warning" }
T.MICOM_ALERT[1][5] = { code = 0x18, detail = "RAM abnormality" }
--T.MICOM_ALERT[1][6] = { code =  6, detail = "NA" }
--T.MICOM_ALERT[1][7] = { code =  7, detail = "NA" }
--T.MICOM_ALERT[1][8] = { code =  8, detail = "NA" }
T.MICOM_ALERT[2][1] = { code = 0x0C, detail = "Shutdown with pulse during shutdown (Safety duration)" }
T.MICOM_ALERT[2][2] = { code = 0x0D, detail = "Test shutdown" }
T.MICOM_ALERT[2][3] = { code = 0x0E, detail = "Low battery voltage warning" }
T.MICOM_ALERT[2][4] = { code = 0x0F, detail = "Low battery voltage shutdown" }
T.MICOM_ALERT[2][5] = { code = 0x10, detail = "Internal pipe leak warning" }
T.MICOM_ALERT[2][6] = { code = 0x11, detail = "Disable internal pipe leakage warning" }
T.MICOM_ALERT[2][7] = { code = 0x12, detail = "Shutdown notification" }
T.MICOM_ALERT[2][8] = { code = 0x13, detail = "Disable shutdown notification" }
T.MICOM_ALERT[3][1] = { code = 0x04, detail = "Electric shock shutdown (Safety duration, Earthquake)" }
T.MICOM_ALERT[3][2] = { code = 0x05, detail = "Low presssure shutdown" }
T.MICOM_ALERT[3][3] = { code = 0x06, detail = "Alarm shutdown" }
T.MICOM_ALERT[3][4] = { code = 0x07, detail = "Leakage recovery confirmation shutdown (Safety duration)" }
T.MICOM_ALERT[3][5] = { code = 0x08, detail = "Centre shutdown" }
T.MICOM_ALERT[3][6] = { code = 0x09, detail = "HA shutdown" }
T.MICOM_ALERT[3][7] = { code = 0x0A, detail = "Shutdown stand-by set" }
T.MICOM_ALERT[3][8] = { code = 0x0B, detail = "Standby shutdown" }
--T.MICOM_ALERT[4][1] = { code = 25, detail = "NA" }
--T.MICOM_ALERT[4][2] = { code = 26, detail = "NA" }
--T.MICOM_ALERT[4][3] = { code = 27, detail = "NA" }
--T.MICOM_ALERT[4][4] = { code = 28, detail = "NA" }
T.MICOM_ALERT[4][5] = { code = 0x00, detail = "Normal mode" }
T.MICOM_ALERT[4][6] = { code = 0x01, detail = "Total maximum flow rate exceeded shutdown (Safety duration)" }
T.MICOM_ALERT[4][7] = { code = 0x02, detail = "Maximum individual flow rate exceeded shutdown (Safety duration)" }
T.MICOM_ALERT[4][8] = { code = 0x03, detail = "Safety duration exceeded shutdown (Safety duration)" }

-- LORA MICOM METER STATUS
T.MICOM_METERSTATUS = {}
T.MICOM_METERSTATUS[1] = {}
T.MICOM_METERSTATUS[2] = {}
T.MICOM_METERSTATUS[3] = {}
T.MICOM_METERSTATUS[1][1] = "Cline"
T.MICOM_METERSTATUS[1][2] = "Exceeding Flow rate warning" 
T.MICOM_METERSTATUS[1][3] = "Low pressure shutdown bypass"
T.MICOM_METERSTATUS[1][4] = "Oscillation detection shutdown bypass"
T.MICOM_METERSTATUS[1][5] = "Internal pipe leakage timer B1"
T.MICOM_METERSTATUS[1][6] = "Internal pipe leakage timer B2" 
T.MICOM_METERSTATUS[1][7] = "Internal pipe leakage pressure monitor"
T.MICOM_METERSTATUS[1][8] = "NA"
T.MICOM_METERSTATUS[2][1] = "Write protect"
T.MICOM_METERSTATUS[2][2] = "B-Line Selection"
T.MICOM_METERSTATUS[2][3] = "Safety duration start time"
T.MICOM_METERSTATUS[2][4] = "Pressure monitor"
T.MICOM_METERSTATUS[2][5] = "Internal pipe leakage warning display bypass"
T.MICOM_METERSTATUS[2][6] = "Low voltage call"
T.MICOM_METERSTATUS[2][7] = "Maximum individual flow rate exceeded shutdown bypass"
T.MICOM_METERSTATUS[2][8] = "Total maximum flow rate exceeded shutdown bypass"
T.MICOM_METERSTATUS[3][1] = "Call for periodical meter reading"
T.MICOM_METERSTATUS[3][2] = "Low voltage shutdown warning"
T.MICOM_METERSTATUS[3][3] = "Call for load survey"
T.MICOM_METERSTATUS[3][4] = "Conduct load survey"
T.MICOM_METERSTATUS[3][5] = "Pilot flame register"
T.MICOM_METERSTATUS[3][6] = "Type of time extension"
T.MICOM_METERSTATUS[3][7] = "Safety duration"
T.MICOM_METERSTATUS[3][8] = "Safety duration bypass"

-- LORA MICOM METER STATUS MASK
T.SET_MICOM_METERSTATUS_MASK = {}
T.SET_MICOM_METERSTATUS_MASK[1]  = "000001"
T.SET_MICOM_METERSTATUS_MASK[2]  = "000002"
T.SET_MICOM_METERSTATUS_MASK[3]  = "000004"
T.SET_MICOM_METERSTATUS_MASK[4]  = "000008"
T.SET_MICOM_METERSTATUS_MASK[5]  = "000010"
T.SET_MICOM_METERSTATUS_MASK[6]  = "000020" 
T.SET_MICOM_METERSTATUS_MASK[7]  = "000040"
T.SET_MICOM_METERSTATUS_MASK[8]  = "000080"
T.SET_MICOM_METERSTATUS_MASK[9]  = "000100"
T.SET_MICOM_METERSTATUS_MASK[10] = "000200"
T.SET_MICOM_METERSTATUS_MASK[11] = "000400"
T.SET_MICOM_METERSTATUS_MASK[12] = "000800"
T.SET_MICOM_METERSTATUS_MASK[13] = "001000"
T.SET_MICOM_METERSTATUS_MASK[14] = "002000"
T.SET_MICOM_METERSTATUS_MASK[15] = "004000"
T.SET_MICOM_METERSTATUS_MASK[16] = "008000"
T.SET_MICOM_METERSTATUS_MASK[17] = "010000"
T.SET_MICOM_METERSTATUS_MASK[18] = "020000"
T.SET_MICOM_METERSTATUS_MASK[19] = "040000"
T.SET_MICOM_METERSTATUS_MASK[20] = "080000"
T.SET_MICOM_METERSTATUS_MASK[21] = "100000"
T.SET_MICOM_METERSTATUS_MASK[22] = "200000"
T.SET_MICOM_METERSTATUS_MASK[23] = "400000"
T.SET_MICOM_METERSTATUS_MASK[24] = "800000"

-- LORA REQUEST CMD PARAM NAMES & LENGTH TO BE PACKED

T.reqParams = {}   --  Each param contains number of parameters & the paramter names to fetch the data from fcp message & length to pack for teh LoRa payload.
T.reqParams[def.msgid.SET_METER_GAS_VALVE_STATE]        = { 1, "valve_state",                       1 }
T.reqParams[def.msgid.SET_NIC_BATTERY_LIFE]             = { 1, "battery_milliamp_hours_remaining",  2 }
T.reqParams[def.msgid.SET_SUMMATION_REPORT_INTERVAL]    = { 1, "report_interval_mins",              2 }
T.reqParams[def.msgid.SET_PRESSURE_REPORT_INTERVAL]     = { 1, "report_interval_mins",              2 }
T.reqParams[def.msgid.SET_OFLOW_DETECT_ENABLE]          = { 1, "overflow_detect_enable",            1 }
T.reqParams[def.msgid.SET_OFLOW_DETECT_DURATION]        = { 1, "overflow_detect_duration",          2 }
T.reqParams[def.msgid.SET_OFLOW_DETECT_RATE]            = { 1, "overflow_detect_flowrate",          2 }
T.reqParams[def.msgid.SET_PRESSURE_ALARM_LEVEL_LOW]     = { 1, "pressure_alarm_level_low",          1 }
T.reqParams[def.msgid.SET_PRESSURE_ALARM_LEVEL_HIGH]    = { 1, "pressure_alarm_level_high",         1 }
T.reqParams[def.msgid.SET_LEAK_DETECT_RANGE]            = { 1, "leak_detect_range",                 1 }
T.reqParams[def.msgid.SET_MANUAL_RECOVER_ENABLE]        = { 1, "manual_recover_enable",             1 }
T.reqParams[def.msgid.SET_COMMS_MODE]                   = { 1, "meter_comms_mode",                  1 }
T.reqParams[def.msgid.SET_PILOT_LIGHT_MODE]             = { 3, "pilot_light_mode",                  1, "pilot_flow_min", 1, "pilot_flow_max", 1 }
T.reqParams[def.msgid.SET_EARTHQUAKE_SENSOR_STATE]      = { 1, "earthquake_sensor_state",           1 }
T.reqParams[def.msgid.SET_METER_READING_VALUE]          = { 1, "reading_value",                     4 }
--T.reqParams[def.msgid.SET_METER_STATUS]                 = { 2, "status",                            1 }
T.reqParams[def.msgid.SET_METER_CUSTOMERID]             = { 1, "customer_id",                       14 }
T.reqParams[def.msgid.SET_METER_TIME]                   = { 1, "time",                              4 }
T.reqParams[def.msgid.SET_NIC_TIME_CORRECTION]          = { 1, "delta",                             5 }
T.reqParams[def.msgid.SET_NIC_SCHEDULE]                 = { 4, "day_mask",              1, "active_period_start_time", 1, "active_period_end_time", 1,              
                                                               "modes", 1 }
T.reqParams[def.msgid.SET_NIC_MODE]                     = { 3, "mode_id", 1, "MAC_polling_interval", 4, "spreadFactor_confirmation", 1 }

---------------------------------------------------------------------------------------------------
-- Responses
T.resParams = {}
T.resParams[def.msgid.METER_SUMMATION_DELIVERED]        = { 4, "summation_delivered",   "uint64" }
T.resParams[def.msgid.METER_CURRENT_PRESSURE]           = { 4, "current_pressure",      "uint16" }
T.resParams[def.msgid.METER_ALERT]                      = { 1, "alert_type",            "uint32", 8, "alert_details", "string" }                   
T.resParams[def.msgid.GET_METER_TYPE]                   = { 9, "manufacturer",          "string" }
T.resParams[def.msgid.GET_METER_SUMMATION_DELIVERED]    = { 4, "summation_delivered",   "uint64" }
T.resParams[def.msgid.GET_METER_CURRENT_PRESSURE]       = { 4, "current_pressure",      "uint16" }
T.resParams[def.msgid.GET_METER_GAS_VALVE_STATE]        = { 1, "valve_state",           "uint8"  }
T.resParams[def.msgid.SET_METER_GAS_VALVE_STATE]        = { 1, "result_code",           "uint8"  }
T.resParams[def.msgid.GET_SUMMATION_REPORT_INTERVAL]    = { 2, "report_interval_mins",  "uint16" } 
T.resParams[def.msgid.SET_SUMMATION_REPORT_INTERVAL]    = { 1, "result_code",           "uint8"  }
T.resParams[def.msgid.GET_PRESSURE_REPORT_INTERVAL]     = { 2, "report_interval_mins",  "uint16" }
T.resParams[def.msgid.SET_PRESSURE_REPORT_INTERVAL]     = { 1, "result_code",           "uint8"  }
T.resParams[def.msgid.GET_NIC_TIME]                     = { 1, "nic_time",              "uint32" }
T.resParams[def.msgid.GET_NIC_SCHEDULE]                 = { 4, "day_mask",              1, "active_period_start_time", 1, "active_period_end_time", 1,              
                                                               "modes", 1 }
T.resParams[def.msgid.GET_NIC_MODE]                     = { 3, "mode_id", 1, "MAC_polling_interval", 4, "spreadFactor_confirmation", 1 }
T.resParams[def.msgid.GET_NIC_BATTERY_LIFE]             = { 1, "battery_milliamp_hours_remaining", 2}

-- Yungloong commands

T.resParams[def.msgid.GET_OFLOW_DETECT_ENABLE]       = { 1, "overflow_detect_enable",       "uint8" }
T.resParams[def.msgid.SET_OFLOW_DETECT_ENABLE]       = { 1, "result_code",                  "uint8" }
T.resParams[def.msgid.GET_OFLOW_DETECT_DURATION]     = { 1, "overflow_detect_duration",     "uint8" }
T.resParams[def.msgid.SET_OFLOW_DETECT_DURATION]     = { 1, "result_code",                  "uint8" }
T.resParams[def.msgid.GET_OFLOW_DETECT_RATE]         = { 1, "overflow_detect_flowrate",     "uint8" }
T.resParams[def.msgid.SET_OFLOW_DETECT_RATE]         = { 1, "result_code",                  "uint8" }
T.resParams[def.msgid.GET_PRESSURE_ALARM_LEVEL_LOW]  = { 1, "pressure_alarm_level_low",     "uint8" }
T.resParams[def.msgid.SET_PRESSURE_ALARM_LEVEL_LOW]  = { 1, "result_code",                  "uint8" }
T.resParams[def.msgid.GET_PRESSURE_ALARM_LEVEL_HIGH] = { 1, "pressure_alarm_level_high",    "uint8" }
T.resParams[def.msgid.SET_PRESSURE_ALARM_LEVEL_HIGH] = { 1, "result_code",                  "uint8" }
T.resParams[def.msgid.GET_LEAK_DETECT_RANGE]         = { 1, "leak_detect_range",            "uint8" }
T.resParams[def.msgid.SET_LEAK_DETECT_RANGE]         = { 1, "result_code",                  "uint8" }
T.resParams[def.msgid.GET_MANUAL_RECOVER_ENABLE]     = { 1, "manual_recover_enable",        "uint8" }
T.resParams[def.msgid.SET_MANUAL_RECOVER_ENABLE]     = { 1, "result_code",                  "uint8" }
T.resParams[def.msgid.GET_METER_FIRMWARE_VERSION]    = { 21, "version",                     "string" }
T.resParams[def.msgid.GET_METER_SHUTOFF_CODES]       = { 50, "shutoff_codes",               "string" }
T.resParams[def.msgid.GET_ELECTRIC_QNT_VALUE]        = { 1,  "electric_quantity_value",     "uint16" }


-- NIC commands
T.endpoint  =   {}
T.endpoint[ def.name[ def.msgid.GET_NIC_VERSION ] ]                =  T.NIC_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_NIC_BATTERY_LIFE ] ]           =  T.NIC_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_NIC_BATTERY_LIFE ] ]           =  T.NIC_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_NIC_TIME ] ]                   =  T.NIC_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_NIC_TIME_CORRECTION ] ]        =  T.NIC_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_NIC_SCHEDULE ] ]               =  T.NIC_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_NIC_SCHEDULE ] ]               =  T.NIC_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_NIC_MODE ] ]                   =  T.NIC_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_NIC_MODE ] ]                   =  T.NIC_APP_CMD

-- Yung Loong commands              
T.endpoint[ def.name[ def.msgid.METER_SUMMATION_DELIVERED ] ]        = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.METER_CURRENT_PRESSURE ] ]           = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_METER_TYPE ] ]                   = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_METER_SUMMATION_DELIVERED ] ]    = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_METER_CURRENT_PRESSURE ] ]       = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_METER_GAS_VALVE_STATE ] ]        = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_METER_GAS_VALVE_STATE ] ]        = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_SUMMATION_REPORT_INTERVAL ] ]    = T.METER_APP_CMD 
T.endpoint[ def.name[ def.msgid.SET_SUMMATION_REPORT_INTERVAL ] ]    = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_PRESSURE_REPORT_INTERVAL ] ]     = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_PRESSURE_REPORT_INTERVAL ] ]     = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_OFLOW_DETECT_ENABLE ] ]          = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_OFLOW_DETECT_ENABLE ] ]          = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_OFLOW_DETECT_DURATION ] ]        = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_OFLOW_DETECT_DURATION ] ]        = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_OFLOW_DETECT_RATE ] ]            = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_OFLOW_DETECT_RATE ] ]            = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_PRESSURE_ALARM_LEVEL_LOW ] ]     = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_PRESSURE_ALARM_LEVEL_LOW ] ]     = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_PRESSURE_ALARM_LEVEL_HIGH ] ]    = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_PRESSURE_ALARM_LEVEL_HIGH ] ]    = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_LEAK_DETECT_RANGE ] ]            = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_LEAK_DETECT_RANGE ] ]            = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_MANUAL_RECOVER_ENABLE ] ]        = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_MANUAL_RECOVER_ENABLE ] ]        = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_METER_FIRMWARE_VERSION ] ]       = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_METER_SHUTOFF_CODES ] ]          = T.METER_APP_CMD

-- Micom commands
T.endpoint[ def.name[ def.msgid.GET_METER_READING_VALUE ] ]          = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_METER_READING_VALUE ] ]          = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_METER_STATUS ] ]                 = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_METER_STATUS ] ]                 = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_METER_CUSTOMERID ] ]             = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_METER_CUSTOMERID ] ]             = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_METER_TIME ] ]                   = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_METER_TIME ] ]                   = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_CONFIG_CENTER_SHUTDOWN ] ]       = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_CONFIG_DISABLE_CENTER_SHUTDOWN ] ]    = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_PROTOCOL_VERSION ] ]             = T.METER_APP_CMD


-- Yung Loong Commands
T.endpoint[ def.name[ def.msgid.GET_METER_SERIAL_NUMBER ] ]             = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_METER_SERIAL_NUMBER ] ]             = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_ELECTRIC_QNT_VALUE ] ]         = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_COMMS_MODE ] ]                      = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_COMMS_MODE ] ]                      = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_PILOT_LIGHT_MODE ] ]                = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_PILOT_LIGHT_MODE ] ]                = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.GET_EARTHQUAKE_SENSOR_STATE ] ]         = T.METER_APP_CMD
T.endpoint[ def.name[ def.msgid.SET_EARTHQUAKE_SENSOR_STATE ] ]         = T.METER_APP_CMD

