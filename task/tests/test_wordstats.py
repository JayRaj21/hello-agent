import subprocess
import sys
import textwrap
from pathlib import Path

WORDSTATS = Path(__file__).parent.parent / "wordstats.py"


def run(tmp_path, text, extra_args=None):
    f = tmp_path / "input.txt"
    f.write_text(text, encoding="utf-8")
    args = [sys.executable, str(WORDSTATS), str(f)]
    if extra_args:
        args += extra_args
    result = subprocess.run(args, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    return result.stdout


def parse(stdout):
    fields = {}
    for line in stdout.strip().splitlines():
        key, _, value = line.partition(": ")
        fields[key] = value
    return fields


def test_punctuation_is_stripped(tmp_path):
    # "dog." "dog," "dog!" and "dog" must all count as the same word.
    out = parse(run(tmp_path, "dog. dog, dog! dog"))
    assert out["total_words"] == "4"
    assert out["unique_words"] == "1"


def test_unique_word_count(tmp_path):
    out = parse(run(tmp_path, "cat cat dog Dog CAT"))
    assert out["total_words"] == "5"
    assert out["unique_words"] == "2"


def test_average_word_length_is_a_float(tmp_path):
    # "a" (1) + "bb" (2) + "ccc" (3) + "dddd" (4) -> 10/4 = 2.5, not truncated to 2
    out = parse(run(tmp_path, "a bb ccc dddd"))
    assert out["avg_word_length"] == "2.50"


def test_empty_file(tmp_path):
    out = parse(run(tmp_path, ""))
    assert out["total_words"] == "0"
    assert out["unique_words"] == "0"
    assert out["avg_word_length"] == "0.00"


def test_top_words_most_common_first(tmp_path):
    out = parse(run(tmp_path, "dog cat dog bird dog cat", ["--top", "2"]))
    assert out["top_words"] == "dog:3, cat:2"


def test_top_words_ties_broken_alphabetically(tmp_path):
    out = parse(run(tmp_path, "zebra apple mango", ["--top", "3"]))
    assert out["top_words"] == "apple:1, mango:1, zebra:1"
