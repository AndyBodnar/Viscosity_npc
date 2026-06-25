-- ============================================================================
--  Viscosity_npc  ·  (c) 2026 AndyBodnar (Viscosity)
--  https://github.com/AndyBodnar/Viscosity_npc
--  Server use only. No resale, repackaging, or credit removal. See LICENSE.
-- ============================================================================
-- ============================================================
--  Viscosity AI NPCs — speech-to-text (server)
--  Hands the audio to the local Groq STT bridge (bridge/server.js),
--  which uploads it to Groq Whisper correctly (Node handles binary).
--  Returns the transcript text. AiSTT.Transcribe(b64, cb) -> text|nil.
-- ============================================================

AiSTT = {}

function AiSTT.Transcribe(b64, cb)
    local key = GetConvar("ai:groqKey", "")
    if key == "" then return cb(nil, "no_groq_key") end

    local port = GetConvar("ai:bridgePort", "30200")
    local url = ("http://127.0.0.1:%s/transcribe"):format(port)

    PerformHttpRequest(url, function(status, body)
        if status == 0 then
            print("[ai_npcs] STT bridge unreachable — is start-bridge.bat running?")
            return cb(nil, "bridge_down")
        end
        if status ~= 200 or not body then
            print(("[ai_npcs] STT bridge http %s: %s"):format(tostring(status), tostring(body):sub(1, 200)))
            return cb(nil, "http_" .. tostring(status))
        end
        local ok, data = pcall(json.decode, body)
        local text = ok and data and data.text
        if text and text ~= "" then
            print(("[ai_npcs] STT heard: %q"):format(tostring(text):sub(1, 80)))
            cb(text)
        else
            cb(nil, "empty")
        end
    end, "POST", json.encode({ audio = b64, key = key }), { ["Content-Type"] = "application/json" })
end
