FROM node:22-slim

RUN npm install -g openclaw
RUN openclaw skills install tavily --yes 2>/dev/null || true

RUN mkdir -p /root/.openclaw/credentials
COPY telegram-allowFrom.json /root/.openclaw/credentials/telegram-default-allowFrom.json

WORKDIR /app
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENV NODE_OPTIONS=--dns-result-order=ipv4first

CMD ["/bin/sh", "/app/entrypoint.sh"]
