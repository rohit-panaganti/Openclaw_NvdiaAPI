#!/bin/sh
mkdir -p /root/.openclaw
printf '%s' "$OPENCLAW_CONFIG" > /root/.openclaw/openclaw.json
exec openclaw gateway
