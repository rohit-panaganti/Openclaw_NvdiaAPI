#!/bin/sh
set -e
mkdir -p /root/.openclaw/credentials
printf '%s' "$OPENCLAW_CONFIG" > /root/.openclaw/openclaw.json

echo "[entrypoint] === BOOT DIAGNOSTICS ==="
echo "[entrypoint] OPENCLAW_CONFIG length: $(printf '%s' "$OPENCLAW_CONFIG" | wc -c)"
echo "[entrypoint] TAVILY_API_KEY set: $([ -n "$TAVILY_API_KEY" ] && echo YES || echo NO)"
if [ -n "$TAVILY_API_KEY" ]; then
  echo "[entrypoint] TAVILY_API_KEY prefix: $(printf '%s' "$TAVILY_API_KEY" | cut -c1-12)..."
fi

# Patch config: enable Tavily, inject API key, set tools.web.search
node -e "
const fs = require('fs');
const path = '/root/.openclaw/openclaw.json';
let raw;
try { raw = fs.readFileSync(path, 'utf8'); }
catch(e) { console.log('[entrypoint] ERROR reading config:', e.message); process.exit(1); }
let cfg;
try { cfg = JSON.parse(raw); }
catch(e) {
  console.log('[entrypoint] ERROR parsing config JSON:', e.message);
  console.log('[entrypoint] Raw config (first 300 chars):', raw.slice(0, 300));
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
console.log('[entrypoint] Config patched. tavily.enabled=' + cfg.plugins.entries.tavily.enabled +
  ' apiKey=' + (apiKey ? 'SET(' + apiKey.slice(0,8) + '...)' : 'MISSING'));
console.log('[entrypoint] tools.web.search=' + JSON.stringify(cfg.tools.web.search));
console.log('[entrypoint] tools.profile=' + (cfg.tools.profile || 'unset'));
"

# Preflight: verify Tavily plugin files exist and try to load + register
echo "[entrypoint] === TAVILY PREFLIGHT ==="
node -e "
const fs = require('fs');
const path = require('path');
let openclawPkg;
try { openclawPkg = require.resolve('openclaw/package.json'); }
catch(e) { console.log('[preflight] FATAL: cannot resolve openclaw package:', e.message); process.exit(0); }
const ocRoot = path.dirname(openclawPkg);
console.log('[preflight] openclaw root:', ocRoot);
const tavilyDir = path.join(ocRoot, 'dist', 'extensions', 'tavily');
console.log('[preflight] tavily dir exists:', fs.existsSync(tavilyDir));
if (fs.existsSync(tavilyDir)) {
  console.log('[preflight] tavily dir contents:', fs.readdirSync(tavilyDir).join(', '));
  const manifestPath = path.join(tavilyDir, 'openclaw.plugin.json');
  if (fs.existsSync(manifestPath)) {
    const m = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    console.log('[preflight] tavily manifest id:', m.id, 'entry:', m.entry, 'onStartup:', m.activation && m.activation.onStartup);
    console.log('[preflight] tavily contracts:', JSON.stringify(m.contracts || {}));
  }
}
// Try to require the tavily entry directly
try {
  const mod = require(path.join(tavilyDir, 'index.js'));
  console.log('[preflight] tavily module loaded. exports:', Object.keys(mod).join(', '));
  if (typeof mod.register === 'function') {
    let registered = null;
    const fakeApi = {
      registerWebSearchProvider: (p) => { registered = p; },
      logger: { info: ()=>{}, warn: ()=>{}, error: ()=>{}, debug: ()=>{} }
    };
    try {
      mod.register(fakeApi);
      console.log('[preflight] tavily.register() OK. provider id:', registered && registered.id);
    } catch(e) {
      console.log('[preflight] tavily.register() THREW:', e.message);
      console.log(e.stack);
    }
  }
} catch(e) {
  console.log('[preflight] FAILED to require tavily:', e.message);
  console.log('[preflight] stack:', e.stack);
}
" || echo "[preflight] node script crashed"

echo "[entrypoint] === STARTING GATEWAY ==="
printf '{"version":1,"allowFrom":["7029905272"]}' > /root/.openclaw/credentials/telegram-default-allowFrom.json
printf '{"version":1,"requests":[]}' > /root/.openclaw/credentials/telegram-pairing.json
export TAVILY_API_KEY="${TAVILY_API_KEY}"
exec openclaw gateway
