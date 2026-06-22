-- ============================================================
--  Viscosity AI NPCs — reputation / memory (server)
--  NPCs report crimes -> heat accrues per player. Heat drives the
--  police response AND the NPC dialogue (a known murderer gets
--  terrified NPCs). Decays slowly so it cools off.
-- ============================================================

Rep = {}

local heat = {}   -- [src] = { score = n, counts = { murder = 2, ... } }

local function entry(src)
    heat[src] = heat[src] or { score = 0, counts = {} }
    return heat[src]
end

function Rep.Add(src, crime)
    if not Config.Crime.enabled then return end
    local pts = Config.Crime.points[crime] or 5
    local h = entry(src)
    h.score = h.score + pts
    h.counts[crime] = (h.counts[crime] or 0) + 1
    print(("[ai_npcs] crime '%s' by %s — heat now %d"):format(crime, src, h.score))

    -- dispatch police once over the threshold
    if h.score >= Config.Crime.dispatchThreshold then
        TriggerClientEvent("viscosity_ai_npcs:client:dispatch", src, h.score)
    end
    TriggerEvent("viscosity_ai_npcs:server:crimeLogged", src, crime, h.score)
end

function Rep.Score(src)
    return heat[src] and heat[src].score or 0
end

-- One-line memory string for the LLM persona.
function Rep.Summary(src)
    local h = heat[src]
    if not h or h.score == 0 then return "" end
    local parts = {}
    for c, n in pairs(h.counts) do parts[#parts + 1] = n .. "x " .. c end
    local mood = h.score >= 40 and "terrified" or h.score >= 20 and "very wary" or "uneasy"
    return ("\n\nYou recognize this person as a known local criminal (%s). You are %s of them — let it color your reply.")
        :format(table.concat(parts, ", "), mood)
end

-- slow cooldown
CreateThread(function()
    while true do
        Wait(60000)
        for src, h in pairs(heat) do
            h.score = math.max(0, h.score - (Config.Crime.decayPerMin or 3))
            if h.score == 0 then h.counts = {} end
        end
    end
end)

RegisterNetEvent("viscosity_ai_npcs:server:reportCrime", function(crime)
    Rep.Add(source, crime)
end)

-- arrest -> sentence length (months) from heat, sent back to the client; slate cleared
RegisterNetEvent("viscosity_ai_npcs:server:beginSentence", function()
    local src = source
    local score = Rep.Score(src)
    local cfg = Config.Prison or {}
    local months = math.max(cfg.minMonths or 5, math.min(math.floor(score), cfg.maxMonths or 600))
    print(("[ai_npcs] %s sentenced to %d months (heat %d)"):format(src, months, score))
    heat[src] = nil
    TriggerClientEvent("viscosity_ai_npcs:client:sentence", src, months)
end)

AddEventHandler("playerDropped", function()
    heat[source] = nil
end)

exports("GetHeat", function(src) return Rep.Score(src) end)
