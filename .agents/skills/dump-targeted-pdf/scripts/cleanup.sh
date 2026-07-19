#!/usr/bin/env bash
# cleanup.sh <run-id> — idempotent teardown + leftover-artifact gates.
# A committed temp page on this auto-deploying repo is exactly what the
# gates exist to catch: fail loudly, keep the workspace for forensics.
set -euo pipefail
[[ $# -eq 1 ]] || { echo "usage: cleanup.sh <run-id>" >&2; exit 2; }
RUN_ID=$1
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../../.." && pwd)
WORKSPACE="$REPO_ROOT/.tmp/dump-targeted-pdf/$RUN_ID"
SERVER_DIR="$REPO_ROOT/.tmp/dump-targeted-pdf/server"
PAGE_REL="_pages/$RUN_ID.md"

rm -f "$REPO_ROOT/$PAGE_REL"

shopt -s nullglob
for pidfile in "$SERVER_DIR"/jekyll-*.pid; do
  kill "$(cat "$pidfile")" 2>/dev/null || true
  rm -f "$pidfile"
done

fail=0
if [[ -n $(git -C "$REPO_ROOT" ls-files "$PAGE_REL") ]]; then
  echo "GATE FAILURE: $PAGE_REL is tracked by git — remove it from the index/history before pushing" >&2
  fail=1
fi
if [[ -f $WORKSPACE/baseline-head.txt ]]; then
  base=$(cat "$WORKSPACE/baseline-head.txt")
  if git -C "$REPO_ROOT" log --oneline "$base"..HEAD -- "$PAGE_REL" | grep -q .; then
    echo "GATE FAILURE: a commit since $base touches $PAGE_REL" >&2
    fail=1
  fi
  new=$(comm -13 <(sort "$WORKSPACE/baseline-status.txt") <(git -C "$REPO_ROOT" status --porcelain | sort))
  if [[ -n $new ]]; then
    echo "GATE FAILURE: new git artifacts since baseline:" >&2
    echo "$new" >&2
    fail=1
  fi
else
  echo "cleanup.sh: warning: no baseline recorded for $RUN_ID; ran page/server teardown only" >&2
fi

if ((fail)); then
  echo "cleanup.sh: gates failed; workspace kept at $WORKSPACE" >&2
  exit 1
fi
rm -rf "$WORKSPACE"
