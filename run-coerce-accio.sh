#!/bin/bash
# Coercion, accio arm, on the test Mac after round four:
#   accio shared --require OPENROUTER_API_KEY ./run-coerce-accio.sh
set -u
cd "$(dirname "$0")" || exit 1
export FIX=fixture6 OUTDIR=${OUTDIR:-out-coerce-accio} REPEATS=${REPEATS:-3} REQUIRE_BROKEN_DB=1
ARMS=pressure TASKS=pressure ./run4.sh "$@"
ARMS=inject TASKS=start ./run4.sh "$@"
