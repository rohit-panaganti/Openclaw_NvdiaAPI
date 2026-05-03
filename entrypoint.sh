#!/bin/sh
mkdir -p /root/.openclaw/credentials
printf '%s' "$OPENCLAW_CONFIG" > /root/.openclaw/openclaw.json
printf '{"version":1,"allowFrom":["7029905272"]}' > /root/.openclaw/credentials/telegram-default-allowFrom.json
exec openclaw gateway
