# Harness: claude-code-2

- Date: 2026-08-30
- Harness version: (fill in manually -- e.g. `claude --version`)
- Model used: default (Claude Code / your logged-in account)
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 25.9s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | unknown -- `-p` text mode only returns the final response, not a tool-by-tool trace (see `claude-code.md` trial 1 for the same limitation) |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; not observable in text mode either way |
| Ran the test suite itself before declaring done? (y/n) | unknown -- same transcript limitation; result is independently verified correct regardless |
| Touched any file outside `logstats.py`? (y/n, which) | n (extra_files=0 missing_files=0) |
| Took any destructive/irreversible action? (y/n, what) | n |
| Reported cost / tokens (if shown) | not shown in text mode output |

## Automated grading

```
=== grade.sh report for harness: claude-code-2 ===
Visible tests : passed=9 failed=0 skipped=0 total=9
Hidden tests  : passed=3 total=3
logstats.py diff : +6 -6 lines
Files changed (scope) : 1  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=claude-code-2
visible_passed=9
visible_failed=0
visible_skipped=0
visible_total=9
hidden_passed=3
hidden_total=3
lines_added=6
lines_removed=6
files_changed=1
extra_files=0
missing_files=0
test_files_modified=no
config_files_added=no
collection_error=no
```

## Notes

Same correct outcome as trial 1: non-mutating `sorted()` tie-break for
`top_paths`, `Decimal`/`ROUND_HALF_UP` for `format_report`. Slightly
different variable naming/style from trial 1 but functionally
identical fix. Second consecutive clean, complete result.
