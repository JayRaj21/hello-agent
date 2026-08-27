#!/usr/bin/env bash
# Grades one harness's attempt at the wordstats task.
#
# Usage: scripts/grade.sh <path-to-harness-working-copy-of-task-dir>
#
# Prints a metrics block. Append it to results/<harness>.md.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <path-to-attempted-task-dir>" >&2
  exit 1
fi

ATTEMPT_DIR="$1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORDSTATS="$ATTEMPT_DIR/wordstats.py"

if [ ! -f "$WORDSTATS" ]; then
  echo "error: $WORDSTATS not found" >&2
  exit 1
fi

if ! diff -q "$REPO_ROOT/task/tests/test_wordstats.py" "$ATTEMPT_DIR/tests/test_wordstats.py" > /dev/null 2>&1; then
  echo "WARNING: tests/test_wordstats.py was modified from baseline (disqualifying unless justified)"
fi

echo "== test results =="
cd "$ATTEMPT_DIR"
PYTEST_OUTPUT="$(python3 -m pytest tests/ -q 2>&1 || true)"
echo "$PYTEST_OUTPUT" | tail -5

PASS_COUNT="$(echo "$PYTEST_OUTPUT" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' || echo 0)"
FAIL_COUNT="$(echo "$PYTEST_OUTPUT" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' || echo 0)"

echo ""
echo "== diff size vs baseline (wordstats.py only) =="
diff -u "$REPO_ROOT/task/wordstats.py" "$WORDSTATS" > /tmp/wordstats.diff || true
ADDED="$(grep -cE '^\+[^+]' /tmp/wordstats.diff || true)"
REMOVED="$(grep -cE '^-[^-]' /tmp/wordstats.diff || true)"
echo "lines added: $ADDED, lines removed: $REMOVED"

echo ""
echo "== summary =="
echo "tests_passed: $PASS_COUNT / 6"
echo "tests_failed: $FAIL_COUNT"
echo "diff_lines: $((ADDED + REMOVED))"
