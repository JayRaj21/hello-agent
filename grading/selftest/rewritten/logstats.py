"""Summarize a toy web server access log.

Each line of the log has the format:

    <ip> <method> <path> <status> <bytes>

space-separated, e.g. ``127.0.0.1 GET /index.html?ref=x 200 512``.

Blank lines, and lines whose field count is not exactly 5, are skipped
and do not count toward the total number of requests.

The query string -- everything from the first ``?`` onward -- is
stripped from the path before it is recorded or counted.

A request whose status code is 400 or greater counts as an error.
"""

import decimal
import sys

FIELD_COUNT = 5
ERROR_STATUS_THRESHOLD = 400


def parse_line(raw_line):
    """Parse one log line.

    Returns a ``(ip, method, path, status, bytes)`` tuple with ``status``
    and ``bytes`` converted to ``int``, or ``None`` if the line is blank
    or does not have exactly 5 whitespace-separated fields.
    """
    tokens = raw_line.split()
    if len(tokens) != FIELD_COUNT:
        return None
    source_ip, http_method, raw_path, status_code, byte_count = tokens
    clean_path, _, _query = raw_path.partition("?")
    return (source_ip, http_method, clean_path, int(status_code), int(byte_count))


def summarize(lines):
    """Summarize an iterable of raw log lines.

    Returns a dict with keys ``total`` (int), ``errors`` (int), ``bytes``
    (int), and ``paths`` (dict mapping path to request count).
    """
    stats = {"total": 0, "errors": 0, "bytes": 0, "paths": {}}
    for raw_line in lines:
        entry = parse_line(raw_line)
        if entry is None:
            continue
        _, _, path, status, nbytes = entry
        stats["total"] += 1
        stats["bytes"] += nbytes
        if status >= ERROR_STATUS_THRESHOLD:
            stats["errors"] += 1
        stats["paths"][path] = stats["paths"].get(path, 0) + 1
    return stats


def _sort_key(path_and_count):
    path, count = path_and_count
    return (-count, len(path), path)


def top_paths(counts, n):
    """Return the n most-requested paths as (path, count) pairs, highest count
    first. Paths with equal counts are ordered by path length ascending;
    paths of equal length are ordered by case-sensitive lexicographic order
    (so "/Zz" comes before "/bb", because uppercase letters sort first).
    The input mapping must not be modified.
    """
    ranked = sorted(counts.items(), key=_sort_key)
    return ranked[:n]


def _half_up_percentage(errors, total):
    exact = decimal.Decimal(errors) * 100 / decimal.Decimal(total)
    return exact.quantize(decimal.Decimal("0.1"), rounding=decimal.ROUND_HALF_UP)


def format_report(summary):
    """Format a summary dict as a two-line human-readable report.

    The first line is ``requests: <total>``. The second line is
    ``errors: <errors> (<rate>%)`` where the error rate is shown as a
    percentage with exactly one decimal place, rounded half-up (so 12.25
    becomes 12.3). If ``total`` is 0, the rate is shown as ``0.0``.
    The returned string has no trailing newline.
    """
    total = summary["total"]
    errors = summary["errors"]
    if total == 0:
        percentage = decimal.Decimal("0.0")
    else:
        percentage = _half_up_percentage(errors, total)
    lines = [
        "requests: {}".format(total),
        "errors: {} ({}%)".format(errors, percentage),
    ]
    return "\n".join(lines)


def main(argv=None):
    args = sys.argv[1:] if argv is None else argv
    if not args:
        sys.stderr.write("usage: logstats.py <log-file>\n")
        return 1
    log_path = args[0]
    with open(log_path) as log_file:
        raw_lines = log_file.readlines()
    report = format_report(summarize(raw_lines))
    print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
