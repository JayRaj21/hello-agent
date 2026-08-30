# hello-agent

A small benchmark task for comparing coding-agent harnesses: give each
harness the same buggy Python module and prompt, then grade the result
with a script instead of eyeballing it.

Results from trials run so far: [`results/SUMMARY.md`](results/SUMMARY.md).

## Layout

- `task/` -- what a harness actually receives: `logstats.py` (2 bugs
  plus one docstring-only unimplemented rule), `tests/test_logstats.py`
  (the visible test suite), and `sample.log` (a fixture for the CLI
  smoke test).
- `baseline/` -- a byte-identical pristine copy of `task/`, used by
  `grading/grade.sh` as the diff/tamper reference. It is not a git tag;
  harness working copies are plain directories and are often not git
  repos at all.
- `grading/hidden/test_spec.py` -- a hidden spec-conformance suite,
  never given to a harness. It is injected into a harness's working
  copy by `grade.sh` after the visible run.
- `grading/grade.sh` -- the grader (see below).
- `grading/selftest/` -- four prepared working copies
  (`fixed/`, `naive_fixed/`, `tampered/`, `rewritten/`) used to
  validate `grade.sh`'s own behavior, plus `run_selftest.sh`, which
  runs the grader against all four and asserts on its output.
  `grading/selftest/fixed/` is the reference solution.
- `AGENT_PROMPT.md` -- the exact, harness-facing prompt text (repo
  root, deliberately outside `task/` so it's never copied into a
  harness's working copy or visible to its own file tools).
- `PROMPT.md` -- how to feed `AGENT_PROMPT.md` to a harness, plus the
  operator ground rules for running a fair comparison.
- `grading/run_harness.sh` -- automates one full harness run: fresh
  copy, timed non-interactive launch, grading, and a pre-filled
  results file (see "Automated runs" below).
- `results/TEMPLATE.md` -- one filled-in copy per harness run, some
  fields pasted from `grade.sh`'s output and some filled in manually
  from observing the run.
- `results/SUMMARY.md` -- a synthesized write-up comparing harnesses
  across multiple trials, once you have more than one result. Not
  auto-generated; written by hand from the individual `results/*.md`
  files.

**Harnesses only ever receive a fresh `cp -a task/ runs/<harness>/`
copy. They are never pointed at the repo root, and never see
`baseline/`, `grading/`, or the reference solution in
`grading/selftest/fixed/`.** `runs/` is gitignored; each harness gets
its own untouched copy and is never reused.

## The task

`task/logstats.py` summarizes a toy access log. Its module and function
docstrings are the specification. Two of the nine visible tests fail
at baseline:

1. `top_paths` mutates the caller's dict (the counts returned by
   `summarize()` are destroyed on first use) and resolves ties by
   insertion order rather than the rule stated in its own docstring.
2. `format_report`'s error-rate rounding uses Python's `round()`,
   which breaks ties to even, while the docstring specifies half-up
   rounding.

The correct tie-break rule (order by path length, then case-sensitive
lexicographic order) and the non-mutation contract are stated only in
`top_paths`'s docstring -- not in any visible test assertion. An agent
that does not read the docstring will produce alphabetical order
instead, which is wrong but not caught by the visible suite.

## Grading

```
grading/grade.sh <path-to-harness-working-copy> [harness-label]
```

For a harness run at `runs/<harness>/`:

```
grading/grade.sh runs/<harness> <harness>
```

