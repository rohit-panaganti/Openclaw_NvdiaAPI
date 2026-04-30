# Openclaw + NVIDIA NIM API â€” Telegram Bot

A self-hosted AI gateway that connects a Telegram bot to NVIDIA's NIM API (Minimax M2.7 model) using [OpenClaw](https://openclaw.ai).

---

## How It Works

```
Telegram user â†’ @YourBot â†’ OpenClaw Gateway (local) â†’ NVIDIA NIM API â†’ reply
```

- OpenClaw runs locally and polls Telegram for messages
- Routes them to NVIDIA's NIM API using your API key
- Sends the AI response back to Telegram
- Bot only responds to your Telegram user ID (allowlist mode)

---

## Requirements

- Node.js v18 or higher â€” [nodejs.org](https://nodejs.org)
- NVIDIA NIM API key â€” [build.nvidia.com](https://build.nvidia.com)
- Telegram bot token â€” create via [@BotFather](https://t.me/BotFather)
- Your Telegram user ID â€” get via [@userinfobot](https://t.me/userinfobot)

---

## Setup â€” macOS

```bash
# 1. Install Node.js
brew install node

# 2. Install openclaw
npm install -g openclaw

# 3. Copy config template
mkdir -p ~/.openclaw
cp config-template.json ~/.openclaw/openclaw.json

# 4. Edit the config â€” fill in your API keys and IDs
nano ~/.openclaw/openclaw.json

# 5. Fix telegram plugin (run once after install)
node fix-telegram-plugin.js

# 6. Start the gateway
openclaw gateway start

# 7. Check status
openclaw gateway status
```

To watch logs live:
```bash
tail -f ~/.openclaw/logs/openclaw-$(date +%Y-%m-%d).log
```

---

## Setup â€” Windows

```powershell
# 1. Install Node.js from https://nodejs.org

# 2. Run the setup script
.\setup.ps1

# 3. Edit the config â€” fill in your API keys
notepad "$env:USERPROFILE\.openclaw\openclaw.json"

# 4. Start the gateway
& "C:\Program Files\nodejs\node.exe" "C:\Users\$env:USERNAME\AppData\Roaming\npm\node_modules\openclaw\dist\index.js" gateway start
```

To watch logs live:
```powershell
Get-ChildItem "$env:LOCALAPPDATA\Temp\openclaw\openclaw-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content -Tail 20 -Wait
```

---

## Config Fields to Fill In

Open `~/.openclaw/openclaw.json` (Mac) or `%USERPROFILE%\.openclaw\openclaw.json` (Windows) and replace:

| Placeholder | What to put |
|---|---|
| `YOUR_NVIDIA_API_KEY` | API key from build.nvidia.com |
| `YOUR_TELEGRAM_BOT_TOKEN` | Token from @BotFather |
| `YOUR_TELEGRAM_USER_ID` | Your numeric Telegram ID (as string in `peer.id`) |
| `YOUR_TELEGRAM_USER_ID_NUMBER` | Same ID as a number in `allowFrom` array |
| `YOUR_GATEWAY_AUTH_TOKEN` | Any random string â€” run `openssl rand -hex 24` |

---

## Known Issues & Fixes

### Bot receives messages but never responds

The telegram plugin action-runtime module can be missing from openclaw's runtime deps. Fix:

```bash
node fix-telegram-plugin.js
```

Then restart the gateway.

### Slow response times (15â€“100 seconds)

This is normal. Three sources of latency:
1. **Telegram polling** â€” openclaw polls every ~50 seconds; your message may wait up to 50s to be seen
2. **NVIDIA cold start** â€” first request after idle takes 10â€“30s to warm up the model
3. **Model inference** â€” Minimax M2.7 takes 5â€“20s to generate a response

### Gateway won't start â€” port in use

```bash
# Mac
lsof -i :18789
kill -9 <PID>

# Windows
netstat -ano | findstr :18789
taskkill /PID <PID> /F
```

---

## Gateway Commands

| Command | Description |
|---|---|
| `openclaw gateway start` | Start the gateway (registers as login item) |
| `openclaw gateway stop` | Stop the gateway |
| `openclaw gateway status` | Check if gateway is running |
| `openclaw config get channels.telegram` | View current Telegram config |

---

## Auto-start on Login

The gateway registers itself as a login item automatically when you run `gateway start`. It will restart every time you log in â€” no manual start needed.
