# dump-targeted-pdf skill — design

Design patterns source: <https://aiskill.market/blog/cross-platform-skills-that-work>

Focus: portable methodology core + thin platform adapters, tool abstraction, behavioral-equivalence testing

Revised 2026-07-19 after an adversarial spec review (contradictions, hidden dependencies, letter-vs-intent gaps).

## Purpose

A platform-independent agent skill that generates a two-page, job-targeted PDF resume for a given job description.

## Decisions (from brainstorming)

- **Portability scope:** works across agent platforms — Claude Code, Codex CLI, Gemini CLI. Personal use only (not a shareable/marketplace skill); macOS is the only OS target.
- **Canonical home:** this repo (`bryant-finney/about`), because the mechanics all operate on it. The repo is public, so committed skill files must contain nothing private; private specifics (the JD path and delivery location) arrive per-invocation as skill arguments and are never stored in the repo, even gitignored.
- **Scope:** full pipeline in one invocation — JD ingest → tailoring → fact-check → render → review → deliver — with user checkpoints before rendering and before delivery.
- **Architecture:** core methodology (markdown) + shared shell/python scripts + thin per-platform adapters. All three platforms share the two universal capabilities the skill relies on: reading markdown and running shell commands.

## Layout & platform wiring

```text
about/
├── .agents/skills/dump-targeted-pdf/        # canonical (mirrors the ~/.agents/skills convention)
│   ├── SKILL.md                      # Claude Code adapter: frontmatter + $ARGUMENTS parsing + pointer to core/
│   ├── core/
│   │   ├── workflow.md               # end-to-end pipeline with checkpoints + abort protocol
│   │   ├── content-rules.md          # truthfulness rules + known factual traps
│   │   ├── layout-spec.md            # canonical 2-page template + graduated shrink ladder
│   │   └── fact-check.md             # adversarial verification checklist + approved derived phrasings
│   ├── scripts/
│   │   ├── render.sh                 # Jekyll serve lifecycle + freshness check + Chrome headless print + retry
│   │   ├── check_pages.py            # stdlib-only PDF page-count + size assertions
│   │   └── cleanup.sh                # remove temp page, stop server, baseline-relative git gate
│   ├── tests/
│   │   ├── selftest.sh               # deterministic script tests (see Testing)
│   │   └── e2e.sh                    # cross-platform harness; takes <reference.jd.md> <reference.pdf>
├── .claude/skills/dump-targeted-pdf → ../../.agents/skills/dump-targeted-pdf   # symlink; exposes /dump-targeted-pdf
├── AGENTS.md                         # gains a short pointer section for Codex CLI
└── GEMINI.md                         # new; same pointer for Gemini CLI
```

- **Claude Code** discovers the skill via the `.claude/skills` symlink (`/dump-targeted-pdf`). Symlinked project-skill discovery is version-dependent behavior, so adapter validation includes a smoke test (ask `claude` to list available skills; assert `dump-targeted-pdf` appears).
- **Codex CLI** and **Gemini CLI** are wired via a short section in `AGENTS.md` / `GEMINI.md`: "to generate a tailored resume PDF, read `.agents/skills/dump-targeted-pdf/core/workflow.md` and follow it." These pointers are prose conventions, not guaranteed loaders — only the end-to-end test proves each platform actually follows them. Note `AGENTS.md` is currently untracked; wiring it up means reviewing and committing it.
- Core files contain **no tool references** — only methodology and script invocations. The adapters carry the only platform-specific behavior (see Graceful degradation).
- The skill's inputs and outputs are inherently private: JDs and fit-analysis notes in, PDFs out. It is referenced only through the invocation arguments (see Invocation & arguments) — there is no config file. `CHROME_BIN` and `PORT` are env-overridable script defaults (macOS Chrome path, 4000); the about-repo root is derived from the scripts' own location, not configured.
- **Temp content containment:** the one file Jekyll must build — the temp resume page — lives at `_pages/<run-id>.md` for the duration of the run. Everything non-rendered (run state, fact-check artifact, render logs, the printed PDF pre-delivery) lives under a gitignored temp workspace, `.tmp/dump-targeted-pdf/<run-id>/`. The temp page is protected from ever publishing by the cleanup gates (never committed, deleted before the run ends) and the never-commit-during-a-run rule; `.tmp/` must be added to `.gitignore`.

## Invocation & arguments

