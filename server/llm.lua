-- ============================================================
--  Viscosity AI NPCs — LLM bridge (server)
--  Calls Gemini or Groq from the SERVER. Keys come from convars
--  (ai:geminiKey / ai:groqKey), never the client. AiLLM.Chat is
--  async (callback with the reply text or nil).
-- ============================================================

AiLLM = {}

local function groq(system, user, cb)
    local key = GetConvar("ai:groqKey", "")
    if key == "" then return cb(nil, "no_key") end
    PerformHttpRequest("https://api.groq.com/openai/v1/chat/completions", function(status, body)
        if status ~= 200 or not body then return cb(nil, "http_" .. tostring(status)) end
        local ok, data = pcall(json.decode, body)
        local msg = ok and data and data.choices and data.choices[1] and data.choices[1].message
        cb(msg and msg.content or nil)
    end, "POST", json.encode({
        model = GetConvar("ai:groqModel", "llama-3.1-8b-instant"),
        messages = {
            { role = "system", content = system },
            { role = "user", content = user },
        },
        max_tokens = 120,
        temperature = 0.9,
    }), {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. key,
    })
end

local function gemini(system, user, cb)
    local key = GetConvar("ai:geminiKey", "")
    if key == "" then return cb(nil, "no_key") end
    local model = GetConvar("ai:geminiModel", "gemini-2.0-flash")
    local url = ("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"):format(model)
    local payload = json.encode({
        contents = { { parts = { { text = system .. "\n\nPlayer: " .. user } } } },
        generationConfig = { maxOutputTokens = 120, temperature = 0.9 },
    })
    local headers = { ["Content-Type"] = "application/json", ["x-goog-api-key"] = key }

    local function attempt(n)
        PerformHttpRequest(url, function(status, body)
            if status == 429 and n < 3 then
                print(("[ai_npcs] text 429 rate-limited — retry %d/2 in %ds"):format(n, n * 2))
                SetTimeout(n * 2000, function() attempt(n + 1) end)
                return
            end
            if status ~= 200 or not body then
                print(("[ai_npcs] text Gemini http %s: %s"):format(tostring(status), tostring(body):sub(1, 300)))
                return cb(nil, "http_" .. tostring(status))
            end
            local ok, data = pcall(json.decode, body)
            local cand = ok and data and data.candidates and data.candidates[1]
            local text = cand and cand.content and cand.content.parts and cand.content.parts[1] and cand.content.parts[1].text
            cb(text)
        end, "POST", payload, headers)
    end
    attempt(1)
end

function AiLLM.Chat(system, user, cb)
    if GetConvar("ai:provider", "groq") == "gemini" then
        gemini(system, user, cb)
    else
        groq(system, user, cb)
    end
end

-- On start: list the models the active provider's key can use, so the exact
-- valid name is visible in console (model names drift over time).
CreateThread(function()
    Wait(1500)
    local provider = GetConvar("ai:provider", "groq")
    if provider == "gemini" then
        local key = GetConvar("ai:geminiKey", "")
        if key == "" then return end
        PerformHttpRequest("https://generativelanguage.googleapis.com/v1beta/models", function(status, body)
            local ok, data = pcall(json.decode, body or "")
            if status ~= 200 or not (ok and data and data.models) then
                print(("[ai_npcs] gemini model-list http %s"):format(tostring(status))); return
            end
            local names = {}
            for _, m in ipairs(data.models) do
                if m.name and tostring(m.name):find("flash") then names[#names + 1] = tostring(m.name):gsub("models/", "") end
            end
            print("[ai_npcs] ^3available flash models^7: " .. table.concat(names, ", "))
        end, "GET", "", { ["x-goog-api-key"] = key })
    elseif provider == "groq" then
        local key = GetConvar("ai:groqKey", "")
        if key == "" then return end
        PerformHttpRequest("https://api.groq.com/openai/v1/models", function(status, body)
            local ok, data = pcall(json.decode, body or "")
            if status ~= 200 or not (ok and data and data.data) then
                print(("[ai_npcs] groq model-list http %s"):format(tostring(status))); return
            end
            local names = {}
            for _, m in ipairs(data.data) do names[#names + 1] = m.id end
            print("[ai_npcs] ^3available Groq models^7: " .. table.concat(names, ", "))
        end, "GET", "", { ["Authorization"] = "Bearer " .. key })
    end
end)
