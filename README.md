# hello-agent

A minimal, repeatable benchmark for comparing agent harnesses (Claude Code,
Codex, opencode, pi, ...) on the same task, with objective metrics instead of
impressions.

## What it tests

`task/wordstats.py` is a small CLI with two real bugs and one missing
feature, verified against `task/tests/test_wordstats.py` (6 tests, 3 fail on
the unmodified baseline). It's small enough to read in under a minute, but
requires:

- running a test suite and reading failure output (not just skimming code)
- fixing a subtle bug (integer division truncating an average)
- implementing a small missing function to spec (`--top N`, with a tie-break
  rule stated only in the docstring, not in the failing tests' obvious
  surface)
- not touching the test file (temptation: some harnesses "fix" the test
  instead of the bug)

This surfaces real differences: does the harness verify its own work before
declaring done, does it stay in scope, how many tool round-trips does it
take, does it silently guess at the tie-break rule or ask.

## Directory layout

- `task/` — the exact starting state to hand to every harness (the "input").
  Copy this directory fresh for each harness run; never let one harness's
  edits leak into another's starting point.
- `TASK.md` — the exact prompt to paste into each harness, plus rules for a
  fair comparison.
- `scripts/grade.sh` — objective grading: runs the test suite against a
  harness's resulting `wordstats.py` and reports pass/fail count and diff
  size (the "output" side of the comparison).
- `results/TEMPLATE.md` — copy to `results/<harness-name>.md` per run; mixes
  the automated grade with a few manually-observed metrics the harness log
  gives you (time, tool-call count, clarifying questions, scope creep).

## Running a comparison

For each harness (Claude Code, Codex, opencode, pi, ...):

1. Copy `task/` to a fresh scratch directory.
2. Start a new session of the harness rooted at that copy.
3. Paste the prompt from `TASK.md` verbatim. Start a timer.
4. Let it run to completion; stop the timer when it reports done.
5. Run `scripts/grade.sh <scratch-dir>` and record the output.
6. Fill in `results/<harness>.md` from `results/TEMPLATE.md` with the timing,
   tool-call count, and grading output.

Once you have a `results/*.md` per harness, the numbers are directly
comparable: correctness (tests passed), precision (diff size — smaller
focused diffs are better than sprawling rewrites), and efficiency (time,
tool calls). No two harnesses need to produce the same diff — only the same
test results — so this rewards correctness and judgment, not mimicry.
