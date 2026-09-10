---
name: security-review
description: Security checklist for changes to broker/API integration, config, secrets handling, order execution, or Dockerfiles. Use when reviewing or writing code in those areas.
---

# Security review

Run this checklist against the change:

- [ ] No hardcoded secrets (keys, tokens, broker credentials). Loaded from env
      or gitignored config.
- [ ] Secrets never logged, never in error messages, never in commits.
- [ ] External input (broker responses, webhooks, feeds, CLI args) validated at
      the boundary.
- [ ] No `eval`/`exec` on external data; no `shell=True` with interpolated input.
- [ ] Live-order code paths gated behind an explicit flag + config value.
- [ ] Dependencies pinned; any new dependency justified.
- [ ] Dockerfile (if touched): non-root user, no secrets baked into layers.

Report failures with `file:line` and the fix. If all pass, say so in one line.
