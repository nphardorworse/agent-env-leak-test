#!/bin/bash
# Round two's three programs through dotenvx run, no agent: CLAUDECODE=1 and
# output to a file, the way an agent would read it. Counts the fake keys in
# each output, without and with --redact (added in dotenvx 2.10.0, off by
# default). Writes compare/dotenvx-<version>/dotenvx.txt and <mode>-<program>.out.
#   VERSION=1.75.1 MODES=plain compare/run-dotenvx.sh   # the first run, before --redact existed
set -u
cd "$(dirname "$0")/.." || exit 1
VERSION=${VERSION:-2.33.0}
MODES=${MODES:-plain redact}
OUT="compare/dotenvx-$VERSION"
mkdir -p "$OUT"
docker run --rm -e VERSION="$VERSION" -e MODES="$MODES" -v "$PWD/fixture2/base:/fx:ro" -v "$PWD/$OUT:/out" fidelius-hn-test bash -c '
set -u; cp -r /fx /tmp/app && cd /tmp/app
npm i -s --no-audit --no-fund @dotenvx/dotenvx@$VERSION >/dev/null 2>&1
echo "dotenvx $(npx dotenvx --version)" > /out/dotenvx.txt
for mode in $MODES; do
  flag=""; [ "$mode" = redact ] && flag="--redact"
  for p in "start:node src/server.js" "weather:node src/weather.js" "doctor:bash scripts/doctor.sh"; do
    n=${p%%:*}; cmd=${p#*:}
    CLAUDECODE=1 npx dotenvx run -q $flag -- $cmd > /out/$mode-$n.out 2>&1
    printf "%-7s %-8s keys in output: %s\n" $mode $n "$(grep -oE "CANARY_[A-Za-z0-9]+" /out/$mode-$n.out | sort -u | wc -l)" >> /out/dotenvx.txt
  done
done'
cat "$OUT/dotenvx.txt"
