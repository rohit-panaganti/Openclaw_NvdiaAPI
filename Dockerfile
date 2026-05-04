FROM node:22-slim

# Cache-bust marker: bump this string to force a clean rebuild of all subsequent layers.
ARG CACHE_BUST=2026-05-04-tavily-debug-v2
RUN echo "[build] cache-bust marker: $CACHE_BUST"

RUN npm install -g openclaw

RUN mkdir -p /root/.openclaw/credentials
COPY telegram-allowFrom.json /root/.openclaw/credentials/telegram-default-allowFrom.json

WORKDIR /app
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && echo "[build] entrypoint.sh installed:" && head -3 /app/entrypoint.sh

ENV NODE_OPTIONS=--dns-result-order=ipv4first

CMD ["/bin/sh", "/app/entrypoint.sh"]
