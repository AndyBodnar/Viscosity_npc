fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'viscosity_ai_npcs'
author 'Viscosity Gaming Studio'
description 'LLM-driven NPC conversations (/talkto) + carjack hostility (RPGs/LMGs).'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
}

server_scripts {
    'server/llm.lua',         -- LLM provider calls (Groq / Gemini)
    'server/stt.lua',         -- speech-to-text (via Groq bridge)
    'server/reputation.lua',  -- crime heat / NPC memory
    'server/main.lua',        -- chat + voice events
}

client_scripts {
    'client/functions.lua',  -- AiNpc module (targeting, speech bubbles)
    'client/hostility.lua',  -- carjack detection + arm-and-attack
    'client/crime.lua',      -- kill GTA stars + report witnessed crimes
    'client/police.lua',     -- custom arrest AI (dispatch/taser/cuff/lethal)
    'client/prison.lua',     -- Bolingbroke transport + sentence + release
    'client/voice.lua',      -- push-to-talk mic capture
    'client/events.lua',     -- /talkto command + reply handler
}

ui_page 'web/index.html'   -- hidden recorder (mic capture for push-to-talk)

files {
    'web/index.html',
}

dependency 'viscosity_core'
