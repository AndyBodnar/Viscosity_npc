# viscosity_ai_npcs

**Living, reactive NPCs for FiveM.** Pedestrians you can actually talk to (typed *or*
by voice) powered by an LLM, who **remember** what you've done, plus a full custom
crime-response world: witnessed crimes build heat, police dispatch and try to
**arrest** you (taser → cuff → drive you to prison) instead of the vanilla "five stars
and you're dead," carjack victims fight back, and it all escalates to SWAT.

Built on [viscosity_core](https://github.com/AndyBodnar/viscosity_core).

---

## Features

- **Talk to anyone**, aim at a ped and `/talkto <message>`; they reply in character.
- **Voice**, hold **B**, speak, release; your speech is transcribed and they answer
  out loud (browser TTS).
- **NPC memory / reputation**, crimes build "heat" per player and get injected into the
  NPC's prompt, so a known murderer gets *terrified* pedestrians, not casual ones.
- **Custom police (no GTA stars)**, witnessed crimes dispatch real units that **drive
  in**, get out, and try to **arrest** you: taser → blackout → cuff. They only go
  lethal if you shoot at them.
- **Surrender**, press **X** to put your hands up; cops stand down and arrest you
  peacefully.
- **Prison**, after arrest you're put in the back of the cruiser and **driven to
  Bolingbroke** to serve a sentence scaled to your crimes (1 month = 1 second), then
  released.
- **Escalation**, heat tiers from 2 officers → 4 → **SWAT**; killing a cop spikes the
  response.
- **Carjack hostility**, try to jack an occupied car and the occupants pile out with
  heavy weapons and fight back.

---

## Requirements

- [viscosity_core](https://github.com/AndyBodnar/viscosity_core) (notifications, draw helpers)
- A **Groq** API key (free at [console.groq.com](https://console.groq.com)) for chat + speech-to-text
- **Node** for the voice bridge (see below), only needed if you want voice

## Installation

1. Drop `viscosity_ai_npcs` into `resources`.
2. In `server.cfg` (keys use `set`, **never** `setr`, that would leak them to clients):
   ```cfg
   set ai:provider "groq"
   set ai:groqKey "gsk_your_key_here"
   ensure viscosity_ai_npcs
   ```
3. **Voice bridge (optional):** FiveM can't upload audio binaries cleanly, so a tiny
   Node sidecar does it. Put a `node.exe` in `bridge/` (or have Node on PATH) and run
   `bridge/start-bridge.bat`. See `bridge/README.txt`.

---

## Controls / commands

| Input | Action |
|-------|--------|
| `/talkto <message>` | Speak to the ped you're aiming at |
| Hold **B** | Push-to-talk voice (needs the bridge running) |
| **X** | Surrender (hands up) during a police encounter |

---

## Configuration

Everything lives in `shared/config.lua`:

- `Config.Crime`, heat points per crime, decay rate, dispatch threshold
- `Config.Police`, models, escalation, taser/arrest ranges, spawn distance
- `Config.Prison`, Bolingbroke coordinates, `secondsPerMonth`, sentence caps
- `Config.Hostility`, carjack arsenal + accuracy

---

## How voice works

Hold **B** → the hidden NUI records WAV via AudioWorklet → sends base64 to the local
Node bridge → the bridge uploads it to Groq Whisper (Node handles the binary FiveM
can't) → transcript → Groq LLM → the NPC replies out loud. No bridge running? Typed
`/talkto` still works fully.

---

© Viscosity. Built and maintained by Viscosity Gaming Studio.

## License

Copyright (c) 2026 **AndyBodnar (Viscosity)**. All rights reserved. See [LICENSE](LICENSE).

Run it on your own server and modify it however you like. Do **not** resell it, repackage it, re-upload it as your own, or strip the credits. Public use must credit AndyBodnar (Viscosity). This is my work, I'm sharing it, not giving it away.
