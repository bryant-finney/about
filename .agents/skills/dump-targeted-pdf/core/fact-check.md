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
