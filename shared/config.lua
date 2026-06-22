Config = {}

-- LLM provider is read from a server convar (ai:provider). This is just the
-- default the client uses for UX; the real key lives server-side only.
Config.TalkDistance = 4.5      -- meters to the nearest NPC for /talkto
Config.ReplyDuration = 7000    -- ms a speech bubble stays up
Config.PushToTalkKey = "B"     -- hold to talk to the nearest NPC (rebind in FiveM keybinds)

-- ---------------- Crime + reputation ----------------
-- Heat points per crime (reputation). Higher = stronger police response +
-- NPCs more afraid of you. Decays slowly over time.
Config.Crime = {
    enabled = true,
    points = { carjack = 12, shooting = 8, assault = 15, murder = 40, copkill = 55 },
    decayPerMin = 3,                 -- heat cooled off each minute
    dispatchThreshold = 10,          -- heat needed before cops are sent
}

-- ---------------- Police (custom arrest AI, no GTA stars) ----------------
Config.Police = {
    enabled = true,
    copModel = `s_m_y_cop_01`,
    carModel = `police`,
    spawnDistance = 90.0,            -- cops arrive from this far, drive in
    unitsPerWave = 2,
    redispatchDelay = 25000,         -- ms between waves
    taserWeapon = `WEAPON_STUNGUN`,
    lethalWeapon = `WEAPON_PISTOL`,
    arrestRange = 2.2,               -- distance to begin cuffing a subdued player
    taserRange = 9.0,                -- distance a cop will tase from
    pd = vec3(441.0, -981.0, 30.69), -- Mission Row PD (haul target)
    cuffSeconds = 8,                 -- how long the cuff/haul sequence holds you
}

-- ---------------- Prison (Bolingbroke) ----------------
Config.Prison = {
    secondsPerMonth = 1,                  -- 1 month of sentence = 1 real second
    minMonths = 5,
    maxMonths = 600,                      -- cap (10 min real time)
    gate = vec3(1846.0, 2608.0, 46.0),    -- drive target (prison entrance road)
    cell = vec3(1845.0, 2585.0, 45.67),   -- where you're dropped to serve (yard)
    release = vec3(1853.0, 2625.0, 47.5), -- released outside the front gate
    bounds = 65.0,                        -- roam radius before you're pulled back to the yard
}

-- ---------------- Carjack hostility ----------------
Config.Hostility = {
    enabled       = true,
    cooldown      = 8000,       -- ms between triggers
    accuracy      = 55,         -- ped aim accuracy (0-100)
    reinforcements = 2,         -- extra armed peds that spawn to back them up
    -- "mad hostility" arsenal — one is picked per ped
    weapons = { `WEAPON_RPG`, `WEAPON_COMBATMG`, `WEAPON_MG`, `WEAPON_GUSENBERG` },
    -- gang ped models used for reinforcements
    reinforcementModels = { `g_m_y_ballaeast_01`, `g_m_y_famca_01`, `g_m_y_mexgoon_01` },
    -- instant shouts (no LLM wait) when a jack kicks off
    shouts = {
        "GET OFF MY CAR!!",
        "WRONG RIDE, FOOL!",
        "YOU PICKED THE WRONG ONE!",
        "LIGHT HIS ASS UP!",
        "NOBODY JACKS ME!",
    },
}