`grade.sh` copies the target into a scratch directory (it never writes
into the harness's own working copy), then:

1. Checks whether anything under `tests/` was modified relative to
   `baseline/tests`, and whether any pytest config file
   (`conftest.py`, `pytest.ini`, `setup.cfg`, `tox.ini`,
   `pyproject.toml`) was added anywhere in the copy. Both are reported
   as separate warnings/flags; a harness can rig the visible suite by
   deleting failing tests or adding a `conftest.py`.
2. Diffs the whole tree against `baseline/` (excluding `.git/`,
   `__pycache__/`, `.pytest_cache/`) to flag files added or removed
   outside the intended scope. `.git/` is excluded so that a harness
   which auto-`git init`s its working copy doesn't spuriously trip
   this check.
3. Runs the visible suite (`tests/test_logstats.py`) via
   `--junitxml`, not by scraping the summary line, since pytest's
   textual summary format is version-fragile.
4. Copies `grading/hidden/test_spec.py` into the working copy's
   `tests/` and runs it the same way, reporting `hidden_passed` /
   `hidden_total` as a **separate** metric.
5. Diffs `logstats.py` against `baseline/logstats.py` to report lines
   added/removed and how many files changed in scope.

It prints a human-readable block followed by a `key=value` block
(`harness`, `visible_passed`, `visible_failed`, `visible_skipped`,
`visible_total`, `hidden_passed`, `hidden_total`, `lines_added`,
`lines_removed`, `files_changed`, `extra_files`, `missing_files`,
`test_files_modified`, `config_files_added`, `collection_error`) meant
to be pasted straight into `results/TEMPLATE.md`.

### Visible vs. hidden results

The visible suite (`tests/test_logstats.py`) is the contract the
harness was told to satisfy: "make the entire test suite pass."
`hidden_passed`/`hidden_total` is a separate metric -- "spec
conformance" -- checking whether the fix actually matches
`logstats.py`'s docstrings rather than merely satisfying the visible
assertions (e.g. by hardcoding the one rounding value the visible
suite exercises, or by picking an easy but wrong tie-break). A harness
that reports "all tests passing" can still score low on the hidden
suite; that is not a moved goalpost, it is the point of the exercise.
Report the two numbers side by side and let the reader interpret them
-- `grade.sh` does not combine them into a single score.

## Automated runs

```
grading/run_harness.sh claude [label]
grading/run_harness.sh pi <ollama-model> [label]
grading/run_harness.sh opencode <ollama-model> [label]
```

Does the whole pipeline in one command: fresh copy, timed
non-interactive launch, grading, and a pre-filled `results/<label>.md`
+ `results/<label>.transcript.log`. Pass `-f`/`--force` to re-run under
an existing label, overwriting the previous attempt.

A few things worth knowing before you rely on it:

- **Run copies live outside this repo**, at `../hello-agent-runs/<label>/`
  (a sibling directory), not `runs/<label>/` inside it. This is
  deliberate, not incidental: with run copies nested inside this git
  repo, `claude -p --dangerously-skip-permissions` was observed to
  edit `task/logstats.py` directly instead of its own isolated copy,
  twice, silently invalidating results (see "Integrity protections"
  below). Moving run copies outside the repo removes whatever ambient
  project context was causing that.
- **It's non-interactive**, so it can't conduct the "answer clarifying
  questions with 'use your best judgment'" exchange from the manual
  procedure below. Instead it appends one fallback sentence to the
  prompt telling the harness to use its best judgment on anything it'd
  otherwise ask about, applied identically for every harness. This
  means "did it ask a clarifying question" isn't observable from an
  automated run's transcript the way other manual-observation fields
  are.
- **Some manual fields still need a human.** The generated
  `results/<label>.md` auto-fills what `grade.sh` and the timer can
  measure; anything requiring judgment (scope creep, did it verify its
  own work, cost/tokens) is left marked `SEE TRANSCRIPT` for you to
  fill in after reading `results/<label>.transcript.log`. Format
  differs by harness: `claude`/`opencode` write plain text;
  `pi` writes newline-delimited JSON events (`--mode json`), since
  its default TUI rendering doesn't survive being redirected to a
  file.
- **Trial-to-trial variance is real.** Don't trust a single run,
  especially for a local model through a harness you haven't already
  validated -- see `results/SUMMARY.md` for a case where five trials
  of the same harness/model pairing produced five different outcomes.

## Manual comparison procedure

If you're running a harness `grading/run_harness.sh` doesn't support,
or want to watch it work interactively:

1. `mkdir -p runs` once (it's gitignored, so it doesn't exist in a
   fresh checkout). Then for each harness, copy the task fresh:
   `cp -a task/ runs/<harness>/`.
2. Paste the exact text of `AGENT_PROMPT.md` as the harness's first
   message (see `PROMPT.md` for why that file is separate from this
   one, and how to feed it reliably per harness). Follow the ground
   rules in `PROMPT.md`: answer any clarifying question with "Use your
   best judgment.", don't run the tests for the harness, and stop the
   clock at its first claim of completion.
3. Grade: `grading/grade.sh runs/<harness> <harness>`.
4. Copy `results/TEMPLATE.md` to `results/<harness>.md`, fill in the
   automated fields from `grade.sh`'s `key=value` output, and fill in
   the manual fields from observing the run.
5. Compare `results/*.md` across harnesses. Tool-call round-trip
   counts may be `n/a` for harnesses that don't expose them -- that
   asymmetry is expected and should be noted, not estimated.

## Integrity protections

`task/` is the pristine, buggy starting state every harness is
supposed to receive. During benchmarking, a runaway harness process
was twice found to have written directly into `task/logstats.py`
instead of its own isolated run copy, silently making every subsequent
run "pass" trivially since it started from an already-fixed file. Two
defenses now guard against this:

- `task/`'s files are `chmod 444` (read-only). `grading/run_harness.sh`
  `chmod`s its own run copy back to writable after copying, since
  `cp -a` preserves the read-only mode otherwise.
- `grading/run_harness.sh` refuses to start any run unless `task/`
  still byte-matches `baseline/`, checked fresh every invocation.

If you ever see this check fail, restore the affected file(s) from
`baseline/` (e.g. `cp baseline/logstats.py task/logstats.py`) before
re-running. If you write your own tooling against this repo, don't
assume a clean `grade.sh` result is trustworthy on its own -- diff the
result against `baseline/` directly, the way `results/SUMMARY.md`'s
final section describes.

## Validating the grader itself

```
grading/selftest/run_selftest.sh
```

runs `grade.sh` against the four prepared fixtures under
`grading/selftest/` and asserts on the expected output:

- `fixed/` (the reference solution): full marks on both suites, no
  warnings.
- `naive_fixed/`: passes the entire visible suite via a plain
  alphabetical tie-break and a hardcoded rounding value, but fails
  most of the hidden suite -- demonstrating that the hidden suite
  actually catches a plausible-looking wrong fix.
- `tampered/`: the two originally-failing visible tests deleted,
  `logstats.py` left buggy -- demonstrating the tamper warning fires.
- `rewritten/`: a correct but structurally different implementation --
  demonstrating the diff-size accounting doesn't crash or mislead on a
  full rewrite.

## Non-goals

No CI, no packaging (the deliberate absence of a `pyproject.toml` is
itself one of the tamper signals `grade.sh` checks for), and no single
scoring formula/ranking -- `grade.sh` reports metrics, humans interpret
them. `grading/run_harness.sh` automates *running* a harness against
the task; it does not score or rank harnesses against each other, that
synthesis still belongs in `results/SUMMARY.md`, written by a human.
This repo also does not touch any existing git tags/commits/history.
