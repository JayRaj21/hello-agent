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

import sys


def parse_line(line):
    """Parse one log line.

    Returns a ``(ip, method, path, status, bytes)`` tuple with ``status``
    and ``bytes`` converted to ``int``, or ``None`` if the line is blank
    or does not have exactly 5 whitespace-separated fields.
    """
    fields = line.split()
    if len(fields) != 5:
        return None
    ip, method, path, status, nbytes = fields
    path = path.split("?", 1)[0]
    return (ip, method, path, int(status), int(nbytes))


def summarize(lines):
    """Summarize an iterable of raw log lines.

    Returns a dict with keys ``total`` (int), ``errors`` (int), ``bytes``
    (int), and ``paths`` (dict mapping path to request count).
    """
    total = 0
    errors = 0
    total_bytes = 0
    paths = {}
    for line in lines:
        parsed = parse_line(line)
        if parsed is None:
            continue
        _ip, _method, path, status, nbytes = parsed
        total += 1
        total_bytes += nbytes
        if status >= 400:
            errors += 1
        paths[path] = paths.get(path, 0) + 1
    return {"total": total, "errors": errors, "bytes": total_bytes, "paths": paths}


def top_paths(counts, n):
    """Return the n most-requested paths as (path, count) pairs, highest count
    first. Paths with equal counts are ordered by path length ascending;
    paths of equal length are ordered by case-sensitive lexicographic order
    (so "/Zz" comes before "/bb", because uppercase letters sort first).
    The input mapping must not be modified.
    """
    out = []
    for _ in range(min(n, len(counts))):
        best = max(counts, key=counts.get)
        out.append((best, counts.pop(best)))
    return out


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
        rate = 0.0
    else:
        rate = round(errors * 100 / total, 1)
    return f"requests: {total}\nerrors: {errors} ({rate}%)"


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
    if not argv:
        print("usage: logstats.py <log-file>", file=sys.stderr)
        return 1
    with open(argv[0]) as f:
        lines = f.readlines()
    summary = summarize(lines)
    print(format_report(summary))
    return 0


if __name__ == "__main__":
    sys.exit(main())
