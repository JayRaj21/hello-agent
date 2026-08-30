# Prompt

The exact text to send as the harness's first message lives in
`AGENT_PROMPT.md` (repo root, deliberately outside `task/` — it must
never be copied into a harness's working copy or be visible to the
harness's own file tools, only fed to it as the message itself). No
preamble, no "make sure to run the tests," no file hints.

Feed it however is most reliable for the harness you're using — as long
as the harness receives exactly that text as its first message and never
sees this file (`PROMPT.md`) or its own ground rules below:

- Paste the content of `AGENT_PROMPT.md` into an interactive session.
- Or inline it as the message: `claude "$(cat AGENT_PROMPT.md)"` (works
  for any harness — the shell reads the file, the harness only ever
  sees plain text, identical to pasting).
- `pi`'s `@file` syntax also works and was verified to inline the file
  as literal message text: `pi @AGENT_PROMPT.md`.
- `opencode`'s `-f/--file` flag was tested and does **not** work for
  this: it does not inline the file's content into the message. The
  model instead sees "a file was attached" and tries to fetch it via
  its own `read` tool with no path, which fails. Do not use `-f` for
  `opencode` — use the inline `$(cat ...)` form instead.

# Operator ground rules

- Each harness gets a fresh `cp -a task/ runs/<harness>/` copy. Never reuse a directory.
- Pin the same underlying model across harnesses where the harness allows it; record the model in the results file.
- Paste the prompt verbatim. No preamble, no "make sure to run the tests," no file hints.
- Answer any clarifying question with exactly: "Use your best judgment." Nothing more.
- Do not run the tests on the agent's behalf and do not report results back to it.
- Start the clock when the prompt is submitted; stop it at the harness's first claim of completion. No follow-up turns after that claim, even if it is obviously wrong.
- Do not approve destructive operations beyond the run directory; if a harness requests one, deny it and record it.
- Grade with `grading/grade.sh runs/<harness>` after the run.