The skill takes its inputs from the invocation itself — `$ARGUMENTS` in the Claude Code `SKILL.md`; the equivalent free text after the pointer instruction on Codex/Gemini. `workflow.md` defines the parse once for all platforms:

- **JD source** (required): any readable local file path (`.md`, `.txt`, `.eml`, or no extension) or a URL. Filename shape is unconstrained. If absent, the agent asks for it (interactive runs) — scripts themselves hard-fail with a usage message rather than guess.
- **Delivery directory** (optional): defaults to the JD file's parent directory — passing the JD path is the only argument needed in the common case. When the JD source is a URL or pasted text (there is no directory to infer), output to `/tmp` by default.
- **`non-interactive`** (test runs only): see Testing; requires an explicit delivery directory that is _not_ the JD's parent.

## Run identifier definition

Each run gets a generated `run-id` (for example, `r-20260719T153012Z-a7c2`) that is independent of the JD filename. It names everything the run touches: the temp page (`_pages/<run-id>.md`), its permalink (`/resume/<run-id>/`), the temp workspace (`.tmp/dump-targeted-pdf/<run-id>/`), and the script argument. Because it is generated (timestamp + random suffix), it cannot collide with existing `_pages/` permalinks or `_data/employers.yml` keys, and two concurrent runs cannot collide with each other.

## Pipeline (`core/workflow.md`)

1. **Ingest** — resolve the JD from the invocation arguments: any readable local file path, a URL, or pasted text. For JS-rendered Workable postings, fetch `https://apply.workable.com/api/v2/accounts/<org>/jobs/<shortcode>` instead of the page. If a sibling fit-analysis note exists, read it as optional context.
2. **Baseline** — generate `run-id`, record `git status --porcelain` of the about repo to a gitignored run-state file under the temp workspace, and verify no stale temp page (`_pages/r-*.md`) or workspace from an earlier aborted run exists (if one does, stop and surface it). All later gates are relative to this baseline, so a pre-existing dirty tree never blocks a run — only _new_ artifacts do.
3. **Tailoring plan** — per `content-rules.md`: tailored headline, skill-badge reorder, per-employer emphasis. **Checkpoint 1: user approves the plan before anything is written.**
4. **Author** — create the temp page `_pages/<run-id>.md` (permalink `/resume/<run-id>/`, layout `single-no-bar`) with all tailored content inline. Never edit shared files during a run: `_pages/summaries/`, `_resume/`, `_data/`, `_sass/`, `_includes/`, `_config.yml`. All layout tweaks go in the temp page's own page-scoped `@media print` block. Never commit anything while the temp page exists.
5. **Fact-check** — adversarial pass against `_data/employers.yml`, `_resume/`, and `_pages/summaries/` using `fact-check.md`. The pass emits an artifact: a table of claim → quoted source line → verdict, written next to the run state. "Pass" means the artifact exists and contains zero FAIL rows. Violations are fixed and re-checked before rendering.
6. **Render loop** — embed a fresh nonce in the temp page, run `render.sh <run-id> <nonce>`, then `check_pages.py <pdf> 2`; if not exactly 2 pages, apply the next step of the shrink ladder in `layout-spec.md` (new nonce each edit) and re-render. **Checkpoint 2: user reviews the rendered PDF while the temp page still exists**, so requested changes iterate in place instead of starting over.
7. **Deliver + cleanup** — on approval, copy to `<delivery-dir>/<date>-finney-resume.<label>.pdf` where `<label>` is optional and defaults to `targeted` (or another explicit user-provided token), then run `cleanup.sh <run-id>`.

**Abort protocol:** every abort path — checkpoint rejection, render failure past retry, user cancellation, session death — ends with `cleanup.sh <run-id>`. Both `render.sh` and `cleanup.sh` are idempotent, so a fresh session can run `cleanup.sh` cold against a stale run workspace found in step 2.

## Scripts

Scripts take everything they need as explicit arguments (with env-overridable defaults for `CHROME_BIN` and `PORT`, and the about-repo root derived from their own location) and are the only place mechanical knowledge lives — no platform re-derives Chrome flags or page-count logic from prose, and no script reads a config file.

