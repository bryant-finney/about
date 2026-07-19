# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## What This Is

A personal website and blog for Bryant Finney, deployed to GitHub Pages at https://bryant-finney.github.io/about/. It doubles as a resume/portfolio site.

## Build & Serve

```bash
bundle install                  # install dependencies
bundle exec jekyll serve        # local dev server at http://localhost:4000/about/
bundle exec jekyll build        # build to _site/
```

The site uses `baseurl: /about`, so all local URLs are under `http://localhost:4000/about/`.

## Architecture

**Jekyll + GitHub Pages** using the [Minimal Mistakes](https://mmistakes.github.io/minimal-mistakes/) remote theme (`mmistakes/minimal-mistakes@4.24.0`).

### Content model

- **`_posts/`** — Blog posts (categories: `fun`, `tech`). The blog page (`_pages/blog.md`) splits posts by category.
- **`_resume/`** — A custom collection. Each employer has a subdirectory (e.g. `_resume/hometap/`) containing markdown files for individual roles/responsibilities. Each file has front matter with `resume_tag` (matching a key in `_data/employers.yml`) and `i_order` (sort order).
- **`_pages/summaries/`** — Short summary markdown files included inline by the resume page and referenced via `summary_file` in `_data/employers.yml`.
- **`_data/employers.yml`** — Structured data for each employer: name, title, dates, location, logo, site link, and summary file reference. Keys (e.g. `elucid`, `hometap`) are used as `resume_tag` values in `_resume/` collection items.
- **`_data/navigation.yml`** — Top-level nav: Blog, Resume, Me.

### Resume page rendering

`_pages/resume.md` iterates over employer tags in a hardcoded order, pulling data from `_data/employers.yml` and rendering each employer's summary + collection items. The layout `single-no-bar` is a full-width variant of the default `single` layout (removes the sidebar progress bar).

### Custom includes

- `trow.html` — Renders a table row for an employer attribute (title, start, end, site).
- `tsum.html` — Renders a compact employer summary table.
- `frankie.html`, `insta.html`, `ghub.html`, `fig-expand` — Embeds for social/media content.
- `head/custom.html`, `footer/custom.html` — Theme override injection points.

### Styling

`_sass/columns.scss` defines the two-column resume layout (`.row`, `.left-col` at 25%, `.right-col` at 75%) and logo sizing.

## Adding Content

**New blog post:** Create `_posts/YYYY-MM-DD-slug.md` with `categories: [tech]` or `categories: [fun]` in front matter.

**New employer/role to resume:**
1. Add employer entry to `_data/employers.yml`
2. Create summary file in `_pages/summaries/<key>.md`
3. Create role files in `_resume/<key>/` with `resume_tag` and `i_order` front matter
4. Add the employer key to the tag list in `_pages/resume.md`

## Deployment

Pushes to `main` deploy automatically via GitHub Pages. No custom CI workflow — GitHub's built-in Jekyll build handles it.

## Generating a targeted resume PDF

To generate a two-page resume PDF tailored to a job description, read `.agents/skills/dump-targeted-pdf/core/workflow.md` and follow it end to end, parsing the user's request per its "Invocation & arguments" section. This platform has no subagent dispatch: perform the workflow's fact-check step inline as a separate discrete pass, quoting the source line for every claim.
