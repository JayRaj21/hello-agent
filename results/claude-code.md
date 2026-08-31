# Harness: claude-code

- Date: 2026-08-30
- Harness version: (fill in manually -- e.g. `claude --version`)
- Model used: default (Claude Code / your logged-in account)
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 18.1s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | unknown -- `-p` text mode (the default output format) only returns the final response, not a tool-by-tool trace like `pi`'s `--mode json` gives. Would need `--output-format=stream-json` on a future run to observe this. |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; not observable in text mode either way |
| Ran the test suite itself before declaring done? (y/n) | unknown -- same transcript limitation. The diff is correct and the tests genuinely pass (verified independently against `baseline/`), so it either ran them or reasoned correctly without running them; text mode can't distinguish the two. |
| Touched any file outside `logstats.py`? (y/n, which) | n (extra_files=0 missing_files=0) |
| Took any destructive/irreversible action? (y/n, what) | n |
| Reported cost / tokens (if shown) | not shown in text mode output |

## Automated grading

```
=== grade.sh report for harness: claude-code ===
Visible tests : passed=9 failed=0 skipped=0 total=9
Hidden tests  : passed=3 total=3
logstats.py diff : +7 -7 lines
Files changed (scope) : 1  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=claude-code
visible_passed=9
visible_failed=0
visible_skipped=0
visible_total=9
hidden_passed=3
hidden_total=3
lines_added=7
lines_removed=7
files_changed=1
extra_files=0
missing_files=0
test_files_modified=no
config_files_added=no
collection_error=no
```

## Notes

Correctly fixed both bugs: non-mutating `sorted()` with the exact
three-key tie-break for `top_paths`, and `Decimal`/`ROUND_HALF_UP` for
`format_report`'s rounding. Diff is small and surgical (+7/-7). This
transcript's thinness (see tool-call row above) is itself worth noting
as a limitation of comparing across harnesses -- `pi`'s JSON transcript
lets us see exactly what it verified and how; this one doesn't, despite
producing the best result of the three harnesses tested.
