#!/usr/bin/env bash
# baseline.sh <run-id> — start-of-run stale check + git baseline snapshot.
set -euo pipefail
[[ $# -eq 1 ]] || { echo "usage: baseline.sh <run-id>" >&2; exit 2; }
RUN_ID=$1
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../../.." && pwd)

shopt -s nullglob
stale=("$REPO_ROOT"/_pages/r-*.md)
if ((${#stale[@]})); then
  echo "baseline.sh: stale temp page(s) from an aborted run:" >&2
  printf '  %s\n' "${stale[@]}" >&2
  echo "baseline.sh: run cleanup.sh <run-id> for each stale run-id first" >&2
  exit 1
fi

WORKSPACE="$REPO_ROOT/.tmp/dump-targeted-pdf/$RUN_ID"
mkdir -p "$WORKSPACE"
git -C "$REPO_ROOT" status --porcelain >"$WORKSPACE/baseline-status.txt"
git -C "$REPO_ROOT" rev-parse HEAD >"$WORKSPACE/baseline-head.txt"
echo "$WORKSPACE"
