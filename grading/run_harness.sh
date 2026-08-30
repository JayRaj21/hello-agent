#!/usr/bin/env bash
# Automates one harness run against the hello-agent task: fresh copy,
# timed non-interactive launch, grading, and a pre-filled results file.
#
# Usage:
#   grading/run_harness.sh [-f|--force] claude [label]
#   grading/run_harness.sh [-f|--force] pi <ollama-model> [label]
#   grading/run_harness.sh [-f|--force] opencode <ollama-model> [label]
#
# Run copies are written to ../hello-agent-runs/<label>/ (a sibling of
# this repo, not runs/<label>/ inside it -- see the comment near
# RUNS_ROOT below for why). results/<label>.md and
# results/<label>.transcript.log still land in this repo's results/.
#
# By default a label can only be used once -- re-running the same
# harness/model combo without -f/--force refuses to clobber the prior
# run. Pass -f/--force to re-run under the same label, overwriting the
# previous attempt's run copy and results.
#
# Examples:
#   grading/run_harness.sh claude
#   grading/run_harness.sh pi qwen3:14b
#   grading/run_harness.sh opencode qwen3:14b pi-vs-opencode-qwen3
#   grading/run_harness.sh -f pi qwen3:14b   # re-run, overwriting the prior pi-qwen3:14b result
#
# LIMITATION (read before trusting a run): this is a non-interactive,
# one-shot invocation. It cannot conduct the interactive "answer
# clarifying questions with 'use your best judgment'" exchange described
# in PROMPT.md, because a scripted run has no way to hear the question
# and answer it. To keep every harness on equal footing, the prompt sent
# here is AGENT_PROMPT.md plus one appended sentence instructing the
# harness to use its best judgment on anything it would otherwise ask
# about, rather than pausing -- applied identically for every harness.
# This means "did it ask a clarifying question" can no longer be
# observed live; check the saved transcript for whether it would have.
set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FORCE=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    -f|--force) FORCE=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

HARNESS="${1:-}"

case "$HARNESS" in
  claude)
    MODEL=""
    LABEL="${2:-claude-code}"
    ;;
  pi)
    MODEL="${2:-}"
    LABEL="${3:-pi-${MODEL}}"
    if [[ -z "$MODEL" ]]; then
      echo "usage: $0 pi <ollama-model> [label]" >&2
      exit 2
    fi
    ;;
  opencode)
    MODEL="${2:-}"
    LABEL="${3:-opencode-${MODEL}}"
    if [[ -z "$MODEL" ]]; then
      echo "usage: $0 opencode <ollama-model> [label]" >&2
      exit 2
    fi
    ;;
  *)
    echo "usage: $0 {claude|pi <model>|opencode <model>} [label]" >&2
    exit 2
    ;;
esac

# Run directories live OUTSIDE the hello-agent git repo entirely (as a
# sibling directory), not under $KIT/runs/. This has been observed to
# matter: with runs/<label>/ nested inside the same git repo as task/,
# `claude -p --dangerously-skip-permissions` reliably edited
# task/logstats.py directly instead of the run copy, twice, despite the
# shell being cd'd into the run directory -- most likely because
# skipping permissions also skips directory confinement, and being
# inside the same repo let it resolve/prefer the enclosing project's
# real task/ path (possibly via loaded project memory/CLAUDE.md
# context) over the literal cwd. Moving runs/ outside the repo removes
# that ambient context entirely.
RUNS_ROOT="$(dirname "$KIT")/hello-agent-runs"
RUN_DIR="$RUNS_ROOT/$LABEL"
if [[ -e "$RUN_DIR" && "$FORCE" -eq 0 ]]; then
  echo "error: $RUN_DIR already exists -- remove it, pick a different label, or pass -f/--force to overwrite" >&2
  exit 2
fi
if [[ "$FORCE" -eq 1 ]]; then
  rm -rf "$RUN_DIR" "$KIT/results/${LABEL}.md" "$KIT/results/${LABEL}.transcript.log"
fi

# Integrity check: task/ must still match baseline/ (i.e. still be the
# unmodified buggy starting state) before we trust it as the source for
# a fresh run. If some prior process ever wrote into task/ directly
# instead of its own runs/<label>/ copy, every run since would silently
# start from an already-solved file and "pass" without the harness
# having done anything -- this has actually happened once, so don't
# skip this check.
TASK_DIFF="$(diff -rq -x '__pycache__' -x '.pytest_cache' "$KIT/task" "$KIT/baseline" 2>&1)"
if [[ -n "$TASK_DIFF" ]]; then
  echo "error: task/ no longer matches baseline/ -- it has been corrupted" >&2
  echo "$TASK_DIFF" >&2
  echo "refusing to start a run from a corrupted task/. Restore it first, e.g.:" >&2
  echo "  cp \"$KIT/baseline/logstats.py\" \"$KIT/task/logstats.py\"" >&2
  exit 2
