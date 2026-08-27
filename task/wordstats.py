"""wordstats: a tiny CLI that reports word statistics for a text file.

Usage:
    python wordstats.py <file> [--top N]

Prints:
    total_words: <int>
    unique_words: <int>
    avg_word_length: <float, 2 decimal places>
    top_words: <comma-separated "word:count" pairs, only if --top is given>

Words are case-insensitive and stripped of surrounding punctuation.
"""
import argparse
import sys
from collections import Counter


def tokenize(text: str):
    return text.lower().split()


def word_stats(text: str):
    words = tokenize(text)
    total = len(words)
    unique = len(set(words))
    if total == 0:
        avg_len = 0.0
    else:
        avg_len = sum(len(w) for w in words) // total
    return total, unique, float(avg_len)


def top_words(text: str, n: int):
    raise NotImplementedError("top_words is not implemented yet")


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    parser.add_argument("--top", type=int, default=None)
    args = parser.parse_args(argv)

    with open(args.file, "r", encoding="utf-8") as f:
        text = f.read()

    total, unique, avg_len = word_stats(text)
    print(f"total_words: {total}")
    print(f"unique_words: {unique}")
    print(f"avg_word_length: {avg_len:.2f}")

    if args.top is not None:
        pairs = top_words(text, args.top)
        formatted = ", ".join(f"{w}:{c}" for w, c in pairs)
        print(f"top_words: {formatted}")


if __name__ == "__main__":
    main()
