# hello-agent: harness comparison summary

Covers all trials run to date via `grading/run_harness.sh`. Each row
below is independently verified: its resulting `logstats.py` was diffed
directly against `baseline/logstats.py`, not inferred from the
harness's own transcript claim. See "A note on trust" at the bottom
before reading anything here as settled fact.

## Results by harness

### Claude Code (default model)

| Trial | Visible (9) | Hidden (3) | Diff | Time |
|---|---|---|---|---|
| 1 (`claude-code`) | 9/9 | 3/3 | +7/-7 | 18.1s |
| 2 (`claude-code-2`) | 9/9 | 3/3 | +6/-6 | 25.9s |
| 3 (`claude-code-3`) | 9/9 | 3/3 | +7/-7 | 33.5s |

**Behavior:** solved the task correctly and completely all three
times, with a small, surgical diff. Used `Decimal`/`ROUND_HALF_UP` for
the rounding bug and a non-mutating `sorted()` with the exact
three-key tie-break (count desc, length asc, lexicographic) for
`top_paths`, matching the docstring precisely every trial. By far the
fastest and most consistent of any harness/model pairing tested.

### `pi` + `qwen3:14b` (local, via Ollama)

| Trial | Visible (9) | Hidden (3) | Diff | Time | Tool calls |
|---|---|---|---|---|---|
| 1 (`pi-qwen3-14b`) | 8/9 | 2/3 | +6/-5 | 334.1s | 3: read, edit, bash (pytest attempt failed, gave up) |
| 2 (`pi-qwen3-2`) | 8/9 | 2/3 | +6/-5 | 194.6s | 2: read, edit (no verification attempted) |
| 3 (`pi-qwen3-3`) | 7/9 | 0/3 | +0/-0 | 219.2s | 1: read only -- reasoned to the *correct* fix internally, then the turn ended before it ever called `edit` |

**Behavior:** not the stable pattern it looked like after two trials.
Trials 1-2 landed on an identical partial fix (`top_paths` correct,
`format_report` untouched). Trial 3 broke that pattern entirely --
its internal reasoning independently derived the same correct
`top_paths` fix as the other two trials, including the exact right
sort key, but the turn ended before it ever emitted the `edit` call,
so nothing was actually written. It also explicitly reasoned that it
"can't execute commands," a hallucinated limitation contradicted by
trial 1 successfully using `bash` on this exact model/harness pairing.
Three trials, three different tool-call counts (3, 2, 1) and three
different outcomes. The genuinely reproducible fact across all three
is narrower than first thought: when it does act, it never gets
`format_report` right -- but *whether* it acts at all isn't
reliable.

### `opencode` + `qwen3:14b` (local, via Ollama)

| Trial | Visible (9) | Hidden (3) | Diff | Time | Behavior |
|---|---|---|---|---|---|
| 1 (`opencode-qwen3`) | 4/9 | 3/3 | +11/-94 | 333.1s | Destructive rewrite: deleted `parse_line`/`summarize`/`main`/module docstring, kept only the two target functions -- both fixed correctly, most of the file gone |
| 2 (`opencode-qwen3-2`) | 7/9 | 0/3 | +0/-0 | 169.8s | Malformed tool call (`read` missing required `filePath` key) -> hallucinated an out-of-scope path (`/example.txt`) -> auto-rejected -> gave up, zero work |
| 3 (`opencode-qwen3-3`) | 7/9 | 0/3 | +0/-0 | 485.9s | Correctly diagnosed both the mutation bug and the exact right tie-break sort key in prose -- but never called an edit tool, just explained the fix and stopped |
| 4 (`opencode-qwen3-4`) | 3/9 | 1/3 | +7/-103 | 284.2s | Even more destructive rewrite than trial 1; worse outcome |
| 5 (`opencode-qwen3-5`) | 7/9 | 0/3 | +0/-0 | 247.3s | Missed both bugs entirely; concluded the code was "functionally correct" and offered unrelated style/performance suggestions instead |

**Behavior:** five trials, five qualitatively different outcomes.
**Zero of five** produced a clean, complete, non-destructive fix. No
describable "typical" behavior for this harness/model pairing --
it ranges from correct-but-destructive to complete task
misunderstanding, with no consistent failure mode.

### `pi` + other local models (single trial each)

Earlier smoke testing confirmed `devstral:24b`, `llama3.1:8b`, and
`granite4:7b-a1b-h` can all call tools correctly on a trivial one-shot
task. None of them could actually do this one.

