-- ============================================================
--  Viscosity AI NPCs — wiring
--  /talkto command + the server reply handler.
-- ============================================================

RegisterCommand("talkto", function(_, args)
    local message = table.concat(args, " ")
    if message == "" then
        AiNpc.Say(PlayerPedId(), "usage: /talkto <what you say>", 3000)
        return
    end

    local npc = AiNpc.GetNearby()
    if not npc then
        AiNpc.Say(PlayerPedId(), "nobody close enough to talk to", 3000)
        return
    end

    AiNpc.SetActive(npc)
    TaskTurnPedToFaceEntity(npc, PlayerPedId(), 1500)
    AiNpc.Say(npc, "…", 8000)   -- thinking indicator while the LLM responds
    TriggerServerEvent("viscosity_ai_npcs:server:talk", message)
end, false)

RegisterNetEvent("viscosity_ai_npcs:client:reply", function(reply)
    local npc = AiNpc.GetActive()
    if npc and DoesEntityExist(npc) then
        AiNpc.Say(npc, reply, Config.ReplyDuration)
    end
    -- speak it out loud via the NUI's text-to-speech
    SendNUIMessage({ type = "speak", text = reply })
end)
