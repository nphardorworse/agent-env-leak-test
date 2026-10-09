#!/bin/bash
# Round one's tasks with other models, all driven by Claude Code so only the
# model changes. VARIANTS picks base (no rules, default) and/or protected (deny
# rules and instructions). Run on the host through Fidelius:
#   accio shared --require OPENROUTER_API_KEY ./run-models.sh
# Settings: REPEATS (default 2), MODELS ("label=openrouter/slug ..."), TASKS,
# OUTDIR. SMOKE=1 runs one task once per model.
set -u
cd "$(dirname "$0")" || exit 1
FIX=${FIX:-fixture}
OUTDIR=${OUTDIR:-out-models}
REPEATS=${REPEATS:-2}
VARIANTS=${VARIANTS:-base}
MODELS=${MODELS:-deepseek=deepseek/deepseek-v4-pro-0813 qwen=qwen/qwen3.8-max-0902 kimi=moonshotai/kimi-k3 glm=z-ai/glm-5.3 gemini=google/gemini-3.8-flash grok=x-ai/grok-4.7}
TASKS=${TASKS:-$(cut -d"|" -f1 $FIX/tasks.txt | tr "\n" " ")}
if [ "${SMOKE:-0}" = 1 ]; then REPEATS=1; TASKS=which; fi
mkdir -p "$OUTDIR"
for r in $(seq 1 "$REPEATS"); do
  for m in $MODELS; do
    label=${m%%=*}; slug=${m#*=}
    for v in $VARIANTS; do
    for t in $TASKS; do
      name="claude_$label-$v-$t-r$r"
      [ -f "$OUTDIR/$name.jsonl" ] && { echo "skip $name"; continue; }
      echo "== $name ($slug)"
      docker run --rm --network bridge -e OPENROUTER_API_KEY -e MODEL="$slug" \
        -v "$PWD/$FIX:/fixture:ro" -v "$PWD/$OUTDIR:/out" \
        fidelius-hn-test agent-run "claude_$label" "$v" "$t" "$r"
    done
    done
  done
done
python3 redact.py "$OUTDIR"
python3 scan.py "$OUTDIR" > "$OUTDIR/summary.md"
echo "done: $OUTDIR/summary.md"
