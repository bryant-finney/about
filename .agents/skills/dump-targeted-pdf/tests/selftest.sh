#!/usr/bin/env bash
# selftest.sh — deterministic tests for the dump-targeted-pdf scripts.
# Page-count/size expectations pinned 2026-07-20; re-pin the numbers below
# if assets/pdf/ or _pages/pdf.md content changes.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILL_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd "$SKILL_DIR/../../.." && pwd)
S="$SKILL_DIR/scripts"
cd "$REPO_ROOT"

step() { echo "--- $*"; }

# Failure-path safety net: if any assertion below trips `set -e` mid-scenario,
# this trap still tears down whatever that scenario could have left live —
# the scratch clone, the render scenario's server/workspace on :4123, and any
# scenario-local files/pages. Successful runs already clean up explicitly
# inline (those inline cleanups double as real assertions against
# cleanup.sh's gates); this trap is a backstop, not a substitute, so its own
# gate failures are swallowed with `|| true` to avoid masking the actual test
# failure that triggered it.
scratch=""
on_exit() {
  local status=$?
  rm -f selftest-stray.txt
  rm -f "_pages/r-selftest-stale.md"
  if [[ -n "${rid:-}" ]]; then
    rm -f "_pages/$rid.md"
    rm -rf ".tmp/dump-targeted-pdf/$rid"
  fi
  "$S/cleanup.sh" "r-selftest-render" >/dev/null 2>&1 || true
  if [[ -n "$scratch" && -d "$scratch" ]]; then
    rm -rf "$scratch"
  fi
  exit "$status"
}
trap on_exit EXIT

step "check_pages: pinned counts on committed PDFs"
"$S/check_pages.py" assets/pdf/2026-05-29-resume.pdf 4
"$S/check_pages.py" assets/pdf/2021-10-22-resume.pdf 7
if "$S/check_pages.py" assets/pdf/2026-05-29-resume.pdf 5 2>/dev/null; then
  echo "FAIL: mismatch should exit nonzero" >&2
  exit 1
fi

step "baseline/cleanup: happy path is baseline-relative"
rid="r-selftest-$$"
"$S/baseline.sh" "$rid" >/dev/null
printf -- '---\npermalink: /resume/%s/\n---\nselftest\n' "$rid" >"_pages/$rid.md"
"$S/cleanup.sh" "$rid"
[[ ! -e _pages/$rid.md ]]

step "cleanup: new-artifact gate trips"
"$S/baseline.sh" "$rid" >/dev/null
touch selftest-stray.txt
if "$S/cleanup.sh" "$rid" 2>/dev/null; then
  rm -f selftest-stray.txt
  echo "FAIL: gate should have tripped" >&2
  exit 1
fi
rm -f selftest-stray.txt
rm -rf ".tmp/dump-targeted-pdf/$rid"

step "baseline: stale-page refusal"
touch _pages/r-selftest-stale.md
if "$S/baseline.sh" "r-other-$$" >/dev/null 2>&1; then
  rm -f _pages/r-selftest-stale.md
  echo "FAIL: stale page should refuse" >&2
  exit 1
fi
rm -f _pages/r-selftest-stale.md

step "cleanup: committed-page gate trips (scratch clone)"
scratch=$(mktemp -d)
git clone --quiet --local "$REPO_ROOT" "$scratch/clone"
(
  cd "$scratch/clone"
  cs="./.agents/skills/dump-targeted-pdf/scripts"
  rid2="r-clonetest-1"
  "$cs/baseline.sh" "$rid2" >/dev/null
  printf -- '---\npermalink: /resume/%s/\n---\noops\n' "$rid2" >"_pages/$rid2.md"
  git add "_pages/$rid2.md"
  git -c user.email=t@t -c user.name=t commit --quiet --no-gpg-sign -m "oops: commit temp page"
  if "$cs/cleanup.sh" "$rid2" 2>/dev/null; then
    echo "FAIL: committed temp page should trip the gate" >&2
    exit 1
  fi
)
rm -rf "$scratch"

step "render: untailored /resume/pdf/ renders at pinned size/pages"
out=$(PORT=4123 "$S/render.sh" "r-selftest-render" - /resume/pdf/)
"$S/check_pages.py" "$out" 5
size=$(stat -f%z "$out")
((size >= 150000)) || { echo "FAIL: untailored render only $size bytes" >&2; exit 1; }
"$S/cleanup.sh" "r-selftest-render"
# Note: cleanup.sh intentionally leaves .tmp/dump-targeted-pdf/server/jekyll-*.log
# behind (gitignored, kept for debugging) — that's expected, not a leaked artifact.

echo "SELFTEST PASS"
