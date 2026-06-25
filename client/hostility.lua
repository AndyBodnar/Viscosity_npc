-- ============================================================================
--  Viscosity_npc  ·  (c) 2026 AndyBodnar (Viscosity)
--  https://github.com/AndyBodnar/Viscosity_npc
--  Server use only. No resale, repackaging, or credit removal. See LICENSE.
-- ============================================================================
-- ============================================================
--  Viscosity AI NPCs — carjack hostility (client)
--  Try to jack an occupied vehicle and the occupants pile out
--  with heavy weapons and attack you. Plus armed reinforcements.
-- ============================================================

Hostility = {}

local HOSTILE_GROUP = `VIS_HOSTILE`
local cooldownUntil = 0

CreateThread(function()
    AddRelationshipGroup("VIS_HOSTILE")
    SetRelationshipBetweenGroups(5, HOSTILE_GROUP, `PLAYER`)   -- 5 = hate
    SetRelationshipBetweenGroups(5, `PLAYER`, HOSTILE_GROUP)
end)

-- Turn a ped into a furious, heavily-armed attacker.
local function makeHostile(ped, target)
    if not DoesEntityExist(ped) then return end
    NetworkRequestControlOfEntity(ped)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedRelationshipGroupHash(ped, HOSTILE_GROUP)

    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then TaskLeaveVehicle(ped, veh, 4160) end

    local weapon = Config.Hostility.weapons[math.random(#Config.Hostility.weapons)]
    GiveWeaponToPed(ped, weapon, 250, false, true)
    SetCurrentPedWeapon(ped, weapon, true)

    SetPedAccuracy(ped, Config.Hostility.accuracy or 55)
    SetPedCombatAttributes(ped, 46, true)   -- always fight
    SetPedCombatAttributes(ped, 5, true)    -- can use cover/vehicles
    SetPedCombatAttributes(ped, 0, true)    -- can use weapon swaps
    SetPedCombatRange(ped, 2)               -- engage from far
    SetPedCombatMovement(ped, 3)            -- offensive (push the player)
    SetPedCombatAbility(ped, 2)             -- professional
    SetPedFleeAttributes(ped, 0, false)     -- never flee
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedAsEnemy(ped, true)
    SetPedDropsWeaponsWhenDead(ped, true)
    TaskCombatPed(ped, target, 0, 16)
end

function Hostility.Trigger(veh)
    local target = PlayerPedId()
    local first

    -- a jacking is a reported crime (heat + possible police dispatch)
    TriggerServerEvent("viscosity_ai_npcs:server:reportCrime", "carjack")

    -- ONLY the peds already in the targeted vehicle react — no spawned peds.
    for seat = -1, 4 do
        local occ = GetPedInVehicleSeat(veh, seat)
        if occ ~= 0 and occ ~= target and not IsPedAPlayer(occ) then
            first = first or occ
            makeHostile(occ, target)
        end
    end

    -- instant shout over the driver (no LLM wait)
    if first then
        local shout = Config.Hostility.shouts[math.random(#Config.Hostility.shouts)]
        AiNpc.Say(first, shout, 4000)
    end
end

-- Watch for jack attempts.
CreateThread(function()
    while true do
        Wait(150)
        if Config.Hostility.enabled then
            local ped = PlayerPedId()
            if IsPedJacking(ped) and GetGameTimer() > cooldownUntil then
                cooldownUntil = GetGameTimer() + (Config.Hostility.cooldown or 8000)
                local veh = GetVehiclePedIsTryingToEnter(ped)
                if veh == 0 then veh = GetVehiclePedIsIn(ped, true) end
                if veh ~= 0 then Hostility.Trigger(veh) end
            end
        end
    end
end)
