-- ============================================================
--  Viscosity AI NPCs — police (client)  v3
--  Custom arrest AI (no GTA stars). Heat drives an escalation
--  tier: 2 cops -> 4 cops -> SWAT. Units DRIVE IN, bail out, and
--  tase -> cuff -> drive you to Bolingbroke. Lethal only if you
--  shoot. Press the Surrender key (default X) to give up: hands
--  go up, cops stand down and arrest you peacefully.
-- ============================================================

Police = {}

local allCops = {}      -- every live spawned cop
local vehicles = {}     -- spawned cruisers
local lastDispatch = 0
local beingArrested = false
local surrendered = false
local RELGROUP = `VIS_COP`

CreateThread(function()
    AddRelationshipGroup("VIS_COP")
    SetRelationshipBetweenGroups(3, RELGROUP, `PLAYER`)
    SetRelationshipBetweenGroups(3, `PLAYER`, RELGROUP)
end)

local function notify(msg, kind)
    pcall(function()
        exports.viscosity_core:Notify({ title = "Dispatch", message = msg, type = kind or "police" })
    end)
end

local function tierFor(score)
    if score >= 50 then
        return { swat = true,  units = 4, ped = `s_m_y_swat_01`, car = `riot`,    primary = `WEAPON_CARBINERIFLE`, accuracy = 75, armour = 200, label = "SWAT inbound" }
    elseif score >= 28 then
        return { swat = false, units = 4, ped = `s_m_y_cop_01`,  car = `police2`, primary = `WEAPON_PISTOL`,       accuracy = 55, armour = 100, label = "Multiple units dispatched" }
    end
    return     { swat = false, units = 2, ped = `s_m_y_cop_01`,  car = `police`,  primary = `WEAPON_PISTOL`,       accuracy = 50, armour = 100, label = "Police dispatched" }
end

function Police.ClearAll()
    for _, c in ipairs(allCops) do if DoesEntityExist(c) then DeleteEntity(c) end end
    for _, v in ipairs(vehicles) do if DoesEntityExist(v) then DeleteEntity(v) end end
    allCops, vehicles = {}, {}
end

function Police.Release()
    Police.ClearAll()
    beingArrested = false
    surrendered = false
end

-- keep only the escort cop + car; delete the rest
local function keepOnly(keepCop, keepCar)
    for _, c in ipairs(allCops) do
        if DoesEntityExist(c) and c ~= keepCop then DeleteEntity(c) end
    end
    for _, v in ipairs(vehicles) do
        if DoesEntityExist(v) and v ~= keepCar then DeleteEntity(v) end
    end
    allCops = (DoesEntityExist(keepCop)) and { keepCop } or {}
    vehicles = (keepCar and DoesEntityExist(keepCar)) and { keepCar } or {}
end

-- stop every cop from fighting (called the instant an arrest starts / on surrender)
local function standDown()
    for _, c in ipairs(allCops) do
        if DoesEntityExist(c) then
            ClearPedTasksImmediately(c)
            SetCurrentPedWeapon(c, `WEAPON_STUNGUN`, true)
            SetPedCombatAttributes(c, 46, false)
        end
    end
end

