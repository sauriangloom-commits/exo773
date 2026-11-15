#!/usr/bin/env bash
# Export a candidate build into this copy's own artifact area and record exactly
# which source state produced it. Never writes into the original project.
#
#   tools/qa/build_candidate.sh [build-id]
#
# Output: <copy>/builds/qa/candidates/<build-id>/RavenloftFoundationEdit.exe + BUILD.txt
# This editable copy has no Git repository, so revision fields become "no-git".
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="$ROOT/builds/qa"
# The engine install is shared read-only; override with GODOT_EXE if it moves.
GODOT="${GODOT_EXE:-$ROOT/../Project Ravenloft/Godot_v4.7.2-stable_win64.exe}"
ID="${1:-$(date +%Y-%m-%d_%H%M%S)}"
OUT="$WORKSPACE/candidates/$ID"
mkdir -p "$OUT"

"$GODOT" --headless --path "$ROOT" \
  --export-release "Windows Desktop" "$OUT/RavenloftFoundationEdit.exe"

HASH="$(sha256sum "$OUT/RavenloftFoundationEdit.exe" | cut -d' ' -f1)"
SIZE="$(stat -c%s "$OUT/RavenloftFoundationEdit.exe")"
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  SOURCE_HEAD="$(git -C "$ROOT" rev-parse HEAD)"
  WORKTREE_ENTRIES="$(git -C "$ROOT" status --porcelain=v1 | wc -l)"
  WORKTREE_DIFF="$(git -C "$ROOT" diff | sha256sum | cut -d' ' -f1)"
  UNTRACKED_COUNT="$(git -C "$ROOT" ls-files --others --exclude-standard | grep -c . || true)"
  # Null-delimited: QA profiles can live under paths containing spaces.
  UNTRACKED_HASH="$(cd "$ROOT" && git ls-files -z --others --exclude-standard | sort -z | xargs -0 -r sha256sum | sha256sum | cut -d' ' -f1)"
else
  SOURCE_HEAD="no-git"
  WORKTREE_ENTRIES="0"
  WORKTREE_DIFF="no-git"
  UNTRACKED_COUNT="0"
  UNTRACKED_HASH="no-git"
fi
{
  echo "build_id=$ID"
  echo "built_at=$(date -Iseconds)"
  echo "project=$ROOT"
  echo "source_head=$SOURCE_HEAD"
  echo "worktree_entries=$WORKTREE_ENTRIES"
  echo "worktree_diff_sha256=$WORKTREE_DIFF"
  echo "untracked_files=$UNTRACKED_COUNT"
  echo "untracked_source_sha256=$UNTRACKED_HASH"
  echo "exe_sha256=$HASH"
  echo "exe_bytes=$SIZE"
  echo "export_preset=Windows Desktop"
} > "$OUT/BUILD.txt"
cat "$OUT/BUILD.txt"
