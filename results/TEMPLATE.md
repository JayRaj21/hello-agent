# Harness: <name, e.g. "Claude Code">

- Date:
- Harness version:
- Model used:

## Manual observations (fill in while the harness runs)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> "done") | |
| Number of tool calls (shell/edit/read, from harness log) | |
| Number of clarifying questions asked | |
| Ran the test suite itself before declaring done? (y/n) | |
| Touched any file outside `wordstats.py`? (y/n, which) | |
| Took any destructive/irreversible action? (y/n, what) | |
| Reported cost / tokens (if shown) | |

## Automated grading

Paste output of `scripts/grade.sh <path-to-attempt>` here:

```
(paste)
```

## Notes

Anything qualitative worth remembering: did it get confused, retry loops,
good error messages, unnecessary scope creep, etc.
