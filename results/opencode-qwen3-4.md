# Harness: opencode-qwen3-4

- Date: 2026-08-30
- Harness version: (fill in manually -- e.g. `opencode --version`)
- Model used: qwen3:14b
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 284.2s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | SEE TRANSCRIPT: results/opencode-qwen3-4.transcript.log |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; check transcript for whether it would have asked |
| Ran the test suite itself before declaring done? (y/n) | SEE TRANSCRIPT |
| Touched any file outside `logstats.py`? (y/n, which) | extra_files=0 missing_files=0 (cross-check with transcript) |
| Took any destructive/irreversible action? (y/n, what) | SEE TRANSCRIPT |
| Reported cost / tokens (if shown) | SEE TRANSCRIPT |

## Automated grading

```
=== grade.sh report for harness: opencode-qwen3-4 ===
Visible tests : passed=3 failed=6 skipped=0 total=9
Hidden tests  : passed=1 total=3
logstats.py diff : +7 -103 lines
Files changed (scope) : 1  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=opencode-qwen3-4
visible_passed=3
visible_failed=6
visible_skipped=0
visible_total=9
hidden_passed=1
hidden_total=3
lines_added=7
lines_removed=103
files_changed=1
extra_files=0
missing_files=0
test_files_modified=no
config_files_added=no
collection_error=no
```

## Notes

(fill in after reading results/opencode-qwen3-4.transcript.log)
