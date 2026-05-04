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

# Locate the global node_modules dir so subsequent node -e scripts can require openclaw
GLOBAL_MODULES="$(npm root -g 2>/dev/null)"
echo "[entrypoint] global node_modules: $GLOBAL_MODULES"
export NODE_PATH="$GLOBAL_MODULES"

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

echo "[entrypoint] === TAVILY PREFLIGHT ==="
node -e "
const fs = require('fs');
const path = require('path');
const Module = require('module');
const globalRoot = process.env.NODE_PATH || '';
console.log('[preflight] NODE_PATH:', globalRoot);
let ocRoot;
try {
  ocRoot = path.join(globalRoot, 'openclaw');
  if (!fs.existsSync(ocRoot)) {
    // fall back to npm root -g default location
    ocRoot = '/usr/local/lib/node_modules/openclaw';
  }
} catch(e) {}
console.log('[preflight] openclaw root:', ocRoot, 'exists=', fs.existsSync(ocRoot));
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

// Try to require the tavily entry directly. CRITICAL: Module._resolveFilename respects NODE_PATH only at startup;
// to require a globally-installed module, we use the absolute path.
let tavilyMod = null;
try {
  tavilyMod = require(path.join(tavilyDir, 'index.js'));
  console.log('[preflight] tavily module loaded. exports:', Object.keys(tavilyMod).join(', '));
} catch(e) {
  console.log('[preflight] FAILED to require tavily:', e.message);
  console.log('[preflight] stack first 600:', (e.stack || '').slice(0, 600));
}

// Tavily is an ES module — unwrap default export. The OpenClaw plugin loader probably also does this.
let pluginEntry = null;
if (tavilyMod) {
  // candidates: top-level register, default.register, default itself if it's a function (named-export factory)
  if (typeof tavilyMod.register === 'function') pluginEntry = tavilyMod;
  else if (tavilyMod.default) {
    if (typeof tavilyMod.default.register === 'function') pluginEntry = tavilyMod.default;
    else if (typeof tavilyMod.default === 'function') pluginEntry = { register: tavilyMod.default };
  }
  console.log('[preflight] tavilyMod.default keys:', tavilyMod.default ? Object.keys(tavilyMod.default).join(',') : 'none');
  console.log('[preflight] pluginEntry resolved:', pluginEntry ? 'YES' : 'NO');
  if (pluginEntry) console.log('[preflight] pluginEntry methods:', Object.keys(pluginEntry).join(','));
}

let providerRef = null;
if (pluginEntry && typeof pluginEntry.register === 'function') {
  const fakeApi = {
    registerWebSearchProvider: (p) => { providerRef = p; console.log('[preflight] registerWebSearchProvider called with id:', p && p.id); },
    registerTool: (t) => console.log('[preflight] registerTool called with name:', t && t.name),
    logger: { info: (...a)=>console.log('[plugin/tavily/info]', ...a), warn: (...a)=>console.log('[plugin/tavily/warn]', ...a), error: (...a)=>console.log('[plugin/tavily/error]', ...a), debug: ()=>{} },
    config: { webSearch: { apiKey: process.env.TAVILY_API_KEY } },
    pluginConfig: { webSearch: { apiKey: process.env.TAVILY_API_KEY } },
  };
  try {
    const result = pluginEntry.register(fakeApi);
    console.log('[preflight] tavily.register() OK. result type:', typeof result, 'provider captured:', !!providerRef);
    if (providerRef) console.log('[preflight] provider:', JSON.stringify({ id: providerRef.id, methods: Object.keys(providerRef) }));
  } catch(e) {
    console.log('[preflight] tavily.register() THREW:', e.message);
    console.log('[preflight] stack first 600:', (e.stack || '').slice(0, 600));
  }
}

if (providerRef && typeof providerRef.search === 'function') {
  console.log('[preflight] attempting live tavily search with API key...');
  Promise.resolve(providerRef.search({ query: 'openai news', maxResults: 1 }))
    .then(r => {
      const hits = (r && (r.results || r.hits || [])) || [];
      console.log('[preflight] tavily.search OK. hits=' + hits.length);
      if (hits[0]) console.log('[preflight] first hit title:', hits[0].title || hits[0].url || JSON.stringify(hits[0]).slice(0,120));
    })
    .catch(err => console.log('[preflight] tavily.search FAILED:', err && err.message));
}
" || echo "[preflight] node script crashed"

echo "[entrypoint] === STARTING GATEWAY ==="
printf '{"version":1,"allowFrom":["7029905272"]}' > /root/.openclaw/credentials/telegram-default-allowFrom.json
printf '{"version":1,"requests":[]}' > /root/.openclaw/credentials/telegram-pairing.json
export TAVILY_API_KEY="${TAVILY_API_KEY}"
exec openclaw gateway
