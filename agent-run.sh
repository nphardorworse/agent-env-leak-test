#!/bin/bash
# Runs inside the container: agent-run <claude[_label]|codex|gemini> <base|protected> <task-id> [repeat]
set -u
AGENT=$1 VARIANT=$2 TASK_ID=$3
TASK=$(grep "^$TASK_ID|" /fixture/tasks.txt | cut -d'|' -f2-)
NAME="$AGENT-$VARIANT-$TASK_ID${4:+-r$4}"
OUT=/out/$NAME

REPO=/home/node/shop-api
# A fixture folder named like the variant replaces base (coercion fixtures).
SRC=/fixture/base
[ "$VARIANT" != protected ] && [ -d "/fixture/$VARIANT" ] && SRC=/fixture/$VARIANT
rm -rf "$REPO" && cp -r "$SRC" "$REPO"
if [ "$VARIANT" = protected ]; then
  cp -r /fixture/protected/. "$REPO/"
  cp "$REPO/AGENTS.md" "$REPO/CLAUDE.md"
  cp "$REPO/AGENTS.md" "$REPO/GEMINI.md"
fi
cd "$REPO" || exit 1
git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm init

case "$AGENT" in
  claude*)
    # Claude Code through OpenRouter's Anthropic-compatible endpoint. MODEL picks
    # another model for the same harness (agent names like claude_deepseek).
    M=${MODEL:-anthropic/claude-sonnet-5.5}
    ANTHROPIC_BASE_URL=https://openrouter.ai/api ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY" ANTHROPIC_API_KEY="" \
    ANTHROPIC_SMALL_FAST_MODEL="$M" \
    claude -p "$TASK" --model "$M" --output-format stream-json --verbose \
      --dangerously-skip-permissions --max-turns 12 > "$OUT.jsonl" 2> "$OUT.stderr" ;;
  codex)
    mkdir -p ~/.codex && cat > ~/.codex/config.toml <<'TOML'
model = "openai/gpt-6-sol"
model_provider = "openrouter"
[model_providers.openrouter]
name = "OpenRouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"
wire_api = "responses"
TOML
    timeout 600 codex exec --json --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox \
      "$TASK" > "$OUT.jsonl" 2> "$OUT.stderr" ;;
  gemini)
    gemini -p "$TASK" --yolo --output-format stream-json > "$OUT.jsonl" 2> "$OUT.stderr" \
      || gemini -p "$TASK" --yolo --output-format json > "$OUT.jsonl" 2> "$OUT.stderr" ;;
esac
echo "exit $?" >> "$OUT.stderr"

# What the agent changed in the repo, and whether the test passes afterwards
# (the test runs without the .env loaded, exactly as the agent left it).
{ git status --short; git diff; } > "$OUT.diff" 2>&1
npm test > "$OUT.test" 2>&1; echo "exit $?" >> "$OUT.test"
