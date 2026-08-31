# Harness: pi-granite4

- Date: 2026-08-30
- Harness version: (fill in manually -- e.g. `pi --version`)
- Model used: granite4:7b-a1b-h
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 9.0s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | 1: `read logstats.py` -- no edit/write/bash call at all |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; transcript shows no attempt to ask one |
| Ran the test suite itself before declaring done? (y/n) | n |
| Touched any file outside `logstats.py`? (y/n, which) | n (extra_files=0 missing_files=0) |
| Took any destructive/irreversible action? (y/n, what) | n |
| Reported cost / tokens (if shown) | not captured in this transcript's final `message_end` event |

## Automated grading

```
=== grade.sh report for harness: pi-granite4 ===
Visible tests : passed=7 failed=2 skipped=0 total=9
Hidden tests  : passed=0 total=3
logstats.py diff : +0 -0 lines
Files changed (scope) : 0  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=pi-granite4
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

The most severe failure of any local model tested. It correctly `read`
the real `logstats.py`, then produced a confident, detailed description
of a *completely different, imaginary* program: mentions `parse_params`,
`accesses` dict keys built from `LOGNAME`, `os.listdir`, `create_directory`,
`move_file`, `sys.path`/`LOG_FORMAT` -- none of which exist anywhere in
`logstats.py`. This isn't an incomplete summary (like `devstral`'s) or
garbled output (like `llama3.1:8b`'s) -- it's fluent, well-formatted,
entirely fabricated content presented as if it were a real analysis of
the file it had just read. Fastest run of any trial (9.0s), consistent
with it never actually engaging with the real content at all.
