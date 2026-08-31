# Harness: pi-devstral

- Date: 2026-08-30
- Harness version: (fill in manually -- e.g. `pi --version`)
- Model used: devstral:24b
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 107.4s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | 1: `read logstats.py` -- no edit/write/bash call at all |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; transcript shows no attempt to ask one |
| Ran the test suite itself before declaring done? (y/n) | n |
| Touched any file outside `logstats.py`? (y/n, which) | n (extra_files=0 missing_files=0) |
| Took any destructive/irreversible action? (y/n, what) | n |
| Reported cost / tokens (if shown) | not captured in this transcript's final `message_end` event |

## Automated grading

```
=== grade.sh report for harness: pi-devstral ===
Visible tests : passed=7 failed=2 skipped=0 total=9
Hidden tests  : passed=0 total=3
logstats.py diff : +0 -0 lines
Files changed (scope) : 0  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=pi-devstral
visible_passed=7
visible_failed=2
visible_skipped=0
visible_total=9
hidden_passed=0
hidden_total=3
lines_added=0
lines_removed=0
files_changed=0
extra_files=0
missing_files=0
test_files_modified=no
config_files_added=no
collection_error=no
```

## Notes

Read the file once and gave a generic code-summary explanation instead
of fixing anything -- same "explained instead of acted" failure shape
seen with `opencode`+`qwen3:14b` trial 3, but through `pi` this time,
so it's not purely an `opencode`-schema issue; some models/harnesses
just don't reliably distinguish "explain this" from "fix this" even
when the prompt explicitly says to make the tests pass. Worth noting
its comprehension was also incomplete: its own summary of `top_paths`
says only "orders paths first by count, then by path length if counts
are equal" -- it omits the tie-break's lexicographic-order clause
entirely and never mentions the mutation bug or the rounding bug at
all. This is the first local model tested where `pi` (previously 4/4
reliable across `qwen3:14b` and this) produced a fully inert run.
