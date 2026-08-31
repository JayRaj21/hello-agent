# Harness: opencode-qwen3-2

- Date: 2026-08-30
- Harness version: (fill in manually -- e.g. `opencode --version`)
- Model used: qwen3:14b
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 169.8s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | 2 attempted, 0 succeeded: `Read logstats.py` (malformed args, `SchemaError`), then `Read /example.txt` (hallucinated, out-of-scope path) |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; transcript shows no attempt to ask one |
| Ran the test suite itself before declaring done? (y/n) | n -- never got past the initial failed read |
| Touched any file outside `logstats.py`? (y/n, which) | n in effect (extra_files=0 missing_files=0, no write ever happened), but it did *attempt* to read `/example.txt`, a path outside the working directory that has nothing to do with this task -- correctly auto-rejected by opencode's permission system (`external_directory` request denied) |
| Took any destructive/irreversible action? (y/n, what) | n -- the out-of-scope read attempt above was blocked before it could do anything, not something it actually accomplished |
| Reported cost / tokens (if shown) | not shown in the captured transcript output |

## Automated grading

```
=== grade.sh report for harness: opencode-qwen3-2 ===
Visible tests : passed=7 failed=2 skipped=0 total=9
Hidden tests  : passed=0 total=3
logstats.py diff : +0 -0 lines
Files changed (scope) : 0  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=opencode-qwen3-2
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

Never actually got started: the first tool call was malformed (missing
opencode's required `filePath` key), and rather than retrying with
correct arguments, it appears to have hallucinated an entirely
different, unrelated file path (`/example.txt`) to try instead --
which was outside the working directory and correctly auto-rejected.
Zero real work done. This is the same `filePath`-key `SchemaError` seen
with `llama3.1:8b` and `granite4:7b-a1b-h` in earlier smoke testing
(not `hello-agent`-task runs), suggesting it's a recurring fragility in
how opencode presents its tool schema to locally-hosted models, not
specific to this task or this model.
