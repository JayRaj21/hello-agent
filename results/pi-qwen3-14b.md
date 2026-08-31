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
| Number of tool calls (shell/edit/read, from transcript) | 3: `read logstats.py`, `edit logstats.py`, `bash "cd tests && python -m pytest"` |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; transcript shows no attempt to ask one |
| Ran the test suite itself before declaring done? (y/n) | y (attempted) -- but the `python -m pytest` call appears to have failed (likely `python` not on PATH, only `python3`); final message says "the test environment may not have Python installed" and suggests the *user* debug it, rather than retrying with `python3` itself |
| Touched any file outside `logstats.py`? (y/n, which) | n (extra_files=0 missing_files=0, confirmed by transcript: only `logstats.py` read/edited) |
| Took any destructive/irreversible action? (y/n, what) | n |
| Reported cost / tokens (if shown) | input=4009, output=1085, total=5094 (local model, `cost.total=0` since Ollama is free/local) |

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

Fixed `top_paths` correctly (non-mutating, exact tie-break sort key)
but never touched `format_report` at all -- the rounding bug is
entirely unaddressed, matching the hidden-suite shortfall exactly.

Attempted to verify its own work by running pytest via `bash`, which is
good discipline, but the command appears to have failed on an
environment issue (`python` vs `python3`) and it did not retry or
investigate -- it told the user to go check instead. Its final message
never mentions `format_report` or the rounding bug at all, consistent
with the diff: it seems to have genuinely stopped after fixing
`top_paths`, not realized there was a second failing test.
