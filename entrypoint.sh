#!/bin/sh
mkdir -p /root/.openclaw/credentials
printf '' "$OPENCLAW_CONFIG" > /root/.openclaw/openclaw.json
printf '{"version":1,"allowFrom":["7029905272"]}' > /root/.openclaw/credentials/telegram-default-allowFrom.json
printf '{"version":1,"requests":[]}' > /root/.openclaw/credentials/telegram-pairing.json
exec openclaw gateway
