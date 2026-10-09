#!/bin/bash
# Round four: real Claude Code and Codex on a Mac, no Docker. Run from a plain
# Terminal (not from inside an agent), with the OpenRouter key from Fidelius:
#   accio shared --require OPENROUTER_API_KEY ./run4.sh [agent ...]
# Settings: REPEATS (default 5), ARMS (default "control accio"), TASKS, OUTDIR.
# SMOKE=1 runs one repeat of one task per agent and arm.
set -u
cd "$(dirname "$0")" || exit 1
HERE=$PWD
FIX=$HERE/${FIX:-fixture4}
OUTDIR=$HERE/${OUTDIR:-out4}
AGENTS=${*:-claude codex}
ARMS=${ARMS:-control accio}
REPEATS=${REPEATS:-5}
TASKS=${TASKS:-$(cut -d"|" -f1 "$FIX/tasks.txt" | tr "\n" " ")}
if [ "${SMOKE:-0}" = 1 ]; then REPEATS=1; TASKS=start; fi
CLAUDE_MODEL=anthropic/claude-sonnet-5.5
CODEX_MODEL=openai/gpt-6-sol

# Markers from a surrounding agent would make accio mask for the wrong reason.
unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT CODEX_THREAD_ID CODEX_SANDBOX
# macOS has no `timeout`, so runs are capped with perl's alarm (900 s).
# Each agent starts from a clean environment: the shell basics plus what it
# needs to reach its model. accio starts this script with everything in
# shared, fake keys included, and none of that may reach the agent.
clean() {
  env -i HOME="$HOME" USER="$USER" LOGNAME="${LOGNAME:-$USER}" SHELL="${SHELL:-/bin/zsh}" \
    PATH="$PATH" TMPDIR="${TMPDIR:-/tmp/}" LANG="${LANG:-en_US.UTF-8}" TERM=xterm-256color "$@"
}

mkdir -p "$OUTDIR"
for r in $(seq 1 "$REPEATS"); do
  for a in $AGENTS; do
    for arm in $ARMS; do
      for t in $TASKS; do
        name="$a-$arm-$t-r$r"; out="$OUTDIR/$name"
        [ -f "$out.jsonl" ] && { echo "skip $name"; continue; }
        # Tasks that need the broken fake DATABASE_URL stop if someone fixed it
        # in Fidelius (an agent can propose a fix through accio import).
        if [ "${REQUIRE_BROKEN_DB:-0}" = 1 ] && ! accio shared sh -c 'case "$DATABASE_URL" in postgress://*) exit 0;; *) exit 1;; esac'; then
          echo "stop: DATABASE_URL in Fidelius is no longer the broken fake value"; exit 1
        fi
        echo "== $name"
        task=$(grep "^$t|" "$FIX/tasks.txt" | cut -d'|' -f2-)
        # Fresh repo and fresh agent config every run: no memory, no CLAUDE.md
        # or AGENTS.md from anywhere, no plugins or MCP servers.
        work=$(mktemp -d /tmp/envtest.XXXXXX)
        repo=$work/shop-api; cfg=$work/config
        cp -R "$FIX/$arm" "$repo"; mkdir -p "$cfg"
        # Dependencies go in before the agent starts (node_modules is gitignored).
        [ -f "$repo/package-lock.json" ] && (cd "$repo" && npm ci --silent --no-audit --no-fund > /dev/null 2>&1)
        (cd "$repo" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm init)
        case "$a" in
          claude)
            (cd "$repo" && clean CLAUDE_CONFIG_DIR="$cfg" ANTHROPIC_BASE_URL=https://openrouter.ai/api \
              ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY" ANTHROPIC_API_KEY="" \
              ANTHROPIC_SMALL_FAST_MODEL=$CLAUDE_MODEL \
              perl -e 'alarm shift; exec @ARGV' 900 claude -p "$task" --model $CLAUDE_MODEL --output-format stream-json --verbose \
                --strict-mcp-config --dangerously-skip-permissions --max-turns 12 \
                > "$out.jsonl" 2> "$out.stderr" < /dev/null)
            echo "exit $?" >> "$out.stderr"
            cp -R "$cfg/projects" "$out.sessions" 2>/dev/null ;;
          codex)
            cat > "$cfg/config.toml" <<TOML
model = "$CODEX_MODEL"
model_provider = "openrouter"
[model_providers.openrouter]
name = "OpenRouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"
wire_api = "responses"
TOML
            (cd "$repo" && clean CODEX_HOME="$cfg" OPENROUTER_API_KEY="$OPENROUTER_API_KEY" \
                perl -e 'alarm shift; exec @ARGV' 900 codex exec --json --skip-git-repo-check \
                --dangerously-bypass-approvals-and-sandbox "$task" \
                > "$out.jsonl" 2> "$out.stderr" < /dev/null)
            echo "exit $?" >> "$out.stderr"
            cp -R "$cfg/sessions" "$out.sessions" 2>/dev/null ;;
        esac
        (cd "$repo" && { git status --short; git diff; } > "$out.diff" 2>&1)
        rm -rf "$work"
      done
    done
  done
done
# Replace the OpenRouter key wherever an agent's output caught it.
python3 redact.py "$OUTDIR"
python3 scan.py "$OUTDIR" > "$OUTDIR/summary.md"
echo "done: $OUTDIR/summary.md"
