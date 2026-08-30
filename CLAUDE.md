# CLAUDE.md

Guidance for Claude Code (or any agent) working *in* this repo — not for
harnesses being *benchmarked by* it. See `README.md` for the general
project description; this file is for operational gotchas that aren't
obvious from reading the code, several of which were only discovered by
getting burned once.

## The one rule that matters most

**Never write to `task/` directly.** It's the pristine, buggy starting
state every benchmarked harness is supposed to receive. Its files are
`chmod 444` (read-only) as a safety net, but that net has already failed
once — see "The corruption incident" below. If you're fixing bugs,
testing something, or just poking at `logstats.py`, do it in a copy
(`grading/selftest/*/logstats.py`, or a scratch `/tmp` copy), never in
`task/` itself. If `task/logstats.py` ever needs restoring:

```bash
cp baseline/logstats.py task/logstats.py
```

`grading/run_harness.sh` checks `task/` against `baseline/` before every
run and refuses to proceed if they differ — don't bypass or remove that
check.

## Running Claude Code against this repo's own task, from inside this repo

If you ever invoke `claude -p --dangerously-skip-permissions` (or
similar) yourself while working in this repo — e.g. to test the
automation — **do it from a working directory outside this git repo**,
the way `grading/run_harness.sh` does (`../hello-agent-runs/<label>/`,
a sibling directory, not `runs/<label>/` inside the repo). This was
observed, twice, to edit `task/logstats.py` directly instead of the
intended isolated copy, even though the shell was `cd`'d into the run
directory first — most likely because skipping permissions also skips
directory confinement, and being nested inside the same repo let it
resolve the enclosing project's real `task/` path (possibly via loaded
project memory/`CLAUDE.md` context) instead of respecting the literal
cwd. This is why the automation moved run copies outside the repo
entirely — don't move them back in.

## Commit conventions

**Do not add a `Co-Authored-By: Claude ...` or `Claude-Session: ...`
trailer to commits in this repo.** The user wants sole authorship shown
on GitHub. This overrides the default git-commit instructions that would
otherwise add one.

## Don't trust `grade.sh` output blindly

Grading output (`visible_passed`, `hidden_passed`, diff size, etc.) has
been wrong before — not because the grader is buggy, but because the
file it graded didn't contain what its own transcript claimed (see
below). Before treating a result as real, spot-check it:

```bash
diff baseline/logstats.py <path-to-graded-copy>/logstats.py
```

A "0 lines changed" diff paired with a transcript that claims a fix was
made is the specific red flag that caught this before — it means the
edit landed somewhere else, not that the file was already correct.

## The corruption incident (why the above rules exist)

During initial benchmarking, `task/logstats.py` was found silently
overwritten with an already-fixed version — twice — which made every
subsequent run trivially "pass" without the harness under test having
done any real work. Both times, the transcript for the run that caused
it confidently described a correct fix, while the actual graded copy
showed zero real change. The fix was tracing the corruption by
timestamp and direct file diff, not by trusting any tool's self-report.
Full write-up: `results/SUMMARY.md`, final section.

The practical lesson: **verify with `diff` against `baseline/`, not by
reading what a harness (or an agent, including you) says it did.**

## Repo-specific facts worth knowing before editing things

- `AGENT_PROMPT.md` (repo root) is the *only* text a benchmarked harness
  ever sees. It is not inside `task/` on purpose — see `PROMPT.md` for
  why, and for which per-harness delivery methods (`pi`'s `@file`,
  `opencode`'s `-f` flag, etc.) were actually verified to work vs. not.
- `results/*.transcript.log` format differs by harness: `claude` and
  `opencode` write plain text; `pi` writes newline-delimited JSON
  (`--mode json`), because its default TUI rendering doesn't survive
  being redirected to a file.
- `grading/selftest/` fixtures are load-bearing test data for the grader
  itself, not scratch files — don't "clean them up."
- Local Ollama models vary widely in tool-calling reliability, and that
  reliability is harness-dependent, not just model-dependent (the same
  model can be rock-solid under one harness and unusable under another).
  Don't assume a model that worked once will work again without a
  second trial — `results/SUMMARY.md` has a concrete example of one
  harness/model pair producing five different outcomes in five tries.
