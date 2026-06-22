-- ============================================================
--  Viscosity AI NPCs — AiNpc module (client)
--  Finds the nearest pedestrian and renders speech bubbles over
--  it via viscosity_core's DrawText3D export. Pure logic.
-- ============================================================

AiNpc = {}

local active            -- the ped we're currently talking to
local bubble            -- { ped, text, untilT }

-- Single draw loop: shows the current bubble until it expires.
CreateThread(function()
    while true do
        if bubble and DoesEntityExist(bubble.ped) and GetGameTimer() < bubble.untilT then
            local c = GetEntityCoords(bubble.ped)
            exports.viscosity_core:DrawText3D(vec3(c.x, c.y, c.z + 1.05), bubble.text, { scale = 0.42, maxDistance = 25.0 })
            Wait(0)
        else
            bubble = nil
            Wait(150)
        end
    end
end)

-- Nearest living, non-player ped within TalkDistance.
function AiNpc.GetNearby()
    local me = PlayerPedId()
    local coords = GetEntityCoords(me)
    local closest, best = nil, Config.TalkDistance
    for _, p in ipairs(GetGamePool("CPed")) do
        if p ~= me and not IsPedAPlayer(p) and not IsPedDeadOrDying(p, true) then
            local d = #(coords - GetEntityCoords(p))
            if d < best then best = d; closest = p end
        end
    end
    return closest
end

function AiNpc.Say(ped, text, dur)
    bubble = { ped = ped, text = text, untilT = GetGameTimer() + (dur or Config.ReplyDuration) }
end

function AiNpc.SetActive(ped) active = ped end
function AiNpc.GetActive() return active end
