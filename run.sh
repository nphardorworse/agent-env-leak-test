#!/bin/bash
# Run on the host through Fidelius, so the three API keys never sit in a file:
#   accio shared --require OPENROUTER_API_KEY ./run.sh [agent ...]
set -u
cd "$(dirname "$0")"
AGENTS=${*:-claude codex}
FIX=${FIX:-fixture}
OUTDIR=${OUTDIR:-out}
TASKS=${TASKS:-$(cut -d"|" -f1 $FIX/tasks.txt | tr "\n" " ")}
mkdir -p $OUTDIR
for a in $AGENTS; do
  for v in base protected; do
    for t in $TASKS; do
      echo "== $a $v $t"
      docker run --rm --network bridge \
        -e OPENROUTER_API_KEY \
        -v "$PWD/$FIX:/fixture:ro" -v "$PWD/$OUTDIR:/out" \
        fidelius-hn-test agent-run "$a" "$v" "$t"
    done
  done
done
# The agents can see their own API key in their environment. Replace those
# values in everything we saved before anyone reads the transcripts.
python3 redact.py $OUTDIR
python3 scan.py $OUTDIR > $OUTDIR/summary.md
echo "done: $OUTDIR/summary.md"
