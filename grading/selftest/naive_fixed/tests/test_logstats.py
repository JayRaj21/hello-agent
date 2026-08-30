import pathlib

import logstats


def test_parse_line_basic():
    result = logstats.parse_line("127.0.0.1 GET /index.html 200 512")
    assert result == ("127.0.0.1", "GET", "/index.html", 200, 512)
    assert isinstance(result[3], int)
    assert isinstance(result[4], int)


def test_parse_line_strips_query_string():
    result = logstats.parse_line("127.0.0.1 GET /search?q=cats 200 1024")
    assert result[2] == "/search"


def test_parse_line_skips_blank_and_malformed():
    assert logstats.parse_line("") is None
    assert logstats.parse_line("   ") is None
    assert logstats.parse_line("127.0.0.1 GET /x 200") is None


def test_summarize_counts_bytes_and_errors():
    lines = [
        "127.0.0.1 GET /a 200 100",
        "127.0.0.1 GET /a 200 200",
        "127.0.0.1 GET /b 404 50",
        "127.0.0.1 GET /c 500 25",
        "127.0.0.1 GET /a 200 300",
    ]
    summary = logstats.summarize(lines)
    assert summary["total"] == 5
    assert summary["bytes"] == 675
    assert summary["errors"] == 2
    assert summary["paths"] == {"/a": 3, "/b": 1, "/c": 1}


def test_top_paths_orders_by_count_desc():
    counts = {"/a": 5, "/b": 10, "/c": 1}
    result = logstats.top_paths(counts, 3)
    result_counts = [c for _, c in result]
    assert result_counts == sorted(result_counts, reverse=True)
    assert result == [("/b", 10), ("/a", 5), ("/c", 1)]


def test_top_paths_does_not_consume_input():
    counts = {"/a": 5, "/b": 10, "/c": 1}
    snapshot = dict(counts)
    first = logstats.top_paths(counts, 2)
    assert counts == snapshot
    second = logstats.top_paths(counts, 2)
    assert counts == snapshot
    assert first == second


def test_top_paths_tie_membership():
    counts = {"/a": 3, "/bb": 3, "/Zz": 3, "/c": 3, "/x": 1}
    result = logstats.top_paths(counts, 2)
    assert len(result) == 2
    tied_paths = {"/a", "/bb", "/Zz", "/c"}
    for path, count in result:
        assert path in tied_paths
        assert count == 3


def test_format_report_rounds_half_up():
    summary = {"total": 400, "errors": 49, "bytes": 0, "paths": {}}
    assert logstats.format_report(summary) == "requests: 400\nerrors: 49 (12.3%)"


def test_main_smoke(capsys):
    sample_log_path = pathlib.Path(__file__).parent.parent / "sample.log"
    rc = logstats.main([str(sample_log_path)])
    assert rc == 0
    out = capsys.readouterr().out
    assert "requests:" in out
