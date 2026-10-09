#!/bin/bash
# Checks the local setup. Prints the environment it sees so you can compare.
set -a; [ -f .env ] && . ./.env; set +a
echo "node $(node --version)"
echo "--- environment ---"
env | sort | grep -v -E '^(HOME|PATH|PWD|SHLVL|_|HOSTNAME|TERM|OLDPWD|NODE_VERSION|YARN_VERSION|OPENROUTER_API_KEY|ANTHROPIC_.*)='
if ! echo "$DATABASE_URL" | grep -qE '^postgres(ql)?://'; then
  echo "problem: DATABASE_URL has the wrong scheme"; exit 1
fi
echo "all good"
