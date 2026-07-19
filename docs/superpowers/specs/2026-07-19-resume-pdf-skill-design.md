# resume-pdf skill — design

**Date:** 2026-07-19
**Status:** approved (brainstorming session)
**Design patterns source:** <https://aiskill.market/blog/cross-platform-skills-that-work> — portable
methodology core + thin platform adapters, tool abstraction, graceful degradation, behavioral-equivalence
testing.

## Purpose

A platform-independent agent skill that generates a two-page, job-targeted PDF resume from a job
description, automating the manual workflow previously used for the Clairity and TetraScience
applications (temp Jekyll page → Chrome headless print → 2-page check → deliver to the private
job-search repo).

## Decisions (from brainstorming)

- **Portability scope:** works across agent platforms — Claude Code, Codex CLI, Gemini CLI. Personal
  use only (not a shareable/marketplace skill); macOS is the only OS target.
- **Canonical home:** this repo (`bryant-finney/about`), because the mechanics all operate on it.
  The repo is public, so committed skill files must contain nothing private; private specifics
  (delivery path) live in a gitignored `config.env`.
- **Scope:** full pipeline in one invocation — JD ingest → tailoring → fact-check → render → deliver —
  with user checkpoints before rendering and at delivery.
- **Architecture:** core methodology (markdown) + shared shell/python scripts + thin per-platform
  adapters. All three platforms share the two universal capabilities the skill relies on: reading
  markdown and running shell commands.
- **Testing bar:** end-to-end runs on all three platforms against the TetraScience JD
  (`jobs.tetrascience.cloud-platform-architect.jd.md`), compared with the known-good reference
  `2026-06-11-finney-resume.tetrascience.pdf`.

## Layout & platform wiring

```text
about/
├── .agents/skills/resume-pdf/        # canonical (mirrors the ~/.agents/skills convention)
│   ├── SKILL.md                      # Claude Code adapter: frontmatter + pointer to core/ + scripts/
│   ├── core/
│   │   ├── workflow.md               # end-to-end pipeline with checkpoints
│   │   ├── content-rules.md          # truthfulness rules + known factual traps
│   │   ├── layout-spec.md            # canonical 2-page template + graduated shrink ladder
│   │   └── fact-check.md             # adversarial verification checklist
│   ├── scripts/
│   │   ├── render.sh                 # Jekyll serve lifecycle + Chrome headless print + retry
│   │   ├── check_pages.py            # stdlib-only PDF page-count assertion
│   │   └── cleanup.sh                # remove temp page, stop server, verify clean git status
│   ├── tests/
│   │   └── selftest.sh               # deterministic script tests (see Testing)
│   ├── config.env.example            # committed: ABOUT_REPO, CHROME_BIN, PORT, DELIVER_DIR placeholders
│   └── config.env                    # gitignored: real values (incl. private-repo delivery path)
├── .claude/skills/resume-pdf → ../../.agents/skills/resume-pdf   # symlink; exposes /resume-pdf
├── AGENTS.md                         # gains a short pointer section for Codex CLI
└── GEMINI.md                         # new; same pointer for Gemini CLI
```

- **Claude Code** discovers the skill via the `.claude/skills` symlink (`/resume-pdf`).
- **Codex CLI** and **Gemini CLI** are wired via a short section in `AGENTS.md` / `GEMINI.md`:
  "to generate a tailored resume PDF, read `.agents/skills/resume-pdf/core/workflow.md` and follow it."
- Core files contain **no tool references** — only methodology and script invocations. The adapters
  carry the only platform-specific behavior (see Graceful degradation).
- The private repo (`private-job-search-2026`) keeps what is inherently private: JDs in, PDFs and
  fit-analysis notes out/in, referenced only through `DELIVER_DIR` in the gitignored `config.env`.
- **Jekyll exclusion:** `docs/`, `AGENTS.md`, and `GEMINI.md` must be added to the `exclude` list in
  `_config.yml` so they are not deployed into the built site (dot-directories are excluded by Jekyll
  automatically). `config.env` must be added to `.gitignore`.

## Pipeline (`core/workflow.md`)

1. **Ingest** — resolve the JD: a `jobs.<company>.<role>.jd.md` or `.eml` under `DELIVER_DIR`, a URL,
   or pasted text. For JS-rendered Workable postings, fetch
   `https://apply.workable.com/api/v2/accounts/<org>/jobs/<shortcode>` instead of the page. Read the
   matching `jobs.<company>.<role>.md` fit-analysis note if one exists.
2. **Tailoring plan** — per `content-rules.md`: tailored headline, skill-badge reorder, per-employer
   emphasis. **Checkpoint 1: user approves the plan before anything is written.**
3. **Author** — create temp `_pages/<company>.md` (permalink `/resume/<company>/`, layout
   `single-no-bar`) with all tailored content inline; never edit shared `_pages/summaries/` or
   `_resume/` files. Reuse `_sass/pdf.scss` print classes (`.resume-header`, `.skill-badges`,
   `table.tsum`) per `layout-spec.md`.
4. **Fact-check** — adversarial pass against `_data/employers.yml`, `_resume/`, and
   `_pages/summaries/` using `fact-check.md`. Violations are fixed before rendering.
5. **Render loop** — `render.sh <company>` then `check_pages.py <pdf> 2`; if not exactly 2 pages,
   apply the next step of the shrink ladder in `layout-spec.md` and re-render.
6. **Deliver** — copy to `DELIVER_DIR/<date>-finney-resume.<company>.pdf`, run
   `cleanup.sh <company>`, and confirm the about repo's `git status` is clean.
   **Checkpoint 2: user reviews the delivered PDF.**

## Scripts

All scripts source `config.env` (falling back to `config.env.example` defaults where sensible) and
are the only place mechanical knowledge lives — no platform re-derives Chrome flags or page-count
logic from prose.

