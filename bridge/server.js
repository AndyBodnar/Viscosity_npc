// ============================================================
//  Viscosity AI NPCs — Groq STT bridge
//  Tiny localhost server. FiveM POSTs { audio: base64, key } here;
//  this decodes to a binary Buffer and uploads it to Groq Whisper
//  as proper multipart (Node handles binary correctly, unlike
//  FiveM's PerformHttpRequest). Returns { text }.
//
//  Run it next to the FiveM server:  start-bridge.bat
//  No npm install needed — only Node built-ins.
// ============================================================

const http = require("http");
const https = require("https");

const PORT = process.env.BRIDGE_PORT || 30200;
const MODEL = process.env.GROQ_STT_MODEL || "whisper-large-v3";

function transcribe(buf, key, cb) {
  const boundary = "----viscosityBridge" + Date.now();
  const head = Buffer.from(
    `--${boundary}\r\nContent-Disposition: form-data; name="model"\r\n\r\n${MODEL}\r\n` +
    `--${boundary}\r\nContent-Disposition: form-data; name="response_format"\r\n\r\ntext\r\n` +
    `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="audio.wav"\r\n` +
    `Content-Type: audio/wav\r\n\r\n`
  );
  const tail = Buffer.from(`\r\n--${boundary}--\r\n`);
  const payload = Buffer.concat([head, buf, tail]);

  const req = https.request(
    {
      hostname: "api.groq.com",
      path: "/openai/v1/audio/transcriptions",
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": `multipart/form-data; boundary=${boundary}`,
        "Content-Length": payload.length,
      },
    },
    (res) => {
      let data = "";
      res.on("data", (d) => (data += d));
      res.on("end", () => cb(res.statusCode, data));
    }
  );
  req.on("error", (e) => cb(0, e.message));
  req.write(payload);
  req.end();
}

function send(res, code, obj) {
  res.writeHead(code, { "Content-Type": "application/json" });
  res.end(JSON.stringify(obj));
}

http
  .createServer((req, res) => {
    if (req.method === "POST" && req.url === "/transcribe") {
      let body = "";
      req.on("data", (c) => (body += c));
      req.on("end", () => {
        let audio, key;
        try {
          ({ audio, key } = JSON.parse(body));
        } catch {
          return send(res, 400, { error: "bad_json" });
        }
        key = key || process.env.GROQ_API_KEY || "";
        if (!audio) return send(res, 400, { error: "no_audio" });
        if (!key) return send(res, 500, { error: "no_key" });

        const buf = Buffer.from(audio, "base64");
        transcribe(buf, key, (status, text) => {
          if (status !== 200) {
            console.log(`[bridge] Groq ${status}: ${String(text).slice(0, 200)}`);
            return send(res, 502, { error: `groq_${status}` });
          }
          const t = String(text).trim();
          console.log(`[bridge] transcript: ${t.slice(0, 80)}`);
          send(res, 200, { text: t });
        });
      });
    } else if (req.url === "/health") {
      send(res, 200, { ok: true });
    } else {
      send(res, 404, { error: "not_found" });
    }
  })
  .listen(PORT, "127.0.0.1", () =>
    console.log(`[bridge] Viscosity Groq STT bridge listening on http://127.0.0.1:${PORT}`)
  );
