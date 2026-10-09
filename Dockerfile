# Isolated box for the .env test. The agents see only the fixture repo and
# their own API key, never the host's home folder or keychain.
FROM node:22-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends git ripgrep ca-certificates python3 \
 && rm -rf /var/lib/apt/lists/*
RUN npm install -g @anthropic-ai/claude-code@2.1.292 @openai/codex@0.160.1 && npm cache clean --force
COPY agent-run.sh /usr/local/bin/agent-run
RUN chmod +x /usr/local/bin/agent-run
USER node
WORKDIR /home/node
