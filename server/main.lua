-- ============================================================================
--  Viscosity_npc  ·  (c) 2026 AndyBodnar (Viscosity)
--  https://github.com/AndyBodnar/Viscosity_npc
--  Server use only. No resale, repackaging, or credit removal. See LICENSE.
-- ============================================================================
-- ============================================================
--  Viscosity AI NPCs — server events
--  Bridges client talk requests to the LLM and returns the reply.
-- ============================================================

local PERSONA = table.concat({
    "You are a random pedestrian in Los Santos (a parody of Los Angeles in GTA V).",
    "Stay fully in character: street-smart, casual, sometimes rude, sometimes funny.",
    "Reply in ONE or two short sentences. No narration, no stage directions,",
    "no quotation marks, no emojis. Just what the character says out loud.",
}, " ")

local function respond(src, text)
    local provider = GetConvar("ai:provider", "groq")
    print(("[ai_npcs] /talkto from %s via %s: %q"):format(src, provider, tostring(text):sub(1, 80)))
    local sys = PERSONA .. (Rep and Rep.Summary(src) or "")  -- inject what the NPC "remembers"
    AiLLM.Chat(sys, tostring(text):sub(1, 200), function(reply, err)
        if reply then
            print(("[ai_npcs] ^2text OK^7: %q"):format(tostring(reply):sub(1, 100)))
            TriggerClientEvent("viscosity_ai_npcs:client:reply", src, reply)
        else
            print(("[ai_npcs] ^1text FAILED^7: %s"):format(tostring(err)))
            local msg = (err == "no_key") and "(no AI key set — see server.cfg)" or ("(failed: " .. tostring(err) .. ")")
            TriggerClientEvent("viscosity_ai_npcs:client:reply", src, msg)
        end
    end)
end

-- typed: /talkto
RegisterNetEvent("viscosity_ai_npcs:server:talk", function(message)
    respond(source, message or "")
end)

-- spoken: NUI audio -> Groq STT bridge -> Groq LLM reply
RegisterNetEvent("viscosity_ai_npcs:server:voice", function(b64)
    local src = source
    AiSTT.Transcribe(b64, function(text, err)
        if not text then
            local msg = (err == "bridge_down") and "(voice bridge offline — run start-bridge.bat)"
                or (err == "no_groq_key") and "(no Groq key set)"
                or (err == "empty") and "(didn't catch that — try again)"
                or ("(voice failed: " .. tostring(err) .. ")")
            TriggerClientEvent("viscosity_ai_npcs:client:reply", src, msg)
            return
        end
        respond(src, text)   -- NPC reply via the Groq text path
    end)
end)
