# dump-targeted-pdf Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the `dump-targeted-pdf` agent skill (spec: `docs/superpowers/specs/2026-07-19-resume-pdf-skill-design.md`) that generates a two-page job-targeted PDF resume from a job description, usable from Claude Code, Codex CLI, and Gemini CLI.

**Architecture:** A platform-neutral skill directory at `.agents/skills/dump-targeted-pdf/` containing markdown methodology (`core/`), deterministic shell/python mechanics (`scripts/`), and tests (`tests/`), wired into Claude Code via a `.claude/skills` symlink and into Codex/Gemini via pointer sections in `AGENTS.md`/`GEMINI.md`. Each run is isolated behind a generated run-id: one temp Jekyll page `_pages/<run-id>.md` (the only publishable-path file, policed by cleanup gates) plus a gitignored workspace `.tmp/dump-targeted-pdf/<run-id>/` for everything else.

**Tech Stack:** bash, python3 (stdlib only), Jekyll (`bundle exec jekyll serve`), headless Chrome (`--headless=new`), curl, git.

## Global Constraints

- Repo is public and auto-deploys `main` to GitHub Pages: never commit a temp page (`_pages/r-*.md`); nothing company-specific may be committed anywhere.
- No config file: skill inputs arrive as invocation arguments; scripts take explicit arguments with env-overridable defaults `PORT` (4000) and `CHROME_BIN` (`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`); repo root is derived from script location (`scripts/` is 4 levels below repo root).
- Core files (`core/*.md`) contain no platform/tool references — methodology and script invocations only.
- Markdown style: never hard-wrap prose (one line per paragraph/bullet); the repo's markdownlint hook must pass (`markdownlint-cli2 <file>`); tables and emphasis get normalized by `NODENV_VERSION=22.3.0 prettier --write <file>` when the linter complains about alignment.
- Never run `jekyll serve --detach` (disables regeneration) and never pipe its output (holds the pipe open) — background it with output redirected to a log file.
- Chrome printing always uses `--headless=new --disable-gpu --no-pdf-header-footer --run-all-compositor-stages-before-draw --virtual-time-budget=10000`.
- Commits: conventional-commit messages, `git commit --signoff --gpg-sign`; this repo has no prepare-commit-msg hook.
- macOS only; network access is a precondition (remote theme fetch at build, shields.io badge fetches at print).

## File Structure

```text
.agents/skills/dump-targeted-pdf/
├── SKILL.md                  # Claude Code adapter (Task 9)
├── core/
│   ├── workflow.md           # pipeline + invocation parsing + abort protocol (Task 8)
│   ├── content-rules.md      # truthfulness rules + traps (Task 6)
│   ├── fact-check.md         # checklist + approved phrasings + artifact format (Task 6)
│   └── layout-spec.md        # 2-page template + markers + shrink ladder (Task 7)
├── scripts/
│   ├── check_pages.py        # page-count assertion (Task 2)
│   ├── baseline.sh           # start-of-run stale check + baseline snapshot (Task 3)
│   ├── cleanup.sh            # teardown + leftover-artifact gates (Task 3)
│   └── render.sh             # server lifecycle + freshness check + Chrome print (Task 4)
├── tests/
│   ├── selftest.sh           # deterministic script tests (Task 5)
│   └── e2e.sh                # cross-platform harness (Task 11)
.claude/skills/dump-targeted-pdf  → symlink (Task 9)
AGENTS.md, GEMINI.md              # pointer sections (Task 10)
.gitignore, _config.yml           # plumbing (Task 1)
```

Note: `baseline.sh` is a small addition beyond the spec's three-script list — it makes the spec's pipeline step 2 (baseline snapshot + stale-run detection) deterministic instead of prose-driven. The spec's cleanup gates depend on the baseline artifact, so they belong to the same task.

---

### Task 1: Repo plumbing

**Files:**

- Modify: `.gitignore`
- Modify: `_config.yml:43-53` (the `exclude:` list)

**Interfaces:**

- Produces: gitignored `.tmp/` (all run workspaces live under it), and a site build that never publishes `docs/`, `AGENTS.md`, `GEMINI.md`.

- [ ] **Step 1: Add `.tmp/` to `.gitignore`**

Append to `.gitignore` (final content):

```text
*.code-workspace
.DS_Store
.bundle/config
.jekyll-cache
.jekyll-metadata
.sass-cache
_site
vendor
.tmp/
```

- [ ] **Step 2: Extend the Jekyll `exclude` list**

In `_config.yml`, replace the `exclude:` block with:

```yaml
exclude:
  - .sass-cache/
  - .jekyll-cache/
  - gemfiles/
  - Gemfile
  - Gemfile.lock
  - node_modules/
  - vendor/bundle/
  - vendor/cache/
  - vendor/gems/
  - vendor/ruby/
  - docs/
  - AGENTS.md
  - GEMINI.md
```

- [ ] **Step 3: Verify the build excludes them**

Run: `cd /Users/bf/projects/github/bryant-finney/about && bundle exec jekyll build 2>&1 | tail -2 && ls _site/docs 2>&1; ls _site/AGENTS.md 2>&1`

Expected: build reports `done in N seconds`; both `ls` calls print `No such file or directory`.

- [ ] **Step 4: Verify git ignores `.tmp/`**

Run: `mkdir -p .tmp/dump-targeted-pdf && git status --porcelain | grep -c '\.tmp' || echo IGNORED`

