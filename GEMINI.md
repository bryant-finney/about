# GEMINI.md

This file provides guidance to Gemini CLI when working in this repository. Build/architecture context: see `AGENTS.md`.

## Generating a targeted resume PDF

To generate a two-page resume PDF tailored to a job description, read `.agents/skills/dump-targeted-pdf/core/workflow.md` and follow it end to end, parsing the user's request per its "Invocation & arguments" section. This platform has no subagent dispatch: perform the workflow's fact-check step inline as a separate discrete pass, quoting the source line for every claim.
