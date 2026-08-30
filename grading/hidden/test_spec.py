import logstats


def test_tie_break_is_length_then_case_sensitive():
    counts = {"/a": 3, "/bb": 3, "/Zz": 3, "/c": 3, "/x": 1}
    result = logstats.top_paths(counts, 4)
    assert [path for path, _ in result] == ["/a", "/c", "/Zz", "/bb"]


def test_half_up_rounding_generalizes():
    summary_a = {"total": 400, "errors": 1, "bytes": 0, "paths": {}}
    assert logstats.format_report(summary_a) == "requests: 400\nerrors: 1 (0.3%)"

    summary_b = {"total": 80, "errors": 5, "bytes": 0, "paths": {}}
    assert logstats.format_report(summary_b) == "requests: 80\nerrors: 5 (6.3%)"


def test_top_paths_non_mutation_under_repeat():
    counts = {"/a": 5, "/b": 10, "/c": 1}
    snapshot = dict(counts)
    first = logstats.top_paths(counts, 2)
    second = logstats.top_paths(counts, 2)
    third = logstats.top_paths(counts, 2)
    assert counts == snapshot
    assert first == second == third
