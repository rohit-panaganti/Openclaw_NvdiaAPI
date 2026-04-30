# Openclaw + NVIDIA NIM API â€” Telegram Bot Setup

A self-hosted AI gateway that connects a Telegram bot to NVIDIA's NIM API (Minimax M2.7 model) using [OpenClaw](https://openclaw.ai).

---

## How It Works

```
Telegram user â†’ @YourBot â†’ OpenClaw Gateway â†’ NVIDIA NIM API (minimax-m2.7) â†’ reply
```

- OpenClaw polls Telegram for messages
- Routes them to NVIDIA's NIM API using your API key
- Sends the AI response back to Telegram

---

## Requirements

- Node.js v18 or higher
- npm
- NVIDIA NIM API key â€” [get one here](https://build.nvidia.com)
- Telegram bot token â€” create via [@BotFather](https://t.me/BotFather)
- Your Telegram user ID â€” get via [@userinfobot](https://t.me/userinfobot)

---

## Setup â€” macOS

### 1. Install Node.js

```bash
brew install node
```

Or download from [nodejs.org](https://nodejs.org).

### 2. Install OpenClaw

```bash
npm install -g openclaw
```

### 3. Configure OpenClaw

Copy the config template and fill in your values:

```bash
mkdir -p ~/.openclaw
cp config-template.json ~/.openclaw/openclaw.json
```

Open `~/.openclaw/openclaw.json` and replace all placeholders:
- `YOUR_NVIDIA_API_KEY` â€” your NVIDIA NIM API key
- `YOUR_TELEGRAM_BOT_TOKEN` â€” token from BotFather
- `YOUR_TELEGRAM_USER_ID` â€” your numeric Telegram user ID
- `YOUR_GATEWAY_AUTH_TOKEN` â€” any random 48-char hex string (run `openssl rand -hex 24`)

### 4. Start the Gateway

```bash
openclaw gateway start
```

To check status:
```bash
openclaw gateway status
```

To view logs:
```bash
tail -f ~/Library/Logs/openclaw/openclaw-$(date +%Y-%m-%d).log
```

### 5. Start on Login (macOS)

```bash
openclaw gateway install
```

This registers the gateway as a launchd service so it starts automatically on login.

---

## Setup â€” Windows

### 1. Install Node.js

Download from [nodejs.org](https://nodejs.org) and install.

### 2. Install OpenClaw

```powershell
npm install -g openclaw
```

### 3. Configure OpenClaw

```powershell
Copy-Item config-template.json "$env:USERPROFILE\.openclaw\openclaw.json"
```

Edit `%USERPROFILE%\.openclaw\openclaw.json` and replace all placeholders.

### 4. Start the Gateway

```powershell
openclaw gateway start
```

The gateway registers as a Windows login item and starts automatically on boot.

### 5. View Logs

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Temp\openclaw\openclaw-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content -Tail 20 -Wait
```

---

## Key Config Options

| Field | Description |
|---|---|
| `agents.defaults.model.primary` | Model to use. Format: `nvidia/MODEL_ID` |
| `channels.telegram.dmPolicy` | Set to `allowlist` to restrict who can DM the bot |
| `channels.telegram.allowFrom` | Array of Telegram user IDs allowed to message the bot |
| `models.providers.nvidia.apiKey` | Your NVIDIA NIM API key |
| `channels.telegram.botToken` | Your Telegram bot token |

---

## Troubleshooting

**Bot not responding?**
- Check gateway is running: `openclaw gateway status`
- Check logs for errors
- Make sure your Telegram user ID is in `allowFrom`

**Slow responses?**
- NVIDIA NIM has cold start latency (~10â€“30s for first request after idle)
- Telegram polling adds up to 50s delay
- Total response time of 15â€“100s is normal

**Gateway won't start?**
- Make sure port 18789 is free: `lsof -i :18789` (Mac) or `netstat -ano | findstr :18789` (Windows)
