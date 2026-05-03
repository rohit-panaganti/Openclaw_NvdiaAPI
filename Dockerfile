FROM node:22-slim

RUN npm install -g openclaw

WORKDIR /app
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENV NODE_OPTIONS=--dns-result-order=ipv4first

CMD ["/app/entrypoint.sh"]
