#!/usr/bin/env bash
# e2e.sh <reference.jd.md> <reference.pdf> — cross-platform behavioral-equivalence harness.
# Drives claude, codex, and gemini non-interactively against the supplied JD and
# checks each delivered PDF mechanically. Final quality judgment vs the
# reference PDF is the user's.
set -euo pipefail
[[ $# -eq 2 ]] || { echo "usage: e2e.sh <reference.jd.md> <reference.pdf>" >&2; exit 2; }
JD=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
REF=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
[[ -r $JD ]] || { echo "e2e.sh: JD not readable: $JD" >&2; exit 2; }
[[ -r $REF ]] || { echo "e2e.sh: reference PDF not readable: $REF" >&2; exit 2; }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILL_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd "$SKILL_DIR/../../.." && pwd)
CP="$SKILL_DIR/scripts/check_pages.py"

ref_size=$(stat -f%z "$REF")
floor=$((ref_size * 80 / 100))
scratch=$(mktemp -d /tmp/dump-targeted-pdf-e2e.XXXXXX)
echo "e2e: scratch=$scratch size-floor=$floor bytes"

pre_status=$(git -C "$REPO_ROOT" status --porcelain | sort)

prompt() { # $1=delivery dir
  cat <<EOF
Generate a targeted resume PDF using the dump-targeted-pdf skill: read
.agents/skills/dump-targeted-pdf/core/workflow.md and follow it end to end.
Arguments: $JD | --output $1 | --force.
EOF
}

run_platform() { # $1=name  $2...=command; prompt is appended as last arg
  local name=$1; shift
  local dir="$scratch/$name"
  mkdir -p "$dir"
  echo "=== $name"
  if ! "$@" "$(prompt "$dir")" >"$scratch/$name.log" 2>&1; then
    echo "$name: RUN FAILED (see $scratch/$name.log)"
    return 0
  fi
}

# Per-platform flags: each needs shell access (jekyll server, curl to
# localhost, chrome) and write access to the scratch dir outside the repo.
run_platform claude claude -p --permission-mode bypassPermissions
run_platform codex codex exec --sandbox danger-full-access
run_platform gemini gemini --yolo -p

fail=0
for name in claude codex gemini; do
  dir="$scratch/$name"
  pdf=$(ls "$dir"/*-finney-resume.*.pdf 2>/dev/null | head -1 || true)
  ok=1
  [[ -n $pdf ]] || { echo "$name: FAIL no delivered PDF"; ok=0; }
  if [[ -n $pdf ]]; then
    "$CP" "$pdf" 2 >/dev/null || { echo "$name: FAIL page count != 2"; ok=0; }
    size=$(stat -f%z "$pdf")
    ((size >= floor)) || { echo "$name: FAIL size $size < floor $floor"; ok=0; }
  fi
  [[ -f $dir/fact-check.md ]] || { echo "$name: FAIL missing fact-check.md"; ok=0; }
  if [[ -f $dir/fact-check.md ]] && grep -q '| *FAIL' "$dir/fact-check.md"; then
    echo "$name: FAIL fact-check artifact contains FAIL rows"; ok=0
  fi
  [[ -f $dir/ladder.txt ]] || { echo "$name: FAIL missing ladder.txt"; ok=0; }
  if [[ -f $dir/ladder.txt ]] && grep -q '^7 ' "$dir/ladder.txt"; then
    echo "$name: WARN content cuts were needed (ladder step 7) — review required"
  fi
  [[ -f $dir/markers.txt ]] || { echo "$name: FAIL missing markers.txt"; ok=0; }
  if [[ -f $dir/markers.txt ]] && grep -qi 'missing' "$dir/markers.txt"; then
    echo "$name: FAIL markers.txt reports missing markers"; ok=0
  fi
  ((ok)) && echo "$name: PASS (mechanical checks)"
  ((ok)) || fail=1
done

post_status=$(git -C "$REPO_ROOT" status --porcelain | sort)
if [[ $pre_status != "$post_status" ]]; then
  echo "e2e: FAIL repo has new git artifacts after the runs" >&2
  diff <(echo "$pre_status") <(echo "$post_status") >&2 || true
  fail=1
fi

echo
echo "e2e: grade each fact-check artifact with a SEPARATE agent invocation, e.g.:"
echo "  claude -p \"Adversarially grade this fact-check artifact against the sources in $REPO_ROOT: \$(cat $scratch/claude/fact-check.md)\""
echo "e2e: outputs in $scratch — compare each PDF against $REF yourself for final quality judgment"
exit $fail
