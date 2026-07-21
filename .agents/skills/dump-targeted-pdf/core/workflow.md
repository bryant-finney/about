# dump-targeted-pdf workflow

Generate a two-page, job-targeted PDF resume for a given job description. Follow the steps in order; the scripts referenced live in `../scripts/` (invoke them relative to this file's directory).

## Invocation & arguments

Parse the invocation arguments:

- `[source-jd]` (required positional): any readable local file path (`.md`, `.txt`, `.eml`, or no extension) or a URL. If absent, ask the user for it before doing anything else.
- `--output <delivery-dir>` (optional): where the final PDF lands. Defaults to the JD file's parent directory; when `[source-jd]` is a URL or pasted text, defaults to `/tmp`.
- `--force` (optional, test runs only): skips both checkpoints (non-interactive mode). In this mode, `--output` is REQUIRED and must not be the JD file's parent directory — refuse to proceed otherwise. Deliver the run artifacts (`fact-check.md`, `ladder.txt`, `markers.txt`) alongside the PDF.
- `--label <token>` (optional): a short token for the delivered filename; defaults to `targeted`.

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
