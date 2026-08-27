Paste this exact prompt into each agent harness, unmodified, as the first message in a fresh session rooted at the `task/` directory (only `task/`, not this whole repo).

---

There is a Python CLI tool in `wordstats.py` with a test suite in `tests/test_wordstats.py`. Some tests are failing. Make all tests pass by fixing `wordstats.py`. Do not modify the tests. When you're done, tell me the tests pass.

---

Rules for a fair comparison:

- Give every harness the same starting state: a fresh checkout of `task/` at the `baseline` git tag, in its own directory/session, with no other files or prior conversation.
- Do not answer clarifying questions with more detail than the prompt already contains — if a harness asks, respond "use your best judgment," and note in RESULTS.md that it asked.
- Let each harness run to completion on its own (don't nudge it toward the fix).
- Time from when you send the prompt to when the harness reports done.
