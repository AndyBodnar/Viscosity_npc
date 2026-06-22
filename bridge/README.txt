Viscosity AI NPCs — Groq STT Bridge
===================================

Why this exists
---------------
FiveM's PerformHttpRequest corrupts binary data, so it can't upload audio to
Groq's Whisper directly. This tiny Node server does the upload correctly
(Node handles binary fine), so voice runs on your Groq key — no Gemini,
no billing.

Setup (once)
------------
1. You need Node. If typing `node -v` in a terminal works, you're set.
   If not, copy node.exe into THIS folder (e.g. from the LivingLSAI
   package's "LLAI SERVER\LLAIBridge\node.exe").

2. Double-click start-bridge.bat. Leave the window open while you play.
   You should see:
       [bridge] Viscosity Groq STT bridge listening on http://127.0.0.1:30200

That's it. No npm install — only Node built-ins are used.

How it connects
---------------
- The FiveM resource (viscosity_ai_npcs) sends the recorded audio + your
  Groq key (from server.cfg's ai:groqKey) to http://127.0.0.1:30200/transcribe
- The bridge uploads it to Groq Whisper and returns the transcript
- The resource then sends that text to the Groq LLM for the NPC's reply

Config (optional)
-----------------
- Port: set BRIDGE_PORT before launching (default 30200). If you change it,
  also set `ai:bridgePort` in server.cfg to match.
- STT model: set GROQ_STT_MODEL (default whisper-large-v3).

Health check
------------
Open http://127.0.0.1:30200/health in a browser — should show {"ok":true}.
