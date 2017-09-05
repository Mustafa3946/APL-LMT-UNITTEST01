---------------------------------------------------------------------------------------------------
-- Purpose: Container for list of fragmented messages in play
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
local frag      = require("src.fragmentedMessage")
local bit       = require("bit")
local fme       = require(def.module.fme)

local FragmentMessageMgr = {}
FragmentMessageMgr.PAYLOAD_BYTE_MAX = 8

---------------------------------------------------------------------------------------------------
-- Incoming fragment message
FragmentMessageMgr.new = function(func_getNextPktId)
    local self = {}
    self.getNextPktId = func_getNextPktId
    self.fragmentMsg = {}
    self.seqid = 0
    
    ---------------------------------------------------------------------------------------------------
    self.getFragmentSeqId = function ()
        if self.seqid > 255 then
            self.seqid = 0
        end

        self.seqid = self.seqid + 1

        return self.seqid
    end 
 
    ---------------------------------------------------------------------------------------------------
    self.checkTimeouts = function ()
        for seqid, frag in pairs(self.fragmentMsg) do
            if self.fragmentMsg[seqid].isTimedout() then
                self.fragmentMsg[seqid] = nil
                print("Incoming fragment timed out")
            end
        end
    end 
 
    ---------------------------------------------------------------------------------------------------
    -- A fragmented message bytes are formatted thus:
    -- header, cmd, seqid, one or more payload bytes (ie 4+)
    -- The seqid shall be the same for all the fragments in this message
    -- When we enter here we don't know if it's a fragment or not.
    self.handleFragmentMsg = function(wholeNicPkt)
        local isCompleteMsg = true
        local isFragment = false
        local wholeMsg = wholeNicPkt
        if string.len(wholeNicPkt) >= 4 then
            local seqid = LoraUtils.getSeqid(wholeNicPkt)
            if self.isNewFragMsg(wholeNicPkt) then
                self.fragmentMsg[seqid] = frag.new(wholeNicPkt)
                isFragment = true
                isCompleteMsg = false
            elseif self.matchesExistingFrag(wholeNicPkt) then              
                isFragment, isCompleteMsg, wholeMsg = self.fragmentMsg[seqid].process(wholeNicPkt)
                if isCompleteMsg then
                    self.fragmentMsg[seqid] = nil
                end
            else
            end
        else
        end
        
        return isFragment, isCompleteMsg, wholeMsg
    end    

    ---------------------------------------------------------------------------------------------------
    -- 
    self.matchesExistingFrag = function(wholeNicPkt)
        local seqid = LoraUtils.getSeqid(wholeNicPkt)

        return (self.fragmentMsg[seqid] ~= nil) --and self.fragmentMsg[seqid].isNextFrag(wholeNicPkt)
    end

    ---------------------------------------------------------------------------------------------------
    self.isNewFragMsg = function(wholeNicPkt)
        return LoraUtils.isFragBitSet(wholeNicPkt) and not self.matchesExistingFrag(wholeNicPkt) 
    end
    
    ---------------------------------------------------------------------------------------------------
    self.sendAsFragments = function(reqmsg, payload)
        local ep = loradef.ENDPOINT_METERING
        local msgid = reqmsg["msgid"]
        --local cmd = LoraUtils.msgidToNicCmd(msgid)
        local cmd = msgid - ( loradef.ENDPOINT_METERING * 100)
        local txfrags, seq = self.makeTxFrags(self.getNextPktId, ep, cmd, payload)
 
        local nicmsg = {}
        nicmsg["TYPE"]      = "L1" 
        nicmsg["msgid"]     = msgid
        nicmsg["msgname"]   = reqmsg["msgname"]
        nicmsg["eid"]       = reqmsg["eid"]
        nicmsg["cid"]       = reqmsg["cid"] 
        local index = 1
        local firstPktId = nil
        while txfrags[index] ~= nil do
            local wholeNicPkt = txfrags[index]
            nicmsg["payload"] = wholeNicPkt
            fme.sendmessage(def.fmeContext, nicmsg) -- L1 msg:  processLoraRequest - frag
            fme.sleep(1) -- Hack to deal with problem in LoRa server losing message fragments sent out quickly
            index = index + 1
            -- And print some debug
            local cmd       = string.format("%02x", LoraUtils.getCmdFromResponse(wholeNicPkt))
            local isfrag    = tostring(LoraUtils.isFragBitSet(wholeNicPkt))
            local pktId     = LoraUtils.getPktId(wholeNicPkt)
            print("App=>NIC: Fragment [TID ", pktId, " FragBit: ", isfrag, " cmd ", cmd, 
                " seq ", seq, " ", reqmsg["msgname"]," EID:", reqmsg["eid"], wholeNicPkt)
            LoraUtils.printTable(nicmsg)
            if firstPktId == nil then
                firstPktId = pktId
            end
        end
        
        return txfrags, firstPktId, seq 
    end 
    
    ---------------------------------------------------------------------------------------------------
    -- return a table of fragments to be transmitted
    self.makeTxFrags = function(func_getPktId, ep, cmd, payload)
        local index = 1
        local fragNum = loradef.FRAGMENT_1
        local remaining = payload
        local slice
        local fragPayload = ""
        local fragments = {}
        local lastCmd   = string.format("%02x", cmd)
        local done = false
        local first = true
        local cmdHex, cmdByte, currIndex
        local seq = self.getFragmentSeqId()
        while not done do
            if first then
                cmdByte = cmd           
                first = false
            else
                cmdByte = fragNum
                fragNum = fragNum - 1     
            end
            local seqStr = string.format("%02x", seq)
            if string.len(remaining) > FragmentMessageMgr.PAYLOAD_BYTE_MAX*2 then
                slice = string.sub(remaining, 1, FragmentMessageMgr.PAYLOAD_BYTE_MAX*2)
                cmdHex = string.format("%02x", 0x80 + cmdByte)
                remaining = string.sub(remaining, FragmentMessageMgr.PAYLOAD_BYTE_MAX*2+1)
            else -- last fragment, frag bit not set
                slice = string.sub(remaining, 1)
                cmdHex = string.format("%02x", cmdByte)
                done = true
            end

            local pid = func_getPktId()
            local hdrByte   = bit.bor(pid, bit.lshift(ep, 5))
            local hdrStr    = string.format("%02x", hdrByte)        
            fragments[index] = hdrStr .. cmdHex .. seqStr .. slice
            index = index + 1
        end

        return fragments, seq
    end    
    
    return self
end

return FragmentMessageMgr