local network_id = "FreeFlyCameraSync"

-- Sending
Hooks:PostHook(NetworkPeer, "send", "FreeflySync", function(self, func_name, ...)
    if self ~= managers.network:session():local_peer() and func_name == "lobby_info" then
        LuaNetworking:SendToPeer(self:id(), network_id, "1")
    end
end)

-- Receiving
Hooks:Add("NetworkReceivedData", "RaidWW2MiniGameSendReceive", function(sender, id, data)
    if sender == 1 and id == network_id and FFC then
        FFC.host_has_mod = true
    end
end)