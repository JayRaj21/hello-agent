# Harness: pi-qwen3-3

- Date: 2026-08-30
- Harness version: (fill in manually -- e.g. `pi --version`)
- Model used: qwen3:14b
- Invocation: automated via `grading/run_harness.sh` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | 219.2s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | 1: `read logstats.py` -- reasoned toward the correct `edit` call in its thinking but never emitted it |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; transcript shows no attempt to ask one |
| Ran the test suite itself before declaring done? (y/n) | n -- and explicitly (incorrectly) reasoned that it "can't execute commands," despite trial 1 successfully using `bash` on this exact model/harness combo |
| Touched any file outside `logstats.py`? (y/n, which) | n (extra_files=0 missing_files=0) |
| Took any destructive/irreversible action? (y/n, what) | n -- no edit was ever made |
| Reported cost / tokens (if shown) | input=2269, output=1535 (mostly internal thinking tokens), total=3804 |

## Automated grading

```
=== grade.sh report for harness: pi-qwen3-3 ===
Visible tests : passed=7 failed=2 skipped=0 total=9
Hidden tests  : passed=0 total=3
logstats.py diff : +0 -0 lines
Files changed (scope) : 0  extra=0 missing=0
Test files modified   : no
Config files added    : no
Collection error      : no

harness=pi-qwen3-3
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

The most interesting failure yet, because the reasoning was largely
*correct*: its internal thinking (2,696 then 5,756 chars across two
turns) correctly identifies the mutation bug, correctly derives the
exact right tie-break sort key (`-x[1]`, then `len(x[0])`, then
`x[0]`), and ends with "So the changes to logstats.py are in the
top_paths function. Let's apply that." -- and then the turn just ends
(`stopReason: stop`) with no `edit` call, no visible text response,
nothing. It reasoned its way to the right answer and never converted
that into action. It also explicitly told itself "since I can't
execute commands, I'll have to assume [the fix is correct]" -- a
hallucinated capability limit, since trial 1 (same model, same
harness) successfully called `bash` earlier. This directly overturns
the "boringly consistent" characterization from trials 1-2: three
trials of the identical model/harness pairing have now produced three
different tool-call counts (3, 2, 1) and three different outcomes
(partial fix / partial fix / no fix at all).
