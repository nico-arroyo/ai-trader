---
paths:
  - "**/agents/**"
  - "**/judge/**"
  - "**/gate/**"
  - "**/cycle/**"
  - "**/evaluator/**"
  - "**/data/**"
  - "**/*bundle*.py"
---

# Debate / decision / data rules

These restate the hard constraints in `CLAUDE.md` at the point of editing — see
that file for the full list. Do not weaken any of them.

- **Agents receive data, never fetch it.** No price/news API calls inside an
  agent. The evidence bundle is assembled, frozen, and passed by value.
- **Bull and bear get byte-identical bundles.** Any asymmetry rigs the debate.
- **Data-layer queries take `as_of` and cannot return rows after it** — enforced
  in the query layer, not by convention. This is the anti-lookahead boundary.
- **Every LLM response is cached** by `hash(bundle_hash + role + prompt_version
  + model)`; log `cache_hit` on every response row. Bump `prompt_version` on any
  prompt edit.
- **Only the cycle worker writes portfolio state.**
- **The evaluator never sees outcomes** and never feeds back into a decision.
- **The gate can shrink or veto a position, never enlarge it.** Deterministic,
  no model call.
- **Every row carries a `bundle_id`.**
- Log JSON parse failures loudly; never `except: pass` into a HOLD.
