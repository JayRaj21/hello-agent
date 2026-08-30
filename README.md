# hello-agent

Give different AI coding-agent harnesses (Claude Code, `pi`, `opencode`, ...)
the exact same small buggy task, then grade the result with a script instead
of eyeballing it.

📊 **Results so far:** [`results/SUMMARY.md`](results/SUMMARY.md)

## Quickstart

```bash
grading/run_harness.sh claude
grading/run_harness.sh pi <ollama-model>
grading/run_harness.sh opencode <ollama-model>
```

Each command copies the task fresh, runs the harness on it, grades the
result, and writes `results/<label>.md` + a full transcript. That's the
whole workflow — see [Automated runs](#automated-runs) for details.

## The task

`task/logstats.py` summarizes a toy access log. The docstrings are the
spec. Two of the nine tests fail out of the box:

1. **`top_paths` mutates its input** — calling it twice on the same data
   silently breaks. It also doesn't implement the tie-break rule its own
   docstring describes (order by path length, then case-sensitive
   lexicographic order).
2. **`format_report` rounds wrong** — it uses Python's `round()`, which
   rounds ties to even, but the spec calls for half-up rounding.

The tie-break rule only appears in the docstring, not in any test
assertion — an agent that skips it will produce plain alphabetical order,
which looks reasonable but is wrong.

## Automated runs

```bash
grading/run_harness.sh claude [label]
grading/run_harness.sh pi <ollama-model> [label]
grading/run_harness.sh opencode <ollama-model> [label]
```

Add `-f`/`--force` to re-run an existing label and overwrite its result.

**Good to know:**

- Run copies live at `../hello-agent-runs/<label>/`, a sibling directory
  *outside* this repo — not inside it. That's deliberate; see
  [Integrity protections](#integrity-protections).
- It's non-interactive, so it can't ask you a clarifying question mid-run.
  Instead, the prompt tells the harness to use its own best judgment on
  anything it'd otherwise ask about. That means you can't observe whether
  a harness *would have* asked something.
- The generated `results/<label>.md` auto-fills what can be measured
  automatically (pass/fail counts, diff size, timing). Anything that
  needs a human judgment call is left marked `SEE TRANSCRIPT` for you to
  fill in by reading `results/<label>.transcript.log`.
- **Run more than once before trusting a result.** `results/SUMMARY.md`
  has a real example of the same harness/model producing five different
  outcomes across five trials.

## Grading

```bash
grading/grade.sh <path-to-harness-working-copy> [label]
```

Copies the target into a scratch directory (never touches the original),
then checks, in order:

1. **Tampering** — was anything under `tests/` modified, or was a pytest
   config file (`conftest.py`, `pytest.ini`, ...) added anywhere?
2. **Scope** — were files added or removed outside `logstats.py`?
3. **Visible tests** — runs `tests/test_logstats.py` via `--junitxml`
   (not by scraping pytest's text summary, which is version-fragile).
4. **Hidden tests** — injects `grading/hidden/test_spec.py`, a suite the
   harness never saw, and runs it the same way. Reported as a *separate*
   number, `hidden_passed`/`hidden_total`.
5. **Diff size** — lines added/removed vs. `baseline/logstats.py`.

It prints a human-readable summary, then a `key=value` block meant to be
pasted into `results/TEMPLATE.md`.

### Why two pass counts?

The **visible** suite is the stated contract: "make the tests pass."
The **hidden** suite checks something stricter — does the fix actually
match the docstrings, or does it just satisfy the visible assertions by
coincidence (e.g. hardcoding the one rounding value that's actually
tested, or picking a plausible-but-wrong tie-break)?

A harness can report "all tests passing" and still score low on hidden
tests. That's the point of the exercise, not a moved goalpost. The two
numbers are reported side by side — `grade.sh` never combines them into
one score.

## Layout

| Path | What it is |
|---|---|
| `task/` | What a harness actually receives — `logstats.py`, its tests, a log fixture |
| `baseline/` | Untouched copy of `task/`, used as the diff/tamper reference |
| `AGENT_PROMPT.md` | The exact text to give a harness (outside `task/` on purpose) |
| `PROMPT.md` | How to deliver that prompt, plus ground rules for a fair run |
| `grading/grade.sh` | The grader |
| `grading/run_harness.sh` | Automates a full run: copy → launch → grade → results file |
| `grading/hidden/test_spec.py` | Hidden spec-conformance tests, never shown to a harness |
| `grading/selftest/` | Fixtures that prove the grader itself works (see below) |
| `results/TEMPLATE.md` | Blank template for one harness's result |
| `results/SUMMARY.md` | Hand-written synthesis across all trials |

**Harnesses only ever see a fresh copy of `task/`.** Never the repo root,
never `baseline/`, `grading/`, or the reference solution in
`grading/selftest/fixed/`.

## Manual runs

Prefer this if you're using a harness `run_harness.sh` doesn't support,
or want to watch it work interactively.

1. `mkdir -p runs` (gitignored, so it won't exist in a fresh checkout),
   then `cp -a task/ runs/<harness>/`.
2. Give the harness the exact text of `AGENT_PROMPT.md` as its first
   message. See `PROMPT.md` for delivery tips and ground rules
   (answer clarifying questions with "use your best judgment," don't run
   the tests for it, stop the clock at its first claim of completion).
3. `grading/grade.sh runs/<harness> <harness>`
4. Copy `results/TEMPLATE.md` → `results/<harness>.md`, paste in the
   automated output, fill in what you observed.

## Integrity protections

Mid-benchmark, a runaway harness process was twice found writing
directly into `task/logstats.py` instead of its own isolated copy —
silently making every later run "pass" for free, since it started from
an already-fixed file. Two defenses now prevent this:

- `task/`'s files are `chmod 444` (read-only).
- `run_harness.sh` refuses to start unless `task/` still exactly matches
  `baseline/`.

If that check ever fails, restore from `baseline/`:
```bash
cp baseline/logstats.py task/logstats.py
```

**Don't fully trust a clean `grade.sh` result either** — diff it against
`baseline/` directly before believing it. `results/SUMMARY.md` explains
why in more detail.

## Validating the grader itself

```bash
grading/selftest/run_selftest.sh
```

Runs `grade.sh` against four known fixtures and checks the output makes
sense:

- **`fixed/`** — the real solution → full marks, no warnings.
- **`naive_fixed/`** — passes all visible tests via a plausible-looking
  but wrong tie-break and a hardcoded rounding value → fails most hidden
  tests, proving the hidden suite actually catches this.
- **`tampered/`** — the two failing tests deleted → tamper warning fires.
- **`rewritten/`** — a correct but totally different implementation →
  diff accounting doesn't crash or mislead on a full rewrite.

## Non-goals

No CI, no packaging (a missing `pyproject.toml` is itself a tamper
signal `grade.sh` checks for), no single scoring formula. `grade.sh`
reports metrics; `run_harness.sh` runs a harness against the task;
humans do the ranking, by hand, in `results/SUMMARY.md`.
