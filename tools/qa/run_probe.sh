#!/usr/bin/env bash
# Run one asserted combat probe and write its evidence under this copy's builds/qa.
#
#   tools/qa/run_probe.sh <cleave|trip> <scenario> [path-to-exe]
#
# With no exe it runs the current source (windowed; the probe needs a real
# viewport). With an exe it runs that exported build instead. Evidence goes to
# <copy>/builds/qa/runs/<timestamp>_<demo>_<scenario>/ and the command exits
# non-zero unless the probe prints "PROBE RESULT PASS".
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="$ROOT/builds/qa"
DEMO="${1:?usage: run_probe.sh <cleave|trip> <scenario> [exe]}"
SCENARIO="${2:?scenario required}"
SOURCE_GODOT="$ROOT/../Project Ravenloft/Godot_v4.7.2-stable_win64.exe"
EXE="${3:-$SOURCE_GODOT}"
ID="$(date +%Y-%m-%d_%H%M%S)_${DEMO}_${SCENARIO}"
OUT="$WORKSPACE/qa/runs/$ID"
mkdir -p "$OUT/shots"

if [ "$EXE" = "$SOURCE_GODOT" ]; then
  "$EXE" --path "$ROOT" --quit-after 3000 -- \
    "--demo-$DEMO" "--$DEMO-probe" "--$DEMO-scenario=$SCENARIO" \
    "--trip-shots=$OUT/shots" > "$OUT/probe.log" 2>&1 || true
else
  "$EXE" --quit-after 3000 -- \
    "--demo-$DEMO" "--$DEMO-probe" "--$DEMO-scenario=$SCENARIO" \
    "--trip-shots=$OUT/shots" > "$OUT/probe.log" 2>&1 || true
fi

grep -E "PROBE (RESULT|CHECK FAIL)" "$OUT/probe.log" || true
if ! grep -q "PROBE RESULT PASS" "$OUT/probe.log"; then
  echo "PROBE FAILED — see $OUT/probe.log" >&2
  exit 1
fi
echo "evidence: $OUT"
