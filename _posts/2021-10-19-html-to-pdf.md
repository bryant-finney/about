---
layout: single
title: HTML to PDF
date: 2021-10-19
categories:
  - blog
  - tech
---

My goal for today was to add support for building PDF documents of my
[Resume](/about/resume/).

But getting Jekyll to play nicely with PDF generation was a bit more involved than I had
hoped. Here's what did and didn't work for me.

## Didn't Work

I started off using `pandoc` in a couple of different ways. First attempt was to
generate PDF documents from the built HTML files.

Getting `pandoc` required `LaTeX`, which I installed using
[`homebrew`](https://formulae.brew.sh/formula-linux/texlive):

```bash
brew install basictex
brew install texlive
brew install pandoc
```

Then, I tried running it on the HTML file built by `Jekyll`:

```bash
bundle exec jekyll b
pandoc -s --pdf-engine=xelatex _site/resume/index.html -o resume.pdf
```

The problem with this build was that it messed up the `masthead` / navbar header when
rendering the PDF.

I also tried using a live server, but it had the same problem:

```bash
pandoc -s --pdf-engine=xelatex http://127.0.0.1:4000/about/resume/index.html -o resume.pdf
```

## Worked

Rather than continuing down the `pandoc` route, I decided to try
[wkhtmltopdf](https://wkhtmltopdf.org/). I installed the pre-compiled binary from
[wkhtmltopdf/downloads](https://wkhtmltopdf.org/downloads.html) and generated the
document as follows:

```bash
wkhtmltopdf http://127.0.0.1:4000/about/resume/index.html --no-images resume.pdf
```

It was only after writing this that I realized how old `wkhtmltopdf` is. Next time, I'll
give [`weasyprint`](https://weasyprint.org/) a try.
