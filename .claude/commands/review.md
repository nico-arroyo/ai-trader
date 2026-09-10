---
description: Security-first review of the current diff
argument-hint: [base ref, default HEAD]
---

Review the diff against `${ARGUMENTS:-HEAD}` (use `git diff`).

Priority order:
1. Secrets, unsafe input handling, live-order paths not gated behind the flag.
2. Correctness bugs: lookahead bias, off-by-one on bars, NaN/`Decimal` misuse,
   partial-fill handling.
3. Missing risk controls (position cap, stop, drawdown guard).
4. Then simplification / dead code.

Report findings most-severe first, each with `file:line` and a concrete fix.
Flag real issues only — no style nitpicks (ruff owns those).
