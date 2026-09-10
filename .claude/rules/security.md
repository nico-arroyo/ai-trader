# Security rules (all files)

- No hardcoded secrets: API keys, broker credentials, tokens. Read from env or
  a gitignored config. Never log them.
- `.env`, `.env.*`, and `secrets/` are never read, printed, or committed.
- Validate every external input at the trust boundary (broker responses,
  webhooks, market-data feeds, CLI args) with `pydantic` or explicit checks.
- No `eval`/`exec` on external data; no `shell=True` with interpolated input.
- Pin dependency versions; review any new dependency before adding it.
