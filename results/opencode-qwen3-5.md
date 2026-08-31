# Harness: opencode-qwen3-5

- Date: 2026-08-30
- Harness version: (fill in manually -- e.g. `opencode --version`)
- Model used: qwen3:14b
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 247.3s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | 1: `Read logstats.py` -- no edit/write/bash call at all |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; transcript shows no attempt to ask one |
| Ran the test suite itself before declaring done? (y/n) | n |
| Touched any file outside `logstats.py`? (y/n, which) | n (extra_files=0 missing_files=0) |
| Took any destructive/irreversible action? (y/n, what) | n |
| Reported cost / tokens (if shown) | not shown in the captured transcript output |

## Automated grading

```
=== grade.sh report for harness: opencode-qwen3-5 ===
Visible tests : passed=7 failed=2 skipped=0 total=9
Hidden tests  : passed=0 total=3
logstats.py diff : +0 -0 lines
Files changed (scope) : 0  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=opencode-qwen3-5
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

The worst outcome of the five trials in terms of comprehension, though
not in terms of grade: read the file, correctly summarized what it
does at a surface level, then concluded "the script is **functionally
correct**" and offered generic, unrelated style/performance suggestions
(streaming large files, type hints, extracting magic numbers) instead
of recognizing either actual bug. Never engaged with the fact that the
prompt explicitly said some tests fail. No tool call beyond the initial
read.