Expected: `IGNORED` (zero matches).

- [ ] **Step 5: Commit**

```bash
git add .gitignore _config.yml
git commit --signoff --gpg-sign -m "chore: exclude skill docs and temp workspace from site and git"
```

---

### Task 2: check_pages.py

**Files:**

- Create: `.agents/skills/dump-targeted-pdf/scripts/check_pages.py`

**Interfaces:**

- Produces: `check_pages.py <pdf> [expected]` — prints the page count to stdout; exit 0 on match/no-expectation, exit 1 on mismatch, exit 2 on usage error. Count heuristic: maximum `/Count N` match (correct for Chrome's flat page tree; calibrated to Chrome output only).

- [ ] **Step 1: Write the script**

```python
#!/usr/bin/env python3
"""Page-count assertion for Chrome-generated PDFs.

Uses the maximum /Count value in the raw PDF bytes. Chrome writes a flat
page tree whose root /Pages node carries the true total, so max() is
correct for Chrome output; other producers (object streams, outlines) may
defeat this heuristic. tests/selftest.sh pins expectations against the
committed PDFs under assets/pdf/ to keep the heuristic honest.
"""

import pathlib
import re
import sys


def page_count(pdf: pathlib.Path) -> int:
    counts = [int(m) for m in re.findall(rb"/Count\s+(\d+)", pdf.read_bytes())]
    if not counts:
        sys.exit(f"check_pages.py: no /Count in {pdf} (not a Chrome-style PDF?)")
    return max(counts)


def main() -> int:
    if len(sys.argv) not in (2, 3):
        print("usage: check_pages.py <pdf> [expected]", file=sys.stderr)
        return 2
    count = page_count(pathlib.Path(sys.argv[1]))
    print(count)
    if len(sys.argv) == 3 and count != int(sys.argv[2]):
        print(f"check_pages.py: expected {sys.argv[2]} pages, got {count}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: Make it executable and verify against committed PDFs**

Run: `chmod +x .agents/skills/dump-targeted-pdf/scripts/check_pages.py && .agents/skills/dump-targeted-pdf/scripts/check_pages.py assets/pdf/2026-05-29-resume.pdf 4 && .agents/skills/dump-targeted-pdf/scripts/check_pages.py assets/pdf/2021-10-22-resume.pdf 7`

Expected: prints `4` then `7`, exit 0 both times.

- [ ] **Step 3: Verify the mismatch path fails**

Run: `.agents/skills/dump-targeted-pdf/scripts/check_pages.py assets/pdf/2026-05-29-resume.pdf 5; echo "exit=$?"`

Expected: prints `4`, stderr `expected 5 pages, got 4`, `exit=1`.

- [ ] **Step 4: Commit**

```bash
git add .agents/skills/dump-targeted-pdf/scripts/check_pages.py
git commit --signoff --gpg-sign -m "feat(skill): add check_pages.py page-count assertion"
```

---

### Task 3: baseline.sh + cleanup.sh

**Files:**

- Create: `.agents/skills/dump-targeted-pdf/scripts/baseline.sh`
- Create: `.agents/skills/dump-targeted-pdf/scripts/cleanup.sh`

**Interfaces:**

- Produces: `baseline.sh <run-id>` — refuses to start when stale `_pages/r-*.md` pages exist; creates `.tmp/dump-targeted-pdf/<run-id>/` containing `baseline-status.txt` (`git status --porcelain` snapshot) and `baseline-head.txt` (HEAD sha); prints the workspace path.
- Produces: `cleanup.sh <run-id>` — idempotent; deletes `_pages/<run-id>.md`, kills any Jekyll server whose pidfile is under `.tmp/dump-targeted-pdf/server/`, then enforces three gates: (a) no new `git status --porcelain` entries vs baseline, (b) `git ls-files _pages/<run-id>.md` empty, (c) no commit since baseline touches that path. Exit 0 and remove the workspace on success; keep the workspace and exit 1 on gate failure.
- Consumes: nothing from other tasks. `render.sh` (Task 4) writes the pidfiles cleanup kills.

- [ ] **Step 1: Write `baseline.sh`**

```bash
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
```

- [ ] **Step 2: Write `cleanup.sh`**

```bash
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
```

- [ ] **Step 3: Verify the happy path on the (possibly dirty) tree**

Run:

```bash
chmod +x .agents/skills/dump-targeted-pdf/scripts/baseline.sh .agents/skills/dump-targeted-pdf/scripts/cleanup.sh
rid="r-plumb-$$"
.agents/skills/dump-targeted-pdf/scripts/baseline.sh "$rid"
printf -- '---\npermalink: /resume/%s/\n---\ntest\n' "$rid" > "_pages/$rid.md"
.agents/skills/dump-targeted-pdf/scripts/cleanup.sh "$rid" && echo CLEAN && ls "_pages/$rid.md" 2>&1
```

Expected: workspace path printed, then `CLEAN`, then `No such file or directory` — the pre-existing dirty tree did not trip the gate because it is baseline-relative.

- [ ] **Step 4: Verify the new-artifact gate trips**

Run:

```bash
rid="r-gate-$$"
.agents/skills/dump-targeted-pdf/scripts/baseline.sh "$rid"
touch stray-artifact.txt
.agents/skills/dump-targeted-pdf/scripts/cleanup.sh "$rid"; echo "exit=$?"
rm stray-artifact.txt && rm -rf ".tmp/dump-targeted-pdf/$rid"
```

Expected: `GATE FAILURE: new git artifacts since baseline:` naming `stray-artifact.txt`, `exit=1`.

- [ ] **Step 5: Verify the stale-page refusal**

Run:

```bash
touch _pages/r-stale-demo.md
.agents/skills/dump-targeted-pdf/scripts/baseline.sh "r-next-$$"; echo "exit=$?"
rm _pages/r-stale-demo.md
```

Expected: `stale temp page(s) from an aborted run` listing `r-stale-demo.md`, `exit=1`.

- [ ] **Step 6: Commit**

```bash
git add .agents/skills/dump-targeted-pdf/scripts/baseline.sh .agents/skills/dump-targeted-pdf/scripts/cleanup.sh
git commit --signoff --gpg-sign -m "feat(skill): add baseline snapshot and gated cleanup scripts"
```

---

### Task 4: render.sh

**Files:**

- Create: `.agents/skills/dump-targeted-pdf/scripts/render.sh`

**Interfaces:**

- Consumes: workspace layout from Task 3 (`.tmp/dump-targeted-pdf/<run-id>/`).
- Produces: `render.sh <run-id> <nonce> [url-path]` — ensures a Jekyll server is serving a *fresh* build of the target page, prints it to `.tmp/dump-targeted-pdf/<run-id>/resume.pdf`, and prints that path to stdout. `url-path` defaults to `/resume/<run-id>/`. A nonce of `-` skips the body-content check (HTTP 200 only) — used only for pre-existing pages like the selftest. Env: `PORT` (default 4000), `CHROME_BIN` (default macOS path), `MIN_PDF_BYTES` (default 150000). Server pidfiles land in `.tmp/dump-targeted-pdf/server/jekyll-<port>.pid` (cleanup.sh kills them).

- [ ] **Step 1: Write `render.sh`**

```bash
#!/usr/bin/env bash
# render.sh <run-id> <nonce> [url-path] — serve fresh, print to PDF, assert size.
set -euo pipefail
[[ $# -ge 2 && $# -le 3 ]] || { echo "usage: render.sh <run-id> <nonce> [url-path]" >&2; exit 2; }
RUN_ID=$1
NONCE=$2
URL_PATH=${3:-/resume/$RUN_ID/}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../../.." && pwd)
PORT=${PORT:-4000}
CHROME_BIN=${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}
MIN_PDF_BYTES=${MIN_PDF_BYTES:-150000}

WORKSPACE="$REPO_ROOT/.tmp/dump-targeted-pdf/$RUN_ID"
SERVER_DIR="$REPO_ROOT/.tmp/dump-targeted-pdf/server"
mkdir -p "$WORKSPACE" "$SERVER_DIR"
PDF_OUT="$WORKSPACE/resume.pdf"

url() { echo "http://127.0.0.1:$1/about$URL_PATH"; }

fresh() { # $1=port: 200 + nonce present (nonce '-' skips body check)
  local body
  body=$(curl -fsS --max-time 2 "$(url "$1")" 2>/dev/null) || return 1
  [[ $NONCE == - ]] && return 0
  grep -qF "$NONCE" <<<"$body"
}

start_server() { # $1=port
  (cd "$REPO_ROOT" && nohup bundle exec jekyll serve --port "$1" --host 127.0.0.1 \
    >"$SERVER_DIR/jekyll-$1.log" 2>&1 &
   echo $! >"$SERVER_DIR/jekyll-$1.pid")
}

wait_fresh() { # $1=port $2=seconds
  local i
  for ((i = 0; i < $2; i++)); do
    fresh "$1" && return 0
    sleep 1
  done
  return 1
}

if curl -fsS --max-time 2 "http://127.0.0.1:$PORT/about/" >/dev/null 2>&1; then
  # something serves the site root; only trust it if the target page goes fresh
  if ! wait_fresh "$PORT" 60; then
    echo "render.sh: server on :$PORT is stale or foreign; starting on alternate port" >&2
    PORT=$((PORT + 1))
    start_server "$PORT"
    wait_fresh "$PORT" 180 || { echo "render.sh: $(url "$PORT") never became fresh" >&2; exit 1; }
  fi
else
  start_server "$PORT"
  wait_fresh "$PORT" 180 || { echo "render.sh: $(url "$PORT") never became fresh" >&2; exit 1; }
fi

print_pdf() {
  rm -f "$PDF_OUT"
  "$CHROME_BIN" --headless=new --disable-gpu --no-pdf-header-footer \
    --run-all-compositor-stages-before-draw --virtual-time-budget=10000 \
    --print-to-pdf="$PDF_OUT" "$(url "$PORT")" >"$WORKSPACE/chrome.log" 2>&1 &
  local pid=$! waited=0
  while kill -0 "$pid" 2>/dev/null; do
    ((waited += 1))
    if ((waited > 60)); then
      echo "render.sh: chrome hung; killing and retrying" >&2
      kill -9 "$pid" 2>/dev/null || true
      return 1
    fi
    sleep 1
  done
  wait "$pid"
}

print_pdf || print_pdf || { echo "render.sh: chrome failed twice; see $WORKSPACE/chrome.log" >&2; exit 1; }

[[ -s $PDF_OUT ]] || { echo "render.sh: no output at $PDF_OUT" >&2; exit 1; }
size=$(stat -f%z "$PDF_OUT")
if ((size < MIN_PDF_BYTES)); then
  echo "render.sh: PDF only $size bytes (< $MIN_PDF_BYTES) — badges likely failed to load; check network and retry" >&2
  exit 1
fi
echo "$PDF_OUT"
```

- [ ] **Step 2: Verify against a nonce-bearing temp page**

Run:

```bash
chmod +x .agents/skills/dump-targeted-pdf/scripts/render.sh
rid="r-rendertest-$$"; nonce="n-$RANDOM$RANDOM"
.agents/skills/dump-targeted-pdf/scripts/baseline.sh "$rid"
cat > "_pages/$rid.md" <<EOF
---
layout: single-no-bar
title: ""
permalink: /resume/$rid/
---
<!-- $nonce -->
render smoke test
EOF
PORT=4123 MIN_PDF_BYTES=5000 .agents/skills/dump-targeted-pdf/scripts/render.sh "$rid" "$nonce"
.agents/skills/dump-targeted-pdf/scripts/check_pages.py ".tmp/dump-targeted-pdf/$rid/resume.pdf"
.agents/skills/dump-targeted-pdf/scripts/cleanup.sh "$rid" && echo CLEAN
```

Expected: render.sh prints the PDF path (first build takes 1-3 minutes for the remote-theme fetch), check_pages prints `1`, then `CLEAN`. `MIN_PDF_BYTES=5000` is lowered because this stub page has no badges.

- [ ] **Step 3: Verify the freshness check catches an edit**

Run (immediately after re-creating the same page, while the Task 2 server is still up):

```bash
rid="r-freshtest-$$"; .agents/skills/dump-targeted-pdf/scripts/baseline.sh "$rid"
printf -- '---\nlayout: single-no-bar\ntitle: ""\npermalink: /resume/%s/\n---\n<!-- first -->\n' "$rid" > "_pages/$rid.md"
PORT=4123 MIN_PDF_BYTES=5000 .agents/skills/dump-targeted-pdf/scripts/render.sh "$rid" "first" >/dev/null
printf -- '---\nlayout: single-no-bar\ntitle: ""\npermalink: /resume/%s/\n---\n<!-- second -->\n' "$rid" > "_pages/$rid.md"
PORT=4123 MIN_PDF_BYTES=5000 .agents/skills/dump-targeted-pdf/scripts/render.sh "$rid" "second" && echo FRESH-OK
.agents/skills/dump-targeted-pdf/scripts/cleanup.sh "$rid" && echo CLEAN
```

Expected: second render waits for Jekyll's regeneration to serve the `second` nonce before printing, then `FRESH-OK`, then `CLEAN`. This is the regression test for the `--detach`/stale-print failure mode.

- [ ] **Step 4: Commit**

```bash
git add .agents/skills/dump-targeted-pdf/scripts/render.sh
git commit --signoff --gpg-sign -m "feat(skill): add render.sh with freshness check and hang watchdog"
```

---

### Task 5: tests/selftest.sh

**Files:**

- Create: `.agents/skills/dump-targeted-pdf/tests/selftest.sh`

**Interfaces:**

- Consumes: all Task 2-4 script interfaces exactly as specified.
- Produces: `tests/selftest.sh` — no arguments; exit 0 with `SELFTEST PASS` when all deterministic checks pass; nonzero with the failing check named otherwise.

- [ ] **Step 1: Write `selftest.sh`**

```bash
#!/usr/bin/env bash
# selftest.sh — deterministic tests for the dump-targeted-pdf scripts.
# Page-count/size expectations pinned 2026-07-19; re-pin the numbers below
# if assets/pdf/ or _pages/pdf.md content changes.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILL_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd "$SKILL_DIR/../../.." && pwd)
S="$SKILL_DIR/scripts"
cd "$REPO_ROOT"

step() { echo "--- $*"; }

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
"$S/check_pages.py" "$out" 4
size=$(stat -f%z "$out")
((size >= 150000)) || { echo "FAIL: untailored render only $size bytes" >&2; exit 1; }
"$S/cleanup.sh" "r-selftest-render"

echo "SELFTEST PASS"
```

- [ ] **Step 2: Run it**

Run: `chmod +x .agents/skills/dump-targeted-pdf/tests/selftest.sh && .agents/skills/dump-targeted-pdf/tests/selftest.sh`

Expected: each `--- ...` step prints in order, ending `SELFTEST PASS` (exit 0). The render step is the slow one (server boot).

- [ ] **Step 3: Commit**

```bash
git add .agents/skills/dump-targeted-pdf/tests/selftest.sh
git commit --signoff --gpg-sign -m "test(skill): add deterministic selftest for skill scripts"
```

---

### Task 6: core/content-rules.md + core/fact-check.md

**Files:**

- Create: `.agents/skills/dump-targeted-pdf/core/content-rules.md`
- Create: `.agents/skills/dump-targeted-pdf/core/fact-check.md`

**Interfaces:**

- Produces: the tailoring rules `workflow.md` (Task 8) cites at step 3, and the checklist + artifact format it cites at step 5. The artifact filename `fact-check.md` inside the run workspace is what `e2e.sh` (Task 11) greps for FAIL rows.

- [ ] **Step 1: Write `content-rules.md`** (remember: no hard-wrapped prose)

```markdown
# Content rules

Reframe emphasis truthfully; never fabricate. The resume may reorder, trim, and re-weight real experience toward the job description, but every claim must be traceable to a source line in `_data/employers.yml`, `_resume/`, or `_pages/summaries/` — or to the approved derived phrasings listed in `fact-check.md`.

## Rules

- Reorder the skill badges toward the JD; add only truthful concept badges; keep the set honest — do not add skills not possessed. Known specifics: AWS **ECS**, not Kubernetes; no hands-on DICOM/HL7 claims.
- Reframe the summary and lead bullets toward the JD (e.g., for a backend role, foreground Python services, distributed/event-driven systems, data pipelines, AWS, regulated-healthcare experience).
- Trim the oldest roles (IERUS/RMCI) into one compact "Earlier Experience" block to fit two pages.
- No universal claims ("every environment", "every release") unless a source line says so.
- Do not attach languages to tooling the sources leave unspecified (e.g., the release CLI is not documented as Python).

## Known traps

- The 70,000+ figure counts **billboard structures controlled**, not devices.
- Outdoorlink must appear as one combined entry, never consultant-only (that erases the lead role and breaks the timeline).
```

- [ ] **Step 2: Write `fact-check.md`**

```markdown
# Fact-check

An adversarial verification pass over the drafted resume content, run after authoring and before rendering. The checker's stance: every claim is false until a source line proves it.

## Sources of truth

- `_data/employers.yml` — titles, dates, locations, links
- `_resume/` — role bullets
- `_pages/summaries/` — summary paragraphs and the skills list

## Checklist

For every claim in the drafted content (each bullet, headline fragment, date, title, and badge):

1. Quote the exact source line that supports it, or match it to an approved derived phrasing below.
2. Numbers: verify the quantity and its **unit** (see the 70,000+ trap in `content-rules.md`).
3. Titles and date ranges: verify against `_data/employers.yml` exactly.
4. Badges: each badge names a skill present in the current skills list or a truthful concept the sources support.
5. Scope words ("every", "all", "always"): reject unless the source uses them.

## Approved derived phrasings

These are pre-approved compositions of source facts; verify usage matches the derivation instead of flagging them:

- **Combined Outdoorlink entry:** "Lead / Consulting Software Engineer", 2019 February – 2022 January, "Huntsville, AL / Boston, MA" — derived from the two `employers.yml` entries `odl` (Lead Software Engineer, 2019-02 to 2020-08) + `odl-consult` (Software Engineering Consultant, 2020-08 to 2022-01). Never consultant-only.
- **"more than 14 years"** of engineering experience — used on the public `/resume/pdf/` page.
- **"FDA-regulated"** describing Elucid's domain — approved phrasing even though repo sources do not contain the string "FDA".

## Artifact

Write the results to `fact-check.md` inside the run workspace as a table, one row per claim:

| Claim | Source (file: quoted line) | Verdict |
| ----- | -------------------------- | ------- |

Verdict is `PASS` or `FAIL` (with a one-clause reason). The pass succeeds only when the artifact exists and contains zero `FAIL` rows; fix violations in the drafted content and re-check until it does.
```

- [ ] **Step 3: Lint**

Run: `markdownlint-cli2 .agents/skills/dump-targeted-pdf/core/content-rules.md .agents/skills/dump-targeted-pdf/core/fact-check.md 2>&1 | tail -1`

Expected: `Summary: 0 error(s)` (if table-alignment errors appear, run `NODENV_VERSION=22.3.0 prettier --write` on the files and re-lint).

- [ ] **Step 4: Commit**

```bash
git add .agents/skills/dump-targeted-pdf/core/content-rules.md .agents/skills/dump-targeted-pdf/core/fact-check.md
git commit --signoff --gpg-sign -m "docs(skill): add content rules and fact-check methodology"
```

---

### Task 7: core/layout-spec.md

**Files:**

- Create: `.agents/skills/dump-targeted-pdf/core/layout-spec.md`

**Interfaces:**

- Consumes: the print classes that exist in `_sass/pdf.scss` (`.resume-header`, `.skill-badges`, `table.tsum`) and the include `tsum.html`.
- Produces: the temp-page template, the exact structural marker strings (used by `workflow.md` step 6 and delivered as `markers.txt`), and the shrink ladder.

- [ ] **Step 1: Write `layout-spec.md`**

````markdown
# Layout spec — canonical two-page template

The canonical structure (established by the Clairity/TetraScience PDFs). The temp page is a complete, inline, self-contained document: it must not modify or depend on edits to any shared file.

## Page skeleton

```liquid
---
layout: single-no-bar
title: ""
permalink: /resume/RUN_ID/
---

<!-- nonce: NONCE -->

<header class="resume-header">
  <h1>Bryant Finney</h1>
  <p class="resume-title">TAILORED HEADLINE</p>
  <p class="resume-contact">
    <a href="mailto:finneybp@gmail.com"><i class="fas fa-envelope"></i>finneybp@gmail.com</a>
    <span><i class="fas fa-map-marker-alt"></i>Boston, MA</span>
    <a href="https://www.linkedin.com/in/bryant-finney/"><i class="fab fa-linkedin"></i>LinkedIn</a>
    <a href="https://github.com/bryant-finney"><i class="fab fa-github"></i>GitHub</a>
  </p>
</header>

---

TAILORED 2-3 SENTENCE SUMMARY

---

## Skills

<div class="skill-badges" markdown="1">
BADGES
</div>

## Work Experience

EMPLOYER SECTIONS

## Earlier Experience

EARLIER ROWS

## Education

EDUCATION ROW + PARAGRAPH

<style>
@media print {
  /* shrink-ladder steps get appended here, one per line */
}
</style>
```

## Section rules

- **Headline:** tailored to the JD under the name (e.g., "Principal Engineer · Cloud Platform & Distributed Systems").
- **Badges:** shields.io, `style=for-the-badge`, color `8ce1ff`; reordered toward the JD per `content-rules.md`.
- **Employers, in order:** Elucid, Hometap, Morse Corp, Outdoorlink — each an `{% include tsum.html employer=KEY %}` header (or hand-written equivalent) followed by a one-line intro and 2–6 dense bullets. No `h4` subsections.
- **Outdoorlink:** ONE combined entry with a hand-written header table (the `tsum.html` include renders from a single `employers.yml` key and cannot express the combined entry): title "Lead / Consulting Software Engineer", dates "2019 February – 2022 January", location "Huntsville, AL / Boston, MA".
- **Earlier Experience and Education:** one-row `table.tsum` headers (title · company left, dates right) with one-line paragraphs; Security+ folded into the Education paragraph.

## Structural markers

Verify against the served page HTML (`curl` the page URL, `grep -F` each string). All must be present, and the employer names must appear in the order listed:

- `Bryant Finney`
- `resume-title`
- `finneybp@gmail.com`
- `Elucid`
- `Hometap`
- `MORSE` (case-insensitive match acceptable)
- `Lead / Consulting Software Engineer`
- `Earlier Experience`
- `Education`
- `Security+`

## Shrink ladder

When the render is not exactly 2 pages, append the next step (one line) inside the page's `@media print` block and re-render. Each of steps 1–3 may be applied at most once, at exactly these values. A run that reaches step 4 must be flagged for human review — record it in the ladder log.

1. `@page { margin: 0.4in 0.5in; }`
2. `body { font-size: 0.92em; line-height: 1.28; }`
3. `.skill-badges img { zoom: 0.95; }`
4. Content cuts by judgment: trim oldest roles first, then reduce bullets per employer (respect `content-rules.md`).

Note: `pdf.scss` chains `page-break-after: avoid` across `h1`–`h4`, `table.tsum`, and `hr`, so heading + table + paragraph form one unbreakable block — shrink globally; do not fight page-break rules per-block. If the render is *under* 2 pages, remove ladder steps or restore trimmed content instead.

## Ladder log

Record every ladder step applied (or `none`) in `ladder.txt` inside the run workspace, one line per step, e.g. `1 margins`, `4 content-cuts FLAG-FOR-REVIEW`.
````

- [ ] **Step 2: Lint**

Run: `markdownlint-cli2 .agents/skills/dump-targeted-pdf/core/layout-spec.md 2>&1 | tail -1`

Expected: `Summary: 0 error(s)`.

- [ ] **Step 3: Commit**

```bash
git add .agents/skills/dump-targeted-pdf/core/layout-spec.md
git commit --signoff --gpg-sign -m "docs(skill): add canonical layout spec with markers and shrink ladder"
```

---

### Task 8: core/workflow.md

**Files:**

- Create: `.agents/skills/dump-targeted-pdf/core/workflow.md`

**Interfaces:**

- Consumes: every script and core file above, by exact name and signature.
- Produces: the single methodology entrypoint all three platform adapters point at.

- [ ] **Step 1: Write `workflow.md`**

````markdown
# dump-targeted-pdf workflow

Generate a two-page, job-targeted PDF resume for a given job description. Follow the steps in order; the scripts referenced live in `../scripts/` (invoke them relative to this file's directory).

## Invocation & arguments

Parse the invocation arguments:

- **JD source** (required): any readable local file path (`.md`, `.txt`, `.eml`, or no extension) or a URL. If absent, ask the user for it before doing anything else.
- **Delivery directory** (optional): where the final PDF lands. Defaults to the JD file's parent directory; when the JD source is a URL or pasted text, defaults to `/tmp`.
- **`non-interactive`** (test runs only): skips both checkpoints. In this mode an explicit delivery directory is REQUIRED and it must not be the JD file's parent — refuse to proceed otherwise. Deliver the run artifacts (`fact-check.md`, `ladder.txt`, `markers.txt`) alongside the PDF.
- **Label** (optional): a short token for the delivered filename; defaults to `targeted`.

## Hard rules (all steps)

- Never edit shared files during a run: `_pages/summaries/`, `_resume/`, `_data/`, `_sass/`, `_includes/`, `_config.yml`. All tailored content and layout tweaks live inline in the temp page.
- Never commit anything while the temp page exists.
- Every abort path — checkpoint rejection, render failure, cancellation — ends with `cleanup.sh <run-id>`.

## Steps

1. **Ingest.** Read the JD from the resolved source. For JS-rendered Workable postings, fetch `https://apply.workable.com/api/v2/accounts/<org>/jobs/<shortcode>` instead of the page. If a sibling fit-analysis note exists next to the JD file, read it as context.
2. **Baseline.** Generate the run-id: `RUN_ID="r-$(date -u +%Y%m%dT%H%M%SZ)-$(openssl rand -hex 2)"`. Run `baseline.sh "$RUN_ID"` — it refuses to start if a stale temp page from an aborted run exists (run `cleanup.sh` for the stale run-id, then retry). It prints the run workspace path; the fact-check artifact and ladder log go there.
3. **Tailoring plan.** Draft the plan per `content-rules.md`: tailored headline, badge reorder, per-employer emphasis, planned trims. **Checkpoint 1 (skip only in non-interactive mode): present the plan and get user approval before writing anything.**
4. **Author.** Create `_pages/$RUN_ID.md` from the skeleton in `layout-spec.md`, all content inline, with a fresh nonce in the `<!-- nonce: ... -->` comment.
5. **Fact-check.** Run the `fact-check.md` checklist against the drafted page, adversarially — if the platform supports dispatching a fresh-context subagent, use one; otherwise perform the checklist inline as a separate discrete pass, quoting the source line for every claim. Write the artifact table to `<workspace>/fact-check.md`. Zero FAIL rows required; fix and re-check until clean.
6. **Render loop.** Run `render.sh "$RUN_ID" "<nonce>"` then `check_pages.py <printed-pdf> 2`. If not exactly 2 pages, apply the next shrink-ladder step from `layout-spec.md` (new nonce each edit, appended to the ladder log) and re-render. Then verify the structural markers from `layout-spec.md` against the served page HTML (`curl` + `grep -F`); write the results to `<workspace>/markers.txt`. **Checkpoint 2 (skip only in non-interactive mode): show the user the rendered PDF while the temp page still exists; iterate on feedback in place.**
7. **Deliver + cleanup.** Copy the PDF to `<delivery-dir>/$(date +%Y-%m-%d)-finney-resume.<label>.pdf` — if that file already exists, stop and ask before overwriting (in non-interactive mode, fail instead). In non-interactive mode also copy `fact-check.md`, `ladder.txt`, and `markers.txt` from the workspace to the delivery directory. Finally run `cleanup.sh "$RUN_ID"` and confirm it exits 0 — its gates are the definition of done.
````

- [ ] **Step 2: Lint**

Run: `markdownlint-cli2 .agents/skills/dump-targeted-pdf/core/workflow.md 2>&1 | tail -1`

Expected: `Summary: 0 error(s)`.

- [ ] **Step 3: Commit**

```bash
git add .agents/skills/dump-targeted-pdf/core/workflow.md
git commit --signoff --gpg-sign -m "docs(skill): add end-to-end workflow with checkpoints and abort protocol"
```

---

### Task 9: SKILL.md + Claude Code symlink

**Files:**

- Create: `.agents/skills/dump-targeted-pdf/SKILL.md`
- Create: `.claude/skills/dump-targeted-pdf` (symlink → `../../.agents/skills/dump-targeted-pdf`)

**Interfaces:**

- Consumes: `core/workflow.md` (Task 8).
- Produces: the `/dump-targeted-pdf` skill in Claude Code.

- [ ] **Step 1: Write `SKILL.md`**

```markdown
---
name: dump-targeted-pdf
description: Generate a two-page job-targeted PDF resume from a job description. Use when the user wants a resume tailored to a specific role or JD. Arguments: the JD file path or URL (required), optionally a delivery directory, a filename label, and the word non-interactive (test harnesses only).
---

Invocation arguments: $ARGUMENTS

Read `core/workflow.md` (relative to this file) and follow it end to end, starting with its "Invocation & arguments" section to parse the arguments above. Platform note: this platform supports subagents — run the workflow's fact-check step (step 5) as a fresh-context subagent acting as an adversarial reviewer.
```

- [ ] **Step 2: Create the symlink**

Run: `mkdir -p .claude/skills && ln -s ../../.agents/skills/dump-targeted-pdf .claude/skills/dump-targeted-pdf && ls -L .claude/skills/dump-targeted-pdf/SKILL.md`

Expected: the `ls -L` resolves and prints the SKILL.md path (proves the symlink target is correct).

- [ ] **Step 3: Validate frontmatter parses**

Run: `python3 -c "import pathlib; t=pathlib.Path('.agents/skills/dump-targeted-pdf/SKILL.md').read_text().split('---')[1]; import yaml; d=yaml.safe_load(t); print(d['name'], bool(d['description']))"`

Expected: `dump-targeted-pdf True`.

- [ ] **Step 4: Smoke-test discovery in Claude Code**

Run: `cd /Users/bf/projects/github/bryant-finney/about && claude -p "Reply with only the names of the skills available to you" 2>&1 | grep -i dump-targeted-pdf`

Expected: a line containing `dump-targeted-pdf`. If absent, symlinked project-skill discovery may have changed in this Claude Code version — fall back to making `.claude/skills/dump-targeted-pdf` a real directory containing only `SKILL.md` (adjusting its `core/workflow.md` reference to `../../../.agents/skills/dump-targeted-pdf/core/workflow.md`) and note the deviation in the commit message.

- [ ] **Step 5: Commit**

```bash
git add .agents/skills/dump-targeted-pdf/SKILL.md .claude/skills/dump-targeted-pdf
git commit --signoff --gpg-sign -m "feat(skill): add Claude Code adapter and skill symlink"
```

---

### Task 10: AGENTS.md + GEMINI.md pointers

**Files:**

- Modify: `AGENTS.md` (currently untracked — review the whole file before committing it)
- Create: `GEMINI.md`

**Interfaces:**

- Consumes: `core/workflow.md` path.
- Produces: Codex CLI and Gemini CLI wiring.

- [ ] **Step 1: Append the pointer section to `AGENTS.md`**

Append to the end of the existing `AGENTS.md`:

```markdown

## Generating a targeted resume PDF

To generate a two-page resume PDF tailored to a job description, read `.agents/skills/dump-targeted-pdf/core/workflow.md` and follow it end to end, parsing the user's request per its "Invocation & arguments" section. This platform has no subagent dispatch: perform the workflow's fact-check step inline as a separate discrete pass, quoting the source line for every claim.
```

- [ ] **Step 2: Create `GEMINI.md`**

```markdown
# GEMINI.md

This file provides guidance to Gemini CLI when working in this repository. Build/architecture context: see `AGENTS.md`.

## Generating a targeted resume PDF

To generate a two-page resume PDF tailored to a job description, read `.agents/skills/dump-targeted-pdf/core/workflow.md` and follow it end to end, parsing the user's request per its "Invocation & arguments" section. This platform has no subagent dispatch: perform the workflow's fact-check step inline as a separate discrete pass, quoting the source line for every claim.
```

- [ ] **Step 3: Lint and verify the pointer sections exist**

Run: `markdownlint-cli2 AGENTS.md GEMINI.md 2>&1 | tail -1 && grep -l 'dump-targeted-pdf/core/workflow.md' AGENTS.md GEMINI.md`

Expected: `Summary: 0 error(s)` then both filenames.

- [ ] **Step 4: Review `AGENTS.md` in full (it was never committed) and commit**

Read the whole `AGENTS.md` to confirm nothing unintended is in it (it mirrors `CLAUDE.md`), then:

```bash
git add AGENTS.md GEMINI.md
git commit --signoff --gpg-sign -m "feat(skill): wire Codex and Gemini adapters via AGENTS.md and GEMINI.md"
```

---

### Task 11: tests/e2e.sh

**Files:**

- Create: `.agents/skills/dump-targeted-pdf/tests/e2e.sh`

**Interfaces:**

- Consumes: `check_pages.py`; the non-interactive mode contract from `workflow.md` (delivers `resume PDF + fact-check.md + ladder.txt + markers.txt` to the delivery directory).
- Produces: `e2e.sh <reference.jd.md> <reference.pdf>` — drives `claude`, `codex`, and `gemini` against the supplied JD, then applies the mechanical equivalence checks per platform and prints a PASS/FAIL summary (exit nonzero on any FAIL).

- [ ] **Step 1: Write `e2e.sh`**

```bash
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
Arguments: JD source $JD ; delivery directory $1 ; non-interactive.
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
  if [[ -f $dir/ladder.txt ]] && grep -q '^4 ' "$dir/ladder.txt"; then
    echo "$name: WARN content cuts were needed (ladder step 4) — review required"
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
```

- [ ] **Step 2: Verify argument validation**

Run: `chmod +x .agents/skills/dump-targeted-pdf/tests/e2e.sh && .agents/skills/dump-targeted-pdf/tests/e2e.sh /nonexistent.md /nonexistent.pdf; echo "exit=$?"`

Expected: `e2e.sh: JD not readable: /nonexistent.md`, `exit=2`. (The full harness run happens in Task 12 with the user's reference pair.)

- [ ] **Step 3: Commit**

```bash
git add .agents/skills/dump-targeted-pdf/tests/e2e.sh
git commit --signoff --gpg-sign -m "test(skill): add cross-platform e2e harness"
```

---

### Task 12: Full verification pass

**Files:** none created — verification only.

- [ ] **Step 1: Run the selftest end-to-end**

Run: `.agents/skills/dump-targeted-pdf/tests/selftest.sh`

Expected: `SELFTEST PASS`.

- [ ] **Step 2: Adapter/format validation**

Run: `ls -L .claude/skills/dump-targeted-pdf/SKILL.md && grep -l 'dump-targeted-pdf/core/workflow.md' AGENTS.md GEMINI.md && markdownlint-cli2 .agents/skills/dump-targeted-pdf/core/*.md .agents/skills/dump-targeted-pdf/SKILL.md 2>&1 | tail -1`

Expected: symlink resolves, both pointer files match, `Summary: 0 error(s)`.

- [ ] **Step 3: Confirm a clean tree and push nothing yet**

Run: `git status --porcelain`

Expected: only pre-existing untracked files (`_posts/2023-11-2-compose-patterns.md`); no skill-related entries. Do not push — the user decides when `main` deploys.

- [ ] **Step 4: e2e run (requires the user)**

Ask the user for their reference pair (e.g., the TetraScience JD + known-good PDF from the private job-search repo) and run: `.agents/skills/dump-targeted-pdf/tests/e2e.sh <reference.jd.md> <reference.pdf>`

Expected: `PASS (mechanical checks)` for all three platforms, no new git artifacts, then the user grades the artifacts/PDFs. Each platform run consumes that platform's quota and takes several minutes; treat a platform failure as attributable to sandbox flags first (see the comment in `e2e.sh`) before blaming the skill.

---

## Self-Review Notes

- Spec coverage: plumbing (Task 1), scripts (2–4), selftest (5), core methodology (6–8), Claude adapter + symlink + smoke test (9), Codex/Gemini wiring (10), e2e harness (11), full verification incl. the user-driven e2e run (12). The spec's "structural verification" lives in `layout-spec.md` markers + `workflow.md` step 6 + `e2e.sh` markers.txt check.
- `baseline.sh` is a deliberate, documented addition to the spec's script list (see File Structure note).
- Type/name consistency: run-id format `r-<UTC>Z-<hex4>`; workspace `.tmp/dump-targeted-pdf/<run-id>/`; artifacts `fact-check.md`, `ladder.txt`, `markers.txt`; delivered name `<date>-finney-resume.<label>.pdf` — used identically in Tasks 3, 4, 5, 8, and 11.
