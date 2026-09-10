---
paths:
  - "**/*.py"
---

# Python code style

- PEP 8; format and lint with `uv run ruff format .` / `uv run ruff check .`.
- Type hints on every function signature.
- Use the project logger, never `print()` or bare `logging`.
- `pydantic` models for config and any external/broker payload validation.
- Prefer stdlib and already-installed deps over new ones.
- Money: use `Decimal`, never binary floats, for prices, quantities, and PnL.
