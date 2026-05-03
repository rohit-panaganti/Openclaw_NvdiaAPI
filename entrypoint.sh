#!/bin/sh
mkdir -p /root/.openclaw
echo "$OPENCLAW_CONFIG" > /root/.openclaw/openclaw.json
exec openclaw gateway
