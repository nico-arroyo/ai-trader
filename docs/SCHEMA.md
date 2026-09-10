# Schema

Postgres. Get this right before writing pipeline code — every measurement later
depends on being able to join these cleanly, and `configs` in particular is
painful to retrofit.

## Tables

### `cycle_requests` — the queue

Postgres doubles as the queue at this scale. `SELECT ... FOR UPDATE SKIP LOCKED`
is genuinely sufficient; Redis or a real broker is a later optimization that
probably won't be needed.

| Field | Notes |
|---|---|
| `id` | |
| `created_at` | UTC |
| `instrument` | Used to collapse queued requests |
| `trigger_type` | `scheduled` \| `event` |
| `trigger_ref` | For events, points at the source text |
| `status` | `pending` \| `claimed` \| `done` \| `failed` |
| `claimed_at` | |

### `evidence_bundles`

Written at step 4, before any LLM call.

| Field | Notes |
|---|---|
| `id` | |
| `created_at` | UTC |
| `as_of` | The simulated or real timestamp the bundle was assembled at |
| `bundle_hash` | Hash of `payload` |
| `instrument` | |
| `payload` | JSONB — the full frozen bundle |
| `trigger_type` | `scheduled` \| `event` |
| `trigger_ref` | May reference multiple merged triggers |

### `agent_responses`

Written at steps 5 and 6, and again by the resolver at step C for the evaluator.

| Field | Notes |
|---|---|
| `id` | |
| `bundle_id` | FK |
| `role` | `bull` \| `bear` \| `judge` \| `evaluator` \| `relevance_filter` |
| `model` | e.g. `claude-haiku-4-5` |
| `prompt_version` | Bumped on every prompt edit |
| `raw_response` | JSONB — exactly what came back |
| `parsed` | JSONB — after schema validation |
| `parse_ok` | Boolean; false rows are the signal a prompt broke |
| `latency_ms` | |
| `input_tokens`, `output_tokens` | Cost tracking |
| `cache_hit` | Distinguishes fresh runs from replays |

### `decisions`

Written at steps 7–8. One row per cycle, including HOLDs.

| Field | Notes |
|---|---|
| `id` | |
| `bundle_id` | FK |
| `judge_response_id` | FK to `agent_responses` |
| `config_id` | FK — which configuration produced this |
| `action` | `long` \| `short` \| `hold` \| `close` |
| `size_requested` | What the judge asked for |
| `size_after_gate` | What the gate allowed |
| `gate_reason` | Null if unchanged |
| `confidence` | Judge's stated confidence |

### `trades`

Only for decisions that resulted in execution.

| Field | Notes |
|---|---|
| `id` | |
| `decision_id` | FK |
| `side`, `size` | |
| `entry_price`, `entry_at` | |
| `exit_price`, `exit_at` | Null while open |
| `fees` | Model conservative fills — assume crossing the spread, add slippage |
| `pnl` | Null while open |

### `outcomes`

Written by the resolver at step B, for **every** decision including HOLDs.

| Field | Notes |
|---|---|
| `id` | |
| `decision_id` | FK |
| `horizon` | The evaluation window used |
| `price_at_horizon` | |
| `return_pct` | What the position would have returned, whether or not it was taken |
| `was_directionally_correct` | |
| `resolved_at` | |

### `evaluations`

Written by the resolver at step C. Graded without sight of `outcomes`.

| Field | Notes |
|---|---|
| `id` | |
| `bundle_id` | FK |
| `target_role` | `bull` \| `bear` — which argument is being graded |
| `evaluator_response_id` | FK to `agent_responses` |
| `rubric_version` | Same versioning discipline as prompts |
| `scores` | JSONB — per-criterion scores |

### `configs`

What makes ablation possible without re-running history.

| Field | Notes |
|---|---|
| `id` | |
| `name` | e.g. `full`, `no_bear`, `no_ml` |
| `agents_enabled` | JSONB |
| `prompt_versions` | JSONB — role → version |
| `ml_model_version` | Or `stub` |
| `created_at` | |

### `llm_cache`

| Field | Notes |
|---|---|
| `cache_key` | `hash(bundle_hash + role + prompt_version + model)` |
| `response` | JSONB |
| `created_at` | |

In the database, not in memory, so it survives restarts and is shared across
processes.

## Write points

| Step | Table |
|---|---|
| 1 | `cycle_requests` |
| 4 | `evidence_bundles` |
| 5 | `agent_responses` (bull, bear) |
| 6 | `agent_responses` (judge) |
| 7–8 | `decisions`, `trades` |
| B | `outcomes` |
| C | `agent_responses` (evaluator), `evaluations` |

## Design notes

**`configs` exists so ablation is a filter, not a re-run.** Every decision records
which configuration produced it. Comparing "with bear agent" against "without" is
then a query.

**`prompt_version` on every response.** Prompts change constantly. Without
versioning, measurements silently mix incompatible runs — and the cache silently
serves stale answers.

**`outcomes` is separate from `trades`** because a HOLD is a decision with an
outcome. Most cycles will be HOLDs. Scoring only executed trades discards the
majority of the data at exactly the moment sample size matters most.

**Every row traces to `bundle_id`.** One join key reconstructs any decision
completely: the evidence, both arguments, the ruling, the gate's adjustment, the
fill, the outcome, and the grades.