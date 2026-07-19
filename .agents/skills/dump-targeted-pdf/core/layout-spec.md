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
