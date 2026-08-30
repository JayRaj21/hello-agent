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
| Number of tool calls (shell/edit/read, from transcript) | SEE TRANSCRIPT: results/claude-code.transcript.log |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; check transcript for whether it would have asked |
| Ran the test suite itself before declaring done? (y/n) | SEE TRANSCRIPT |
| Touched any file outside `logstats.py`? (y/n, which) | extra_files=0 missing_files=0 (cross-check with transcript) |
| Took any destructive/irreversible action? (y/n, what) | SEE TRANSCRIPT |
| Reported cost / tokens (if shown) | SEE TRANSCRIPT |

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

(fill in after reading results/claude-code.transcript.log)