| Model | Visible (9) | Hidden (3) | Diff | Time | Behavior |
|---|---|---|---|---|---|
| `devstral:24b` | 7/9 | 0/3 | +0/-0 | 107.4s | Read the file, gave a generic (and incomplete -- omits the tie-break clause and both bugs) code summary instead of fixing anything |
| `llama3.1:8b` | 7/9 | 0/3 | +0/-0 | 19.6s | Copied `pi`'s tool-usage placeholder text (`<add code that makes test suite pass...>`) literally into its first `edit` call, which failed; then, after correctly reading the real file, degenerated into incoherent garbled text mixing broken syntax and random Unicode symbols |
| `granite4:7b-a1b-h` | 7/9 | 0/3 | +0/-0 | 9.0s | Read the real file, then fabricated a fluent, confident description of a *completely different, imaginary* program (invented functions like `parse_params`, `create_directory`, `move_file` that don't exist anywhere in `logstats.py`) |

**Behavior:** all three failed to do any real work, but in three
distinct ways -- incomplete-but-genuine summary, tool-call
misunderstanding cascading into incoherence, and outright fabrication.
None resembles `pi` + `qwen3:14b`'s partial-fix pattern from trials 1-2
-- that pattern needs a model capable enough to attempt the task at
all, which these three didn't manage even once. `qwen3:14b` remains
the only local model that has done *any* real work on this task
through any harness tested so far. (Single trial each -- see caveats.)

## Cross-cutting conclusions

- **Claude Code is the clear leader** on every axis measured here:
  correctness (3/3 trials perfect), diff precision, and speed (speed
  comparison is not fully apples-to-apples -- see caveats). It's also
  the only harness/model pairing tested so far with zero variance
  across trials.
- **Same local model, unreliable under both harnesses tested, just in
  different ways.** `qwen3:14b` under `opencode` is chaotic (five
  different outcomes in five tries). Under `pi` it looked stable after
  two trials (identical partial fix twice) but a third trial broke
  that: same correct reasoning internally, zero actual edits made. The
  harness materially shapes *how* the model fails, but neither harness
  tested reduces `qwen3:14b` to a single predictable failure mode.
- **`pi`'s trials show whether it acts is not reliable, even when its
  reasoning is.** Its per-trial transcripts (only possible to inspect
  for `pi`, since its `--mode json` output gives a tool-by-tool trace
  that `claude -p` text mode doesn't) show three different relationships
  between reasoning and action: trial 1 acted and tried to self-verify
  (`bash "cd tests && python -m pytest"`, which failed on a
  `python`-vs-`python3` environment issue, then gave up rather than
  retrying); trial 2 acted with no verification attempt at all, stated
  success confidently; trial 3 reasoned its way to the *same correct
  fix* as the other two trials, in detail, and then never emitted the
  `edit` call -- the turn simply ended. Confidence of wording, and even
  correctness of internal reasoning, did not reliably predict whether
  real work got done.
- **`opencode`'s tool-call schema is a recurring failure surface.**
  The `filePath`-key `SchemaError` seen in trial 2 here also appeared
  with `llama3.1:8b` and `granite4:7b-a1b-h` in earlier smoke testing
  (see prior conversation) -- this is not a `qwen3:14b`-specific
  problem, it looks like a general fragility in how `opencode`'s tool
  schema is presented to locally-hosted models.

## Not yet covered

- **Codex is untested.** Not installed on the machine these trials ran
  on, and running it needs either an OpenAI API key or an interactive
  `codex login` flow that only a human can complete. `grading/run_harness.sh`
  has no `codex` branch yet. If you set it up, adding one follows the
  same pattern as the existing `claude`/`pi`/`opencode` branches.
- **`devstral`/`llama3.1`/`granite4` have only one trial each, all
  through `pi`.** See "`pi` + other local models" above -- all three
  failed to do real work in their one trial. That's a real result, not
  a placeholder, but N=1 each means it's not yet known whether that's
  their stable behavior or one bad roll. None has been tried through
  `opencode` at all.

## Caveats

- **Sample sizes are still small.** 3 trials for Claude Code, 3 for
  `pi` + `qwen3:14b`, 5 for `opencode` + `qwen3:14b`, 1 each for
  `devstral`, `llama3.1:8b`, and `granite4:7b-a1b-h` via `pi`. Even 3
  trials wasn't enough to safely call `pi` + `qwen3:14b` "consistent"
  -- its third trial broke a pattern that 2 trials made look stable
  (see above). Treat every number in this document, including the
  Claude Code row, as provisional; the one-trial rows are the least
  trustworthy of all -- "this happened once," not "this is what always
  happens."
- **Timing is not a fair cross-harness comparison.** Both local-model
  runs showed ~33%/67% GPU/CPU split (8GB VRAM insufficient to hold
  `qwen3:14b` fully), so their ~3-8 minute times mostly reflect this
  machine's hardware limits, not `pi`/`opencode` overhead. Claude
  Code's 18-26s is a hosted-model call with no local inference cost at
  all. Don't read the time column as "harness X is N times faster
  than harness Y."
- **Non-interactive runs can't observe clarifying questions.** All
  automated runs append a "use your best judgment" instruction instead
  of allowing an interactive back-and-forth (see `grading/run_harness.sh`'s
  header comment), so "did it ask a clarifying question" isn't
  observable from this data.
- **Claude Code's transcript is thin.** `-p` text mode returns only
  the final response, not a tool-by-tool trace like `pi`'s `--mode
  json` output -- so "did it run the tests itself before declaring
  done" can't be confirmed from the Claude Code transcripts the way it
  can for `pi`/`opencode`.

## A note on trust

Earlier in this benchmarking process, `task/logstats.py` (the shared
"given" starting file every harness copies from) was twice found
silently overwritten with an already-fixed version by a runaway
harness process, which would have made every subsequent run's "success"
meaningless -- the harness would be starting from a solved file, not
the real baseline. This is why `grading/run_harness.sh` now refuses to
start any run unless `task/` still byte-matches `baseline/`, and why
`task/`'s files are `chmod 444` (read-only) as a second line of
defense. All results in this document were generated after both fixes
were in place, and each was independently re-diffed against
`baseline/logstats.py` directly rather than trusted from the
harness's own transcript or `grade.sh`'s cached output. If you add
more trials later, keep doing that spot-check rather than assuming
grading output can't be fooled by a corrupted starting file.
