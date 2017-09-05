---------------------------------------------------------------------------------------------------
-- Purpose: Request Groups
--
-- Author:  Alan Barker
--
-- Details: 
--    
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

local def       = require("src.defines")
local loradef   = require("src.loradef")
--local utils     = require("lib.fs-utils.fs-gp-utils")
local bit       = require("bit")

local FragmentMessage = {}
local PAYLOAD_IDX_SID_START     = 5
local PAYLOAD_IDX_SID_END       = 6
local PAYLOAD_IDX_FRG_START     = 7
local PAYLOAD_IDX_NOFRG_START   = 5

FragmentMessage.PKT_BYTES_MAX           = 11

---------------------------------------------------------------------------------------------------
-- This is strictly about requests, which have a 2 byte preamble
FragmentMessage.belowFragmentLimit = function(payload)
    -- Unfrag packet overhead bytes = hdr + cmd byte. = 2 bytes
    return (string.len(payload) + 2 <= FragmentMessage.PKT_BYTES_MAX)
end

---------------------------------------------------------------------------------------------------
FragmentMessage.passAsFirstFrag = function(wholeNicPkt)
    return string.len(wholeNicPkt) == 2*FragmentMessage.PKT_BYTES_MAX
end

---------------------------------------------------------------------------------------------------
-- Only correct for the secon fragment onwards
FragmentMessage.fragNumber = function(cmd)
    return loradef.FRAGMENT_1 - cmd + 2
end

---------------------------------------------------------------------------------------------------
-- Incoming fragment message
FragmentMessage.new = function(wholeNicPkt)
    local self = {}
    
    self.error = false
    self.created = false
    self.header = LoraUtils.getHdrByte(wholeNicPkt)
    self.cmd = LoraUtils.getCmdFromResponse(wholeNicPkt)
    self.fragments = {}
    self.index = 1
    self.timeoutTime = os.time() + def.INCOMING_FRAG_TIMEOUT
    
    -- The first fragment must by definition have the maximum number of bytes possible in a packet
    if FragmentMessage.passAsFirstFrag(wholeNicPkt) then
        self.fragments[self.index] = LoraUtils.getFragPayload(wholeNicPkt)
        self.created = true
        --utils.dbSafePrint(1, "FragmentMessage Instantiated")
    end

    ---------------------------------------------------------------------------------------------------
    self.isTimedout = function()
        return os.time() >= self.timeoutTime
    end

    ---------------------------------------------------------------------------------------------------
    self.isDuplicate = function(infrag)
        local duplicate = false
        for _, frag in pairs(self.fragments) do
            if frag == infrag then
                duplicate = true
                break
            end
        end
        
        return duplicate
    end

    ---------------------------------------------------------------------------------------------------
    -- When we get here this may or may not be a fragment, but if it is a fragment it is for us.
    -- All we know is that a fragment with this seqid has begun, and the 3rd byte of this packet
    -- matches our seqno.
    self.process = function(wholeNicPkt)
        local isFrag = false
        local isComplete = true
        local completeMsg = wholeNicPkt
        if not self.isDuplicate(wholeNicPkt) then
            local cmd = LoraUtils.getCmdFromResponse(wholeNicPkt)
            local index = FragmentMessage.fragNumber(cmd)
            if self.fragments[index] == nil then
                if index - self.index == 1 then
                    self.index = index
                    isFrag = true
                    isComplete = false
                    local payload = LoraUtils.getFragPayload(wholeNicPkt)
                    self.fragments[index] = payload
                    if self.isLastFrag(wholeNicPkt) then
                        if self.isComplete(index) then
                            local wholePayload =  self.assemble(index)
                            local status = loradef.MP_STATUS_SUCCESS
                            -- Echo back the header because we index fragments against the last pktId
                            local header = LoraUtils.getHdrByte(wholeNicPkt)
                            completeMsg = string.format("%02x%02x", header, self.cmd) .. wholePayload
                            isComplete = true
                        end
                    end
                else -- out of order
                    -- 
                    isComplete = false
                end
            else -- duplicate
                isFrag = true
                isComplete = false
            end
        else
            isComplete = false
        end
        
        return isFrag, isComplete, completeMsg
    end
 
    ---------------------------------------------------------------------------------------------------
    self.isComplete = function(lastIndex)
        local isComplete = true
        for fragidx = 1, lastIndex do
            if self.fragments[fragidx] == nil then
                isComplete = true
                break
            end
        end

        return isComplete
    end
 
    ---------------------------------------------------------------------------------------------------
    self.assemble = function(lastIndex)
        local wholePayload = ""
        for fragidx = 1, lastIndex do
            if self.fragments[fragidx] ~= nil then
                wholePayload = wholePayload .. self.fragments[fragidx]
            else
                self.error = true
                break
            end
        end

        return wholePayload
    end
 
    ---------------------------------------------------------------------------------------------------
    -- FRAGMENT_n cmds start at 0x7F and go down, so the next frag has cmd one less than the last one.
    self.isNextFrag = function(wholeNicPkt)
        local rxcmd = LoraUtils.getCmdFromResponse(wholeNicPkt)       
        local currFragNum = FragmentMessage.fragNumber(rxcmd)
        
        return (self.fragments[rxcmd] == nil) and (currFragNum - self.index == 1)
    end

    ---------------------------------------------------------------------------------------------------
    -- The frag bit is not set in the last fragment 
    self.isLastFrag = function(wholeNicPkt)
        return (LoraUtils.isFragBitSet(wholeNicPkt) == false)
    end

    ---------------------------------------------------------------------------------------------------
    self.getFragSeqNum = function(payload)
        return tonumber( string.sub (payload, PAYLOAD_IDX_SID_START, PAYLOAD_IDX_SID_END ), 16 )
    end

    return self
end

return FragmentMessage


