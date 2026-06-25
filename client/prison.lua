-- ============================================================================
--  Viscosity_npc  ·  (c) 2026 AndyBodnar (Viscosity)
--  https://github.com/AndyBodnar/Viscosity_npc
--  Server use only. No resale, repackaging, or credit removal. See LICENSE.
-- ============================================================================
-- ============================================================
--  Viscosity AI NPCs — prison (client)
--  After the perp-walk transport drops you at Bolingbroke, this
--  confines you to the yard and counts down the sentence
--  (months * secondsPerMonth), then releases you at the gate.
-- ============================================================

Prison = {}

local pendingMonths = nil

-- server sends the sentence length (computed from heat)
RegisterNetEvent("viscosity_ai_npcs:client:sentence", function(months)
    pendingMonths = months or Config.Prison.minMonths
end)

local function notify(title, msg, kind)
    pcall(function()
        exports.viscosity_core:Notify({ title = title, message = msg, type = kind or "police" })
    end)
end

-- Called by police transport once you've arrived in the yard.
function Prison.Serve()
    CreateThread(function()
        local player = PlayerPedId()

        -- wait briefly for the sentence value to arrive from the server
        local w = 0
        while pendingMonths == nil and w < 50 do Wait(100); w = w + 1 end
        local months = pendingMonths or Config.Prison.minMonths
        pendingMonths = nil

        local secs = math.max(1, math.floor(months * (Config.Prison.secondsPerMonth or 1)))
        notify("Bolingbroke", ("Sentence: %d months"):format(months), "police")

        local cell = Config.Prison.cell
        local endt = GetGameTimer() + secs * 1000
        while GetGameTimer() < endt do
            local remain = math.ceil((endt - GetGameTimer()) / 1000)
            pcall(function()
                exports.viscosity_core:DrawText2D(0.5, 0.93,
                    ("~p~BOLINGBROKE~s~   %d months remaining"):format(remain),
                    { center = true, scale = 0.5 })
            end)
            DisablePlayerFiring(PlayerId(), true)
            -- keep you inside the yard
            if #(GetEntityCoords(player) - vector3(cell.x, cell.y, cell.z)) > (Config.Prison.bounds or 65.0) then
                SetEntityCoordsNoOffset(player, cell.x, cell.y, cell.z, false, false, false)
            end
            Wait(0)
        end

        -- release
        DoScreenFadeOut(600); Wait(700)
        local r = Config.Prison.release
        SetEntityCoordsNoOffset(player, r.x, r.y, r.z, false, false, false)
        ClearPedTasks(player)
        Wait(400); DoScreenFadeIn(600)
        notify("Released", "You've served your time. Stay clean.", "success")

        if Police and Police.Release then Police.Release() end
    end)
end