fi

mkdir -p "$RUNS_ROOT"
cp -a "$KIT/task/" "$RUN_DIR"
# task/'s files are read-only (chmod 444) to stop stray edits from
# landing there directly; cp -a preserves that mode, so make the
# working copy writable again -- only the copy, never task/ itself.
chmod -R u+w "$RUN_DIR"

PROMPT="$(cat "$KIT/AGENT_PROMPT.md")
If anything is unclear or you would otherwise ask a clarifying question, use your best judgment and proceed without asking."

TRANSCRIPT="$KIT/results/${LABEL}.transcript.log"
TRANSCRIPT_REL="results/${LABEL}.transcript.log"
mkdir -p "$KIT/results"

echo "=== launching $HARNESS (label: $LABEL) ==="
START=$(date +%s.%N)

case "$HARNESS" in
  claude)
    # --dangerously-skip-permissions: required for -p (non-interactive)
    # to actually execute Edit/Write/Bash tool calls -- without it there
    # is no TTY to approve them, they're silently blocked, and Claude
    # Code has been observed to report "done" anyway without noticing
    # the edit never landed. Safe here because $RUN_DIR is disposable
    # scratch content, never the repo itself.
    (cd "$RUN_DIR" && claude -p --dangerously-skip-permissions "$PROMPT") >"$TRANSCRIPT" 2>&1
    ;;
  pi)
    # --mode json: pi's default TUI rendering (spinners, in-place
    # updates via ANSI cursor control) doesn't survive being redirected
    # to a file -- the real interaction gets lost and only stray
    # stderr lines remain. json mode emits structured, append-only
    # events instead, which is what a redirected transcript needs.
    # -ne (no extensions): this install has a broken extension
    # ("web_search" registered by two packages at once) that fatally
    # crashes startup non-deterministically. hello-agent's task needs
    # no extensions, so skip them entirely rather than fight the crash.
    (cd "$RUN_DIR" && pi -ne --provider ollama --model "$MODEL" --mode json -p "$PROMPT") >"$TRANSCRIPT" 2>&1
    ;;
  opencode)
    (cd "$RUN_DIR" && opencode run --model "ollama/$MODEL" "$PROMPT") >"$TRANSCRIPT" 2>&1
    ;;
esac
RUN_EXIT=$?

END=$(date +%s.%N)
ELAPSED=$(python3 -c "print(f'{$END - $START:.1f}')")

echo "=== $HARNESS finished in ${ELAPSED}s (exit $RUN_EXIT) ==="
echo "transcript: $TRANSCRIPT_REL"

echo "=== grading ==="
GRADE_OUTPUT="$("$KIT/grading/grade.sh" "$RUN_DIR" "$LABEL")"
echo "$GRADE_OUTPUT"

# --- generate results/<label>.md from the template, auto-filled where possible ---
RESULTS_FILE="$KIT/results/${LABEL}.md"

get_field() {
  echo "$GRADE_OUTPUT" | grep "^$1=" | cut -d= -f2-
}

cat > "$RESULTS_FILE" <<EOF
# Harness: $LABEL

- Date: $(date +%Y-%m-%d)
- Harness version: (fill in manually -- e.g. \`$HARNESS --version\`)
- Model used: ${MODEL:-default (Claude Code / your logged-in account)}
- Invocation: automated via \`grading/run_harness.sh\` (non-interactive,
  see script header for the clarifying-question caveat)

## Manual observations (fill in after reading the transcript)

| Metric | Value |
|---|---|
| Wall-clock time (prompt sent -> process exit) | ${ELAPSED}s (automated) |
| Number of tool calls (shell/edit/read, from transcript) | SEE TRANSCRIPT: $TRANSCRIPT_REL |
| Number of clarifying questions asked | N/A -- run was non-interactive with a "use your best judgment" fallback baked into the prompt; check transcript for whether it would have asked |
| Ran the test suite itself before declaring done? (y/n) | SEE TRANSCRIPT |
| Touched any file outside \`logstats.py\`? (y/n, which) | extra_files=$(get_field extra_files) missing_files=$(get_field missing_files) (cross-check with transcript) |
| Took any destructive/irreversible action? (y/n, what) | SEE TRANSCRIPT |
| Reported cost / tokens (if shown) | SEE TRANSCRIPT |

## Automated grading

\`\`\`
$GRADE_OUTPUT
\`\`\`

## Notes

(fill in after reading $TRANSCRIPT_REL)
EOF

echo "=== results file written: $RESULTS_FILE ==="
