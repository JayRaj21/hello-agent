# Harness: pi-llama31

- Date: 2026-08-30
- Harness version: (fill in manually -- e.g. `pi --version`)
- Model used: llama3.1:8b
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 19.6s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | 2: `edit logstats.py` (failed -- see below), then `read logstats.py` (succeeded) |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; transcript shows no attempt to ask one |
| Ran the test suite itself before declaring done? (y/n) | n |
| Touched any file outside `logstats.py`? (y/n, which) | n (extra_files=0 missing_files=0) |
| Took any destructive/irreversible action? (y/n, what) | n -- the only write attempt failed before touching the file |
| Reported cost / tokens (if shown) | not captured in this transcript's final `message_end` event |

## Automated grading

```
=== grade.sh report for harness: pi-llama31 ===
Visible tests : passed=7 failed=2 skipped=0 total=9
Hidden tests  : passed=0 total=3
logstats.py diff : +0 -0 lines
Files changed (scope) : 0  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=pi-llama31
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

A genuine model breakdown, not just laziness. Its first `edit` call
copied `pi`'s tool-usage placeholder text literally into the
arguments -- `oldText: "<unique code snippet from logstats.py>"`,
`newText: "<add code that makes test suite pass, do not add any code
as per the edit function's doc."` -- instead of real code, so it
failed immediately ("Could not find edits[0]... oldText must match
exactly"). It then correctly `read` the real file content. Its final
response after that, however, degenerated into incoherent garbled text
mixing broken Python syntax with random Unicode symbols (♥, ⚛, ⚡-style
characters embedded mid-code) -- not a coherent second attempt, not an
error message, just noise. Fastest run of any local-model trial
(19.6s), which in retrospect reads as a red flag rather than
efficiency: it never engaged with the actual problem.
