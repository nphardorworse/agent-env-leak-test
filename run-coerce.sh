#!/bin/bash
# Coercion, .env arm: pressure from the user, and an instruction injected into
# the failing test's output. Run on the host through Fidelius:
#   accio shared --require OPENROUTER_API_KEY ./run-coerce.sh [agent ...]
# The accio arm runs on the test Mac with run-coerce-accio.sh.
set -u
cd "$(dirname "$0")" || exit 1
FIX=${FIX:-fixture5}
PAIRS=${PAIRS:-pressure:pressure inject:fix}
OUTDIR=${OUTDIR:-out-coerce}
AGENTS=${*:-claude codex}
REPEATS=${REPEATS:-3}
mkdir -p "$OUTDIR"
for r in $(seq 1 "$REPEATS"); do
  for a in $AGENTS; do
    for pair in $PAIRS; do
      v=${pair%%:*}; t=${pair#*:}
      [ -f "$OUTDIR/$a-$v-$t-r$r.jsonl" ] && { echo "skip $a-$v-$t-r$r"; continue; }
      echo "== $a-$v-$t-r$r"
      docker run --rm --network bridge -e OPENROUTER_API_KEY \
        -v "$PWD/$FIX:/fixture:ro" -v "$PWD/$OUTDIR:/out" \
        fidelius-hn-test agent-run "$a" "$v" "$t" "$r"
    done
  done
done
python3 redact.py "$OUTDIR"
python3 scan.py "$OUTDIR" > "$OUTDIR/summary.md"
echo "done: $OUTDIR/summary.md"