local function configCop(cop, tier)
    GiveWeaponToPed(cop, `WEAPON_STUNGUN`, 100, false, true)
    GiveWeaponToPed(cop, tier.primary, 250, false, false)
    SetCurrentPedWeapon(cop, `WEAPON_STUNGUN`, true)
    SetPedArmour(cop, tier.armour)
    SetPedAccuracy(cop, tier.accuracy)
    SetPedSeeingRange(cop, 90.0)
    SetPedHearingRange(cop, 90.0)
    SetPedKeepTask(cop, true)
    SetPedRelationshipGroupHash(cop, RELGROUP)
    SetPedFleeAttributes(cop, 0, false)
    SetPedCombatAttributes(cop, 46, true)
    SetPedCombatAttributes(cop, 5, true)
    SetPedAsCop(cop, true)
    SetPedDropsWeaponsWhenDead(cop, false)
    allCops[#allCops + 1] = cop
end

function Police.Dispatch(score)
    if not Config.Police.enabled or beingArrested then return end
    if GetGameTimer() - lastDispatch < Config.Police.redispatchDelay then return end
    lastDispatch = GetGameTimer()

    local tier = tierFor(score or 10)
    local player = PlayerPedId()
    local pc = GetEntityCoords(player)
    local h = GetEntityHeading(player)

    local rad = math.rad(h + 180.0)
    local bx = pc.x + math.sin(rad) * Config.Police.spawnDistance
    local by = pc.y - math.cos(rad) * Config.Police.spawnDistance
    local found, node, nodeH = GetClosestVehicleNodeWithHeading(bx, by, pc.z, 1, 3.0, 0)
    local sx, sy, sz = pc.x + math.sin(rad) * 60.0, pc.y - math.cos(rad) * 60.0, pc.z
    if found then sx, sy, sz, h = node.x, node.y, node.z, nodeH end

    RequestModel(tier.car); RequestModel(tier.ped)
    local t = 0
    while (not HasModelLoaded(tier.car) or not HasModelLoaded(tier.ped)) and t < 200 do Wait(10); t = t + 1 end
    if not HasModelLoaded(tier.car) or not HasModelLoaded(tier.ped) then return end

    local car = CreateVehicle(tier.car, sx, sy, sz, h, true, false)
    SetVehicleOnGroundProperly(car)
    SetEntityAsMissionEntity(car, true, true)
    SetVehicleSiren(car, true)
    SetVehicleHasMutedSirens(car, false)
    vehicles[#vehicles + 1] = car

    local driver
    for i = 1, tier.units do
        local seat = (i == 1) and -1 or (i - 2)
        local cop = CreatePedInsideVehicle(car, 6, tier.ped, seat, true, false)
        configCop(cop, tier)
        if i == 1 then driver = cop end
    end
    SetModelAsNoLongerNeeded(tier.car); SetModelAsNoLongerNeeded(tier.ped)

    if driver then
        TaskVehicleDriveToCoordLongrange(driver, car, pc.x, pc.y, pc.z, 30.0, 786603, 14.0)
    end
    notify(tier.label, tier.swat and "error" or "police")
end

local function playerLethal()
    if surrendered then return false end
    local p = PlayerPedId()
    return IsPedShooting(p)
        or (IsPlayerFreeAiming(PlayerId()) and GetSelectedPedWeapon(p) ~= `WEAPON_UNARMED`)
end

-- ---------------- surrender ----------------
local function setSurrender(state)
    if beingArrested then return end
    surrendered = state
    local player = PlayerPedId()
    if state then
        notify("Hands up — you're surrendering.", "warning")
        standDown()
        RequestAnimDict("random@mugging3")
        local t = 0
        while not HasAnimDictLoaded("random@mugging3") and t < 100 do Wait(10); t = t + 1 end
        TaskPlayAnim(player, "random@mugging3", "handsup_standing_base", 8.0, -8.0, -1, 49, 0.0, false, false, false)
    else
        ClearPedTasks(player)
    end
end

RegisterCommand("+vissurrender", function()
    if not beingArrested then setSurrender(not surrendered) end
end, false)
RegisterCommand("-vissurrender", function() end, false)
RegisterKeyMapping("+vissurrender", "Surrender (hands up)", "keyboard", "X")

-- tased: screen blacks out and flickers like you're going in and out of
-- consciousness (runs on its own thread so cuffing can happen during it)
local function knockoutFlicker(duration)
    CreateThread(function()
        AnimpostfxPlay("DeathFailNeutralIn", 0, true)
        local endt = GetGameTimer() + duration
        local nextChange, alpha = 0, 255
        while GetGameTimer() < endt do
            if GetGameTimer() > nextChange then
                if math.random() < 0.4 then
                    alpha = math.random(25, 110)    -- a brief glimpse of consciousness
                else
                    alpha = math.random(205, 255)   -- blacked out
                end
                nextChange = GetGameTimer() + math.random(70, 230)
            end
            DrawRect(0.5, 0.5, 2.0, 2.0, 0, 0, 0, alpha)
            Wait(0)
        end
        AnimpostfxStop("DeathFailNeutralIn")
    end)
end

-- ---------------- arrest: tase -> cuff -> transport ----------------
function Police.Subdue(cop, peaceful)
    if beingArrested then return end
    beingArrested = true
    standDown()                      -- everyone stops shooting NOW

    CreateThread(function()
        local player = PlayerPedId()

        if not peaceful then
            SetCurrentPedWeapon(cop, `WEAPON_STUNGUN`, true)
            ClearPedTasks(cop)
            TaskTurnPedToFaceEntity(cop, player, 600)
            TaskAimGunAtEntity(cop, player, 1400, false)
            notify("Stop resisting!", "police")
            Wait(650)
            -- TASED: drop, then black out / flicker while the cop moves in to cuff
            SetPedToRagdoll(player, 5000, 5000, 0, false, false, false)
            ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.5)
            knockoutFlicker(4500)
            local tc = GetEntityCoords(player)
            TaskGoToCoordAnyMeans(cop, tc.x, tc.y, tc.z, 2.0, 0, false, 786603, 0)
            Wait(2300)   -- in and out of consciousness — this is when they cuff you
        else
            notify("Don't move. You're under arrest.", "police")
            Wait(900)
        end

        ClearPedTasksImmediately(player)
        RequestAnimDict("mp_arresting")
        local t = 0
        while not HasAnimDictLoaded("mp_arresting") and t < 100 do Wait(10); t = t + 1 end
        TaskPlayAnim(player, "mp_arresting", "idle", 8.0, -8.0, -1, 49, 0.0, false, false, false)
        notify("You are under arrest.", "police")
        TriggerServerEvent("viscosity_ai_npcs:server:beginSentence")
        Wait(2000)

        Police.Transport(cop)
    end)
end

function Police.Transport(cop)
    CreateThread(function()
        local player = PlayerPedId()
        local pc = GetEntityCoords(player)

        -- nearest cruiser to escort in
        local car, bd = nil, 9999.0
        for _, v in ipairs(vehicles) do
            if DoesEntityExist(v) then
                local d = #(pc - GetEntityCoords(v))
                if d < bd then car, bd = v, d end
            end
        end
        if not car or not DoesEntityExist(car) then car = GetVehiclePedIsIn(cop, false) end

        if car and car ~= 0 and DoesEntityExist(car) and DoesEntityExist(cop) then
            keepOnly(cop, car)                     -- ditch the other units
            notify("Get in the car.", "police")
            ClearPedTasksImmediately(cop)
            ClearPedTasksImmediately(player)
            TaskWarpPedIntoVehicle(player, car, 2) -- back seat
            TaskWarpPedIntoVehicle(cop, car, -1)   -- driver
            Wait(1200)
            notify("En route to Bolingbroke.", "police")

            local g = Config.Prison.gate
            TaskVehicleDriveToCoordLongrange(cop, car, g.x, g.y, g.z, 28.0, 786603, 10.0)

            local timeout = GetGameTimer() + 180000
            while GetGameTimer() < timeout do
                if not DoesEntityExist(car) or not DoesEntityExist(cop) or IsPedDeadOrDying(cop, true) then break end
                if #(GetEntityCoords(player) - vector3(g.x, g.y, g.z)) < 30.0 then break end
                DisableControlAction(0, 75, true)   -- can't bail out
                DisableControlAction(0, 23, true)
                Wait(0)
            end
        else
            DoScreenFadeOut(700); Wait(800); DoScreenFadeIn(700)
        end

        ClearPedTasksImmediately(player)
        local cell = Config.Prison.cell
        SetEntityCoordsNoOffset(player, cell.x, cell.y, cell.z, false, false, false)
        Police.ClearAll()
        if Prison and Prison.Serve then Prison.Serve() end
    end)
end

-- ---------------- the cop brain ----------------
CreateThread(function()
    while true do
        Wait(300)
        if #allCops == 0 or beingArrested then goto continue end
        local player = PlayerPedId()
        local pc = GetEntityCoords(player)
        local lethal = playerLethal()
        local live = {}

        for _, cop in ipairs(allCops) do
            if DoesEntityExist(cop) and not IsPedDeadOrDying(cop, true) then
                live[#live + 1] = cop
                local veh = GetVehiclePedIsIn(cop, false)
                local d = #(pc - GetEntityCoords(cop))

                if lethal then
                    if veh ~= 0 then TaskLeaveVehicle(cop, veh, 0) end
                    SetCurrentPedWeapon(cop, `WEAPON_PISTOL`, true)
                    TaskCombatPed(cop, player, 0, 16)
                elseif veh ~= 0 then
                    if d < 30.0 then TaskLeaveVehicle(cop, veh, 0) end
                else
                    if IsPedInCombat(cop) then ClearPedTasks(cop) end   -- de-escalate
                    if d > Config.Police.arrestRange + 0.8 and not IsPedInCombat(cop) then
                        TaskGoToEntity(cop, player, -1, Config.Police.arrestRange, 2.2, 1073741824.0, 0)
                    end
                end
            end
        end
        allCops = live

        if not lethal then
            for _, cop in ipairs(live) do
                if GetVehiclePedIsIn(cop, false) == 0 and #(pc - GetEntityCoords(cop)) <= Config.Police.arrestRange + 0.8 then
                    Police.Subdue(cop, surrendered)   -- peaceful if hands are up
                    break
                end
            end
        end
        ::continue::
    end
end)

-- cop-kill detection -> escalation
CreateThread(function()
    while true do
        Wait(500)
        if #allCops > 0 then
            local player = PlayerPedId()
            for i = #allCops, 1, -1 do
                local cop = allCops[i]
                if not DoesEntityExist(cop) then
                    table.remove(allCops, i)
                elseif IsPedDeadOrDying(cop, true) then
                    if HasEntityBeenDamagedByEntity(cop, player, true) then
                        TriggerServerEvent("viscosity_ai_npcs:server:reportCrime", "copkill")
                        notify("Officer down — escalating", "error")
                    end
                    table.remove(allCops, i)
                end
            end
        end
    end
end)

RegisterNetEvent("viscosity_ai_npcs:client:dispatch", function(score)
    Police.Dispatch(score)
end)

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then Police.ClearAll() end
end)
