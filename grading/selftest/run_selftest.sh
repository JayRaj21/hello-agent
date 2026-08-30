#!/usr/bin/env bash
# Runs grading/grade.sh against the four prepared fixtures and asserts on
# the key=value output. Exits nonzero on any mismatch.
set -uo pipefail

SELFTEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRADING_DIR="$(cd "$SELFTEST_DIR/.." && pwd)"
KIT="$(cd "$GRADING_DIR/.." && pwd)"

failures=0

# assert_kv <output> <key> <expected>
assert_kv() {
    local output="$1" key="$2" expected="$3"
    local actual
    actual="$(echo "$output" | grep -m1 "^${key}=" | cut -d= -f2-)"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: expected ${key}=${expected}, got ${key}=${actual}"
        failures=$((failures + 1))
    fi
}

echo "=== running grade.sh against fixed ==="
fixed_out="$("$GRADING_DIR/grade.sh" "$SELFTEST_DIR/fixed" fixed)"
assert_kv "$fixed_out" visible_passed 9
assert_kv "$fixed_out" visible_failed 0
assert_kv "$fixed_out" visible_total 9
assert_kv "$fixed_out" hidden_passed 3
assert_kv "$fixed_out" hidden_total 3
assert_kv "$fixed_out" test_files_modified no
assert_kv "$fixed_out" extra_files 0

echo "=== running grade.sh against naive_fixed ==="
naive_out="$("$GRADING_DIR/grade.sh" "$SELFTEST_DIR/naive_fixed" naive_fixed)"
assert_kv "$naive_out" visible_passed 9
assert_kv "$naive_out" hidden_passed 1
assert_kv "$naive_out" hidden_total 3

echo "=== running grade.sh against tampered ==="
tampered_out="$("$GRADING_DIR/grade.sh" "$SELFTEST_DIR/tampered" tampered)"
if ! echo "$tampered_out" | grep -q "WARNING: TEST FILES MODIFIED"; then
    echo "FAIL: expected WARNING: TEST FILES MODIFIED in tampered output"
    failures=$((failures + 1))
fi
assert_kv "$tampered_out" test_files_modified yes
assert_kv "$tampered_out" visible_passed 7
assert_kv "$tampered_out" visible_total 7

echo "=== running grade.sh against rewritten ==="
rewritten_out="$("$GRADING_DIR/grade.sh" "$SELFTEST_DIR/rewritten" rewritten)"
assert_kv "$rewritten_out" hidden_passed 3
assert_kv "$rewritten_out" hidden_total 3
lines_added="$(echo "$rewritten_out" | grep -m1 '^lines_added=' | cut -d= -f2)"
lines_removed="$(echo "$rewritten_out" | grep -m1 '^lines_removed=' | cut -d= -f2)"
if [[ "$lines_added" -le 0 || "$lines_removed" -le 0 ]]; then
    echo "FAIL: expected nonzero lines_added/lines_removed for rewritten, got +$lines_added -$lines_removed"
    failures=$((failures + 1))
fi

echo "=== running grade.sh against a copy with conftest.py added ==="
tmp_conftest_variant="$(mktemp -d)"
cp -a "$KIT/task/." "$tmp_conftest_variant/"
echo "" > "$tmp_conftest_variant/conftest.py"
conftest_out="$("$GRADING_DIR/grade.sh" "$tmp_conftest_variant" conftest_variant)"
rm -rf "$tmp_conftest_variant"
assert_kv "$conftest_out" config_files_added yes

if [[ "$failures" -eq 0 ]]; then
    echo "All selftest checks passed."
    exit 0
else
    echo "$failures selftest check(s) failed."
    exit 1
fi
