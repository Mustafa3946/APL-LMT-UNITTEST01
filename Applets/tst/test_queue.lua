#!/usr/bin/env lua
---------------------------------------------------------------------------------------------------
-- Purpose: Remote Terminal Unit:  Utilities 
--
-- Author:  Jeremy Kincaid
--
-- Details: This file contains the code required to perform basic communication with a Remote 
--          Terminal Unit (XARTU/1) from Eagle Research Coorporation, using ERC HexASCII
--          protocol.
--
--          The system expects the RTU to be connected to the Gateway via a MOXA (serial to ethernet
--          adapter)
--
-- Copyright Statement:
-- Copyright © 2014 Freestyle Technology Pty Ltd
-- This contents of this publication may not be reproduced in any part or as a whole, stored, 
-- transcribed in an information retrieval system, translated into -- any language, or transmitted 
-- in any form or by any means, mechanical, electronic, optical, photocopying, manual, or otherwise, 
-- without prior written permission.
-- www.freestyletechnology.com.au
-- This document is subject to change without notice.
---------------------------------------------------------------------------------------------------

local onWindows = (os.getenv("OS") == "Windows_NT")
local defs
---------------------------------------------------------------------------------------------------

if not onWindows then -- select real modules
    defs = require "src.defines"
else
    defs = require "src.defines"
end

local utils = require(defs.module.utils)

-- create
require(defs.module.rtu_queue)
local testQueue = Queue.new()
-- check size (should be 0)
assert(testQueue.size() == 0, "Queue size not 0")
-- check max size (should be 5)
assert(testQueue.getMaxSize() == 5, "Max queue size not 5")

-- add 5 messages
local count = 0

while count < 5 do
	local msg = {}
	msg["Name"] = "name: " .. count
	-- location of added messages should increment to 5
	assert(testQueue.push(msg) == count, "invalid 'add' location for message")
	-- check size (should be 5)
	assert(testQueue.size() == (count + 1), "Invalid count in queue rx " ..testQueue.size() .. " expected " .. (count + 1) )
	count = count + 1
end
-- add one more message (should fail, returns nil)
assert(testQueue.push(msg) == nil, "Failed to reject message")
-- read messages (should read 5)
count = 0
while( count < 5 ) do
	-- check retrieved message are not nil
	msg = testQueue.pop()
	assert(msg ~= nil, "invalid message popped")
	assert(msg["Name"] == "name: " .. count, "invalid message at location " .. count)
	-- check size (should be 0)
	assert(testQueue.size() == (4 - count), "Invalid size in queue")
  count = count + 1
end