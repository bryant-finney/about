---
name: dump-targeted-pdf
description: Generate a two-page job-targeted PDF resume from a job description. Use when the user wants a resume tailored to a specific role or JD. Takes the JD file path or URL (required), optionally a delivery directory, a filename label, and the word non-interactive (test harnesses only).
---

# dump-targeted-pdf

Invocation arguments: $ARGUMENTS

Read `core/workflow.md` (relative to this file) and follow it end to end, starting with its "Invocation & arguments" section to parse the arguments above. Platform note: this platform supports subagents — run the workflow's fact-check step (step 5) as a fresh-context subagent acting as an adversarial reviewer.