- **`render.sh <run-id> <nonce>`** — manages Jekyll serve and printing of the temp page:
  - Starts `bundle exec jekyll serve` as a background process with live regeneration (never `--detach`, which disables auto-regeneration and would make every shrink-ladder iteration re-print stale output; never piped — output goes to a log file). Reuses an existing server only if the freshness check below passes; a server from another checkout or a stale build fails it, triggering a restart on an alternate port.
  - **Freshness check before printing:** polls `http://127.0.0.1:$PORT/about/resume/<run-id>/` until it returns HTTP 200 _and_ the response body contains `<nonce>` (the agent embeds it in the source each edit, e.g. as an HTML comment). This is what guarantees Chrome prints the current iteration, not a 404 page or a previous build. Timeout → server restart → one retry → loud failure.
  - Prints with Chrome `--headless=new --disable-gpu --no-pdf-header-footer --run-all-compositor-stages-before-draw --virtual-time-budget=10000` (old headless races on external badge images and emits a blank PDF). A watchdog kills a hung Chrome and retries once (known intermittent hang; the retry finishes in seconds).
  - Asserts the output exists and its file size is above a floor calibrated to the badge-laden reference PDFs — a missing-badges render (shields.io slow or rate-limiting) produces a _smaller_ file that could otherwise pass the page-count check while visually broken.
