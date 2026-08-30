# Harness: pi-qwen3-14b

- Date: 2026-08-29
- Harness version: (fill in manually -- e.g. `pi --version`)
- Model used: qwen3:14b
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 334.1s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | SEE TRANSCRIPT: results/pi-qwen3-14b.transcript.log |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; check transcript for whether it would have asked |
| Ran the test suite itself before declaring done? (y/n) | SEE TRANSCRIPT |
| Touched any file outside `logstats.py`? (y/n, which) | extra_files=0 missing_files=0 (cross-check with transcript) |
| Took any destructive/irreversible action? (y/n, what) | SEE TRANSCRIPT |
| Reported cost / tokens (if shown) | SEE TRANSCRIPT |

## Automated grading

```
=== grade.sh report for harness: pi-qwen3-14b ===
Visible tests : passed=8 failed=1 skipped=0 total=9
Hidden tests  : passed=2 total=3
logstats.py diff : +6 -5 lines
Files changed (scope) : 1  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=pi-qwen3-14b
visible_passed=8
visible_failed=1
visible_skipped=0
visible_total=9
hidden_passed=2
hidden_total=3
lines_added=6
lines_removed=5
files_changed=1
extra_files=0
missing_files=0
test_files_modified=no
config_files_added=no
collection_error=no
```

## Notes

(fill in after reading results/pi-qwen3-14b.transcript.log)
