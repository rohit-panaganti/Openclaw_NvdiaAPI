#!/bin/sh
mkdir -p /root/.openclaw/credentials
printf '%s' "$OPENCLAW_CONFIG" > /root/.openclaw/openclaw.json

echo "[entrypoint] OPENCLAW_CONFIG length: $(printf '%s' "$OPENCLAW_CONFIG" | wc -c)" >&2
echo "[entrypoint] TAVILY_API_KEY set: $([ -n "$TAVILY_API_KEY" ] && echo YES || echo NO)" >&2

# Patch config to ensure Tavily is enabled with API key from env
node -e "
const fs = require('fs');
const path = '/root/.openclaw/openclaw.json';
let raw;
try {
  raw = fs.readFileSync(path, 'utf8');
} catch(e) {
  process.stderr.write('[entrypoint] ERROR reading config: ' + e.message + '\n');
  process.exit(1);
}
let cfg;
try {
  cfg = JSON.parse(raw);
} catch(e) {
  process.stderr.write('[entrypoint] ERROR parsing config JSON: ' + e.message + '\n');
  process.stderr.write('[entrypoint] Raw config (first 200 chars): ' + raw.slice(0, 200) + '\n');
  process.exit(1);
}
if (!cfg.plugins) cfg.plugins = {};
if (!cfg.plugins.entries) cfg.plugins.entries = {};
if (!cfg.plugins.entries.tavily) cfg.plugins.entries.tavily = {};
cfg.plugins.entries.tavily.enabled = true;
if (!cfg.plugins.entries.tavily.config) cfg.plugins.entries.tavily.config = {};
if (!cfg.plugins.entries.tavily.config.webSearch) cfg.plugins.entries.tavily.config.webSearch = {};
const apiKey = process.env.TAVILY_API_KEY || cfg.plugins.entries.tavily.config.webSearch.apiKey || '';
if (apiKey) cfg.plugins.entries.tavily.config.webSearch.apiKey = apiKey;
if (!cfg.tools) cfg.tools = {};
if (!cfg.tools.web) cfg.tools.web = {};
if (!cfg.tools.web.search) cfg.tools.web.search = {};
cfg.tools.web.search.provider = 'tavily';
cfg.tools.web.search.enabled = true;
fs.writeFileSync(path, JSON.stringify(cfg));
process.stderr.write('[entrypoint] Config patched OK. Tavily enabled=' + cfg.plugins.entries.tavily.enabled + ' apiKey=' + (apiKey ? 'SET(' + apiKey.slice(0,8) + '...)' : 'MISSING') + '\n');
process.stderr.write('[entrypoint] tools.web.search=' + JSON.stringify(cfg.tools.web.search) + '\n');
" || { echo "[entrypoint] FATAL: config patch failed" >&2; exit 1; }

printf '{"version":1,"allowFrom":["7029905272"]}' > /root/.openclaw/credentials/telegram-default-allowFrom.json
printf '{"version":1,"requests":[]}' > /root/.openclaw/credentials/telegram-pairing.json
export TAVILY_API_KEY="${TAVILY_API_KEY}"
exec openclaw gateway
