---
description: Run pytest, analyze failures, optionally fix
argument-hint: [pytest args] [--fix]
---

Run `uv run pytest $ARGUMENTS` (strip `--fix` before passing args to pytest).

- Report pass/fail counts and the actual failure output.
- For each failure: name the cause (test wrong, or code wrong).
- If `--fix` was passed: apply the minimal fix for genuine code bugs and
  re-run. Do not touch tests that are correctly failing.
