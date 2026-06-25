-- ============================================================================
--  Viscosity_npc  ·  (c) 2026 AndyBodnar (Viscosity)
--  https://github.com/AndyBodnar/Viscosity_npc
--  Server use only. No resale, repackaging, or credit removal. See LICENSE.
-- ============================================================================
-- ============================================================
--  Viscosity AI NPCs — crime detection (client)
--  Kills the native GTA wanted system and reports witnessed
--  crimes to the server (which accrues heat + dispatches police).
-- ============================================================

local seenDead = {}   -- ped handles already counted as kills

local function report(crime)
    TriggerServerEvent("viscosity_ai_npcs:server:reportCrime", crime)
end

-- branded toast via the shared core notify system (safe if core isn't loaded yet)
local function notify(msg, kind)
    pcall(function()
        exports.viscosity_core:Notify({ title = "Dispatch", message = msg, type = kind or "police" })
    end)
end

-- loud proof-of-life that this client script is actually running
CreateThread(function()
    Wait(3000)
    print("[ai_npcs] CRIME SYSTEM ONLINE (client)")
    notify("Crime system online", "info")
end)

-- A witness = a living, non-player ped near the crime (not the victim).
local function witnessed(coords, victim)
    for _, p in ipairs(GetGamePool("CPed")) do
        if p ~= victim and not IsPedAPlayer(p) and not IsPedDeadOrDying(p, true) then
            if #(coords - GetEntityCoords(p)) < 35.0 then return true end
        end
    end
    return false
end

-- Suppress GTA's star system entirely — we run our own police logic.
CreateThread(function()
    SetMaxWantedLevel(0)
    local pid = PlayerId()
    while true do
        Wait(0)
        if GetPlayerWantedLevel(pid) ~= 0 then
            SetPlayerWantedLevel(pid, 0, false)
            SetPlayerWantedLevelNow(pid, false)
        end
    end
end)

-- Detect kills + shootings.
CreateThread(function()
    print(("[ai_npcs] crime detection running (enabled=%s)"):format(tostring(Config.Crime and Config.Crime.enabled)))
    while true do
        Wait(350)
        if Config.Crime and Config.Crime.enabled then
            local player = PlayerPedId()
            local pc = GetEntityCoords(player)

            for _, p in ipairs(GetGamePool("CPed")) do
                if p ~= player and p ~= 0 and not IsPedAPlayer(p) and not seenDead[p] and IsEntityDead(p) then
                    local byPlayer = HasEntityBeenDamagedByEntity(p, player, true)
                        or GetPedSourceOfDeath(p) == player
                    seenDead[p] = true   -- count once either way
                    if byPlayer then
                        print(("[ai_npcs] kill detected (ped %s)"):format(p))
                        notify("Kill witnessed — units dispatched", "error")
                        report("murder")
                    end
                end
            end

            if IsPedShooting(player) and witnessed(pc, player) then
                print("[ai_npcs] shooting near witnesses")
                report("shooting")
                Wait(3500)   -- debounce repeated shots
            end
        end
    end
end)