- **`render.sh <slug>`** — health-checks `http://127.0.0.1:$PORT/about/` and reuses a running Jekyll
  server, else starts `bundle exec jekyll serve --detach` (never piped — a detached server holds the
  pipe open). Prints the page to PDF with Chrome `--headless=new --disable-gpu
--no-pdf-header-footer --run-all-compositor-stages-before-draw --virtual-time-budget=10000`
  (old headless races on external badge images and emits a blank PDF). A watchdog kills a hung
  Chrome and retries once (known intermittent hang; the retry finishes in seconds). Fails loudly on
  a missing/tiny output file.
- **`check_pages.py <pdf> [expected]`** — stdlib-only `/Count` regex page count; prints the count,
  exits nonzero on mismatch with `expected`.
- **`cleanup.sh <slug>`** — deletes `_pages/<slug>.md`, stops Jekyll only if `render.sh` started it,
  and exits nonzero if `git status --porcelain` in `ABOUT_REPO` is non-empty (leftover-artifact
  protection: nothing company-specific may remain to publish).

## Error handling

| Failure                   | Handling                                                                                                                                                                                                                                                                              | Where                              |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| Blank PDF (headless race) | new headless mode + virtual-time budget; size + page-count assertions                                                                                                                                                                                                                 | `render.sh`                        |
| Chrome hangs indefinitely | watchdog timeout, kill, one automatic retry                                                                                                                                                                                                                                           | `render.sh`                        |
| Port already in use       | health-check and reuse the server if it serves the site; else alternate port                                                                                                                                                                                                          | `render.sh`                        |
| Output ≠ 2 pages          | graduated shrink ladder: (1) `@page{margin:0.4in 0.5in}`; (2) `body{font-size:0.92em;line-height:1.28}`; (3) `.skill-badges img{zoom:0.95}`; (4) content cuts by agent judgment (trim oldest roles first) — applied as a page-scoped `@media print` block, never edits to shared SCSS | `layout-spec.md`, applied by agent |
| Temp page left behind     | `cleanup.sh` git-status gate is part of the definition of done                                                                                                                                                                                                                        | `cleanup.sh`                       |
| Factual drift             | fact-check checklist pass required before rendering                                                                                                                                                                                                                                   | `fact-check.md`                    |

Note `pdf.scss` chains `page-break-after: avoid` on `h1`–`h4`, `table.tsum`, and `hr`, so heading +
table + paragraph form one unbreakable block — the ladder shrinks globally rather than fighting
page-break rules.

## Graceful degradation

The one capability that differs across platforms is subagent dispatch:

- **Claude Code:** the fact-check runs as a fresh-context subagent (adversarial reviewer with no
  stake in the drafted content).
- **Codex CLI / Gemini CLI:** the same `fact-check.md` checklist runs inline as a separate
  discrete pass after authoring, item by item, quoting the source line for every claim verified.

Everything else (markdown reading, shell execution) is universal, so no other fallbacks are needed.

## Content rules (`core/content-rules.md`)

Promoted from session memory into versioned files:

- Reframe emphasis truthfully; never fabricate. Reorder badges toward the JD; add only truthful
  concept badges; do not add skills not possessed (AWS **ECS**, not Kubernetes; no DICOM/HL7
  hands-on claims).
- Known traps: the 70,000+ figure counts **billboard structures controlled**, not devices; no
  universal claims ("every environment/release"); don't attach languages to tooling the sources
  leave unspecified. "FDA-regulated" and "more than 14 years" are approved phrasings.
- Canonical template (`core/layout-spec.md`): tailored headline under the name; per-employer
  one-line intro + 2–6 dense bullets (no `h4` subsections); Outdoorlink as ONE combined entry
  ("Lead / Consulting Software Engineer", 2019 February – 2022 January, "Huntsville, AL / Boston,
  MA"); Earlier Experience and Education as one-row `table.tsum` headers with one-line paragraphs;
  Security+ folded into Education; shields.io badges (`style=for-the-badge`, color `8ce1ff`).

## Testing

1. **Script tests** (`tests/selftest.sh`, deterministic): render the existing untailored
   `_pages/pdf.md` page and assert a non-trivial PDF of the expected page count; run
   `check_pages.py` against known reference PDFs; verify `cleanup.sh` leaves the repo clean and
   fails when a temp page remains.
2. **Adapter/format validation:** `SKILL.md` frontmatter parses as YAML with `name` and
   `description`; the `.claude/skills` symlink resolves; `AGENTS.md`/`GEMINI.md` contain the pointer
   sections.
3. **Behavioral equivalence (end-to-end, all three platforms):** drive `claude`, `codex exec`, and
   `gemini` non-interactively with the same instruction: run the skill against
   `jobs.tetrascience.cloud-platform-architect.jd.md`. `workflow.md` defines a **non-interactive
   mode** (invoked by saying "run non-interactively") that skips both checkpoints; the test prompt
   uses it and overrides `DELIVER_DIR` to a scratch directory so the real
   `2026-06-11-finney-resume.tetrascience.pdf` stays untouched as the reference. Each output must:
   - be exactly 2 pages;
   - contain the canonical structural markers (name/contact header, tailored headline, employer
     order, combined Outdoorlink entry, Earlier Experience + Education rows);
   - pass the `fact-check.md` checklist;
   - leave the about repo's git status clean.
     Final quality judgment vs the reference PDF is the user's, at the review checkpoint.

## Out of scope

- Other OSes (Chrome discovery is macOS-first, though `CHROME_BIN` is configurable).
- Shareable/marketplace packaging; other people's resume data.
- Cover letters, application tracking, or JD acquisition beyond the ingest formats listed.
- Cursor/Copilot adapters.
