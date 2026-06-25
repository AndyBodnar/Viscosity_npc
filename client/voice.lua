-- ============================================================================
--  Viscosity_npc  ·  (c) 2026 AndyBodnar (Viscosity)
--  https://github.com/AndyBodnar/Viscosity_npc
--  Server use only. No resale, repackaging, or credit removal. See LICENSE.
-- ============================================================================
-- ============================================================
--  Viscosity AI NPCs — push-to-talk voice (client)
--  Hold the key: target the nearest NPC + record. Release: send
--  the audio to the server (Whisper STT -> LLM -> reply bubble).
-- ============================================================

local talking = false

-- NUI sends the recorded clip back here.
RegisterNUICallback("voice", function(d, cb)
    cb(1)
    if d.audio and d.audio ~= "" then
        TriggerServerEvent("viscosity_ai_npcs:server:voice", d.audio)
    end
end)

RegisterNUICallback("micError", function(d, cb)
    cb(1)
    print("[ai_npcs] mic error: " .. tostring(d.error))
    AiNpc.Say(PlayerPedId(), "mic unavailable — check FiveM mic permission", 3500)
end)

-- +command on key press, -command on release (FiveM push-to-talk pattern).
RegisterCommand("+vistalk", function()
    if talking then return end
    local npc = AiNpc.GetNearby()
    if not npc then
        AiNpc.Say(PlayerPedId(), "nobody close enough to talk to", 2500)
        return
    end
    talking = true
    AiNpc.SetActive(npc)
    TaskTurnPedToFaceEntity(npc, PlayerPedId(), 1000)
    SendNUIMessage({ type = "startRec" })
end, false)

RegisterCommand("-vistalk", function()
    if not talking then return end
    talking = false
    SendNUIMessage({ type = "stopRec" })
end, false)

RegisterKeyMapping("+vistalk", "Talk to nearest NPC (hold)", "keyboard", Config.PushToTalkKey or "B")