- **`check_pages.py <pdf> [expected]`** — stdlib-only page count using the maximum `/Count N` match (correct for Chrome's flat page tree; explicitly calibrated to Chrome output only — the selftest against known reference PDFs is what keeps this honest); prints the count, exits nonzero on mismatch with `expected`.
- **`cleanup.sh <run-id>`** — deletes `_pages/<run-id>.md` and the run workspace, stops the Jekyll server only if `render.sh` started it, then enforces the leftover-artifact gates: (a) `git status --porcelain` contains no entries that were not in the step-2 baseline; (b) `git ls-files _pages/<run-id>.md` is empty (the temp page was never committed); (c) no commit made since the baseline touches `_pages/<run-id>.md`. Any failure exits nonzero with the offending paths — a committed temp page on this auto-deploying repo is precisely the outcome these gates exist to catch.

## Error handling

| Failure                              | Handling                                                                                                                                                                                                                                                                                                                                                                                                    | Where                              |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| Blank PDF (headless race)            | new headless mode + virtual-time budget; size + page-count assertions                                                                                                                                                                                                                                                                                                                                       | `render.sh`                        |
| Stale render or 404 printed          | nonce freshness check against the target URL before printing                                                                                                                                                                                                                                                                                                                                                | `render.sh`                        |
| Chrome hangs indefinitely            | watchdog timeout, kill, one automatic retry                                                                                                                                                                                                                                                                                                                                                                 | `render.sh`                        |
| Port in use / foreign server         | freshness check fails → restart on alternate port                                                                                                                                                                                                                                                                                                                                                           | `render.sh`                        |
| Output ≠ 2 pages                     | graduated shrink ladder: (1) `@page{margin:0.4in 0.5in}`; (2) `body{font-size:0.92em;line-height:1.28}`; (3) `.skill-badges img{zoom:0.95}`; (4) content cuts by agent judgment (trim oldest roles first). Steps 1–3 may each be applied at most once, at the stated values; a run that needs step 4 is flagged for human review. Applied as a page-scoped `@media print` block, never edits to shared SCSS | `layout-spec.md`, applied by agent |
| Run aborted mid-flight               | abort protocol: every exit path ends in idempotent `cleanup.sh`; stale temp pages and workspaces detected at next run's baseline step                                                                                                                                                                                                                                                                       | `workflow.md`, `cleanup.sh`        |
| Required argument missing/unreadable | hard fail with a clear message in every script; no fallback                                                                                                                                                                                                                                                                                                                                                 | all scripts                        |
| Factual drift                        | fact-check artifact (claim → source quote → verdict) with zero FAIL rows required before rendering                                                                                                                                                                                                                                                                                                          | `fact-check.md`                    |

Note `pdf.scss` chains `page-break-after: avoid` on `h1`–`h4`, `table.tsum`, and `hr`, so heading + table + paragraph form one unbreakable block — the ladder shrinks globally rather than fighting page-break rules.

## Graceful degradation

The one capability that differs across platforms is subagent dispatch:

- **Claude Code:** the fact-check runs as a fresh-context subagent (adversarial reviewer with no stake in the drafted content).
- **Codex CLI / Gemini CLI:** the same `fact-check.md` checklist runs inline as a separate discrete pass after authoring, item by item. The artifact requirement (claim → quoted source line → verdict) is what keeps the inline pass honest: every verdict must quote its source, so a rubber-stamp pass is visible in the artifact.

Everything else (markdown reading, shell execution) is universal, so no other fallbacks are needed.

## Content rules (`core/content-rules.md`)

Promoted from session memory into versioned files:

- Reframe emphasis truthfully; never fabricate. Reorder badges toward the JD; add only truthful concept badges; do not add skills not possessed (AWS **ECS**, not Kubernetes; no DICOM/HL7 hands-on claims).
- Known traps: the 70,000+ figure counts **billboard structures controlled**, not devices; no universal claims ("every environment/release"); don't attach languages to tooling the sources leave unspecified.
- **Approved derived phrasings** (enumerated in `fact-check.md` with their derivations, so the adversarial pass verifies against the approved list instead of flagging them as fabrications): the combined Outdoorlink entry ("Lead / Consulting Software Engineer", 2019 February – 2022 January, "Huntsville, AL / Boston, MA" — derived from the two separate `employers.yml` entries `odl` + `odl-consult`; never consultant-only), "more than 14 years", and "FDA-regulated".
- Canonical template (`core/layout-spec.md`): tailored headline under the name; per-employer one-line intro + 2–6 dense bullets (no `h4` subsections); the combined Outdoorlink header is hand-written markup (it cannot reuse the `tsum.html` include, which renders from a single `employers.yml` key); Earlier Experience and Education as one-row `table.tsum` headers with one-line paragraphs; Security+ folded into Education; shields.io badges (`style=for-the-badge`, color `8ce1ff`).

## Testing

1. **Script tests** (`tests/selftest.sh`, deterministic): render the existing untailored `_pages/pdf.md` page and assert a PDF of pinned size and page count (exact numbers pinned in the script as of implementation date, with a comment on how to re-pin when resume content changes); run `check_pages.py` against the committed PDFs under `assets/pdf/` (already public, so no private material enters the tests); verify `cleanup.sh` passes on a baseline-dirty tree with no new artifacts, and fails when a run workspace remains or has been committed.
2. **Adapter/format validation:** `SKILL.md` frontmatter parses as YAML with `name` and `description`; the `.claude/skills` symlink resolves; `AGENTS.md`/`GEMINI.md` contain the pointer sections; smoke test that `claude` lists the `dump-targeted-pdf` skill.
3. **Structural verification mechanism:** marker checks (name/contact header, tailored headline, employer order, combined Outdoorlink entry, Earlier Experience + Education rows) run against the **served HTML** via the target URL — the same content Chrome prints once the freshness check holds — using curl + grep with exact marker strings listed in `layout-spec.md`. The PDF itself is only checked mechanically for page count and size floor.
4. **Behavioral equivalence (end-to-end, all three platforms):** the test command is `tests/e2e.sh <reference.jd.md> <reference.pdf>` — the user supplies both inputs: the reference job description and the corresponding known-good output PDF produced from it (e.g., the TetraScience pair from the private job-search repo). The harness hard-fails with a clear message if either argument is missing or not a readable file; nothing is ever copied into the repo or committed. It then drives `claude`, `codex exec`, and `gemini` non-interactively with the same instruction: run the skill against the supplied JD. Each output must:
   - be exactly 2 pages, with a file-size floor derived from the supplied reference PDF (e.g., ≥ 80% of its size — the badges-failed-to-load guard, calibrated automatically instead of hardcoded);
   - pass the structural marker checks (mechanism above);
   - produce a fact-check artifact with zero FAIL rows, graded by a **separate** agent invocation (not the one that authored the content);
   - record which shrink-ladder steps fired (a run that needed content cuts is flagged, not silently passed);
   - leave the about repo with no new git artifacts vs its baseline.

   `e2e.sh` documents the exact per-platform invocation, including sandbox/approval flags (e.g., Codex sandbox mode and Gemini approval flags), because default sandboxes can block localhost servers and out-of-workspace writes — an equivalence failure must be attributable to the skill, not platform sandbox config. Final quality judgment vs the supplied reference PDF is the user's.

**Non-interactive mode** exists for these test runs only and is deliberately hobbled for safety: it skips both checkpoints but **refuses to infer the delivery directory from the JD's location** — it requires an explicit delivery-directory argument that is not the JD's parent (`e2e.sh` points it at a scratch directory), so a real delivery can never silently skip review or overwrite the user-supplied reference PDF.

## Out of scope

- Other OSes (Chrome discovery is macOS-first).
- Shareable/marketplace packaging; other people's resume data.
- Cover letters, application tracking, or JD acquisition beyond the ingest formats listed.
- Cursor/Copilot adapters.
