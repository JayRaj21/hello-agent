# Harness: pi-qwen3-2

- Date: 2026-08-30
- Harness version: (fill in manually -- e.g. `pi --version`)
- Model used: qwen3:14b
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 194.6s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | 2: `read logstats.py`, `edit logstats.py` -- no `bash`/pytest call this time |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; transcript shows no attempt to ask one |
| Ran the test suite itself before declaring done? (y/n) | n -- declared "the test suite should now pass" on reasoning alone, no verification attempt at all (contrast with trial 1, which at least tried) |
| Touched any file outside `logstats.py`? (y/n, which) | n (extra_files=0 missing_files=0, confirmed by transcript: only `logstats.py` read/edited) |
| Took any destructive/irreversible action? (y/n, what) | n |
| Reported cost / tokens (if shown) | input=3304, output=298, total=3602 (local model, `cost.total=0` since Ollama is free/local) |

## Automated grading

```
=== grade.sh report for harness: pi-qwen3-2 ===
Visible tests : passed=8 failed=1 skipped=0 total=9
Hidden tests  : passed=2 total=3
logstats.py diff : +6 -5 lines
Files changed (scope) : 1  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=pi-qwen3-2
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

Same code outcome as trial 1 (`top_paths` fixed correctly,
`format_report` untouched), but arrived at it with less effort and no
self-verification: no bash/pytest call at all, just asserted success.
Notably, trial 1's verification attempt failed and it hedged
("should now be resolved... if you're encountering issues"), while
this trial stated success flatly and confidently despite having
verified nothing. Confident wording did not correlate with actual
correctness here.
