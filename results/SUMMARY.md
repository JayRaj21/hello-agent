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

**Behavior:** solved the task correctly and completely both times, with
a small, surgical diff. Used `Decimal`/`ROUND_HALF_UP` for the rounding
bug and a non-mutating `sorted()` with the exact three-key tie-break
(count desc, length asc, lexicographic) for `top_paths`, matching the
docstring precisely both trials. By far the fastest of the three.

### `pi` + `qwen3:14b` (local, via Ollama)

| Trial | Visible (9) | Hidden (3) | Diff | Time |
|---|---|---|---|---|
| 1 (`pi-qwen3-14b`) | 8/9 | 2/3 | +6/-5 | 334.1s |
| 2 (`pi-qwen3-2`) | 8/9 | 2/3 | +6/-5 | 194.6s |

**Behavior:** identical outcome both trials. Correctly fixed
`top_paths` -- non-mutating, exact correct tie-break sort key -- but
never touched `format_report` at all, leaving the banker's-rounding
bug (`round()` instead of half-up) completely unaddressed. Reads the
harder of the two bugs correctly and consistently misses the easier
one; a stable, reproducible partial-completion pattern, not a fluke.

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

## Cross-cutting conclusions

- **Claude Code is the clear leader** on every axis measured here:
  correctness, diff precision, and speed (speed comparison is not
  fully apples-to-apples -- see caveats).
- **Same local model, wildly different reliability depending on
  harness.** `qwen3:14b` under `pi` is boringly consistent (same
  partial result twice). The identical model under `opencode` is
  chaotic (five different outcomes in five tries). The harness
  materially shapes not just whether the model succeeds, but *how* it
  fails.
- **`pi`'s failure mode is an omission, not a guess.** It's not that
  it doesn't understand `format_report`'s bug -- it simply never
  engages with that function at all, both times. Worth checking in a
  future trial whether a more insistent prompt ("fix *all* the
  failures") changes this, since the current prompt already says
  "make the entire test suite pass."
- **`opencode`'s tool-call schema is a recurring failure surface.**
  The `filePath`-key `SchemaError` seen in trial 2 here also appeared
  with `llama3.1:8b` and `granite4:7b-a1b-h` in earlier smoke testing
  (see prior conversation) -- this is not a `qwen3:14b`-specific
  problem, it looks like a general fragility in how `opencode`'s tool
  schema is presented to locally-hosted models.

## Caveats

- **Sample sizes are small.** 2 trials for Claude Code and `pi`, 5 for
  `opencode`. The two low-N harnesses happened to be highly
  consistent, so 2 trials feels more trustworthy for them than it
  would in isolation -- but that's still not proof of a hard
  guarantee.
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
