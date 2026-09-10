# Roadmap

Roughly 8–10 weeks part-time. The ordering matters more than the estimates: each
phase should leave the project presentable, so a stall in a later phase doesn't
leave nothing to show.

A finished smaller version beats a 60%-complete larger one. "I cut X because Y"
is a good answer; "I didn't get X working" is not.

---

## Phase 1 — Skeleton (1–2 weeks)

No LLM at all. Prove the plumbing before adding the interesting part.

- Data ingestion for one instrument, a handful of indicators
- Full database schema (all tables, including `configs` — retrofitting it is painful)
- `cycle_requests` queue with `FOR UPDATE SKIP LOCKED`
- Scheduler and cycle worker as separate processes
- Paper execution tracking a simulated portfolio
- A dummy decision function — random or always-hold
- Cycle steps 1–4, 8, 9
- `docker compose up` brings everything up

**Done when:** the loop runs unattended for three days, bundles are logged, and
every decision traces to a bundle.

---

## Phase 2 — The debate (2 weeks)

- Bull, bear, and judge prompts as versioned files
- Structured JSON output with schema validation; parse failures logged loudly
- Bull and bear called in parallel on an identical frozen bundle
- Response caching from day one, not retrofitted
- Cycle steps 5–7
- ML field in the bundle is a stub returning 0.5

**Done when:** you can read a transcript of an actual argument and it isn't
embarrassing, and re-running the same bundles produces byte-identical decisions.

---

## Phase 3 — ML voice (3 weeks)

The most self-contained phase and the most likely to overrun. This is real ML
work, not a weekend.

- Feature engineering from historical data
- XGBoost/LightGBM stacking with a logistic-regression meta-learner
- Triple-barrier labeling
- Purged walk-forward cross-validation
- HMM regime detection if time allows
- Replace the stub in bundle assembly; include `historical_accuracy` so agents
  know how much to trust it

**Done when:** the model validates on walk-forward CV and its prediction appears
in bundles with an honest accuracy figure attached.

---

## Phase 4 — Event path (1–2 weeks)

- Text feed ingestion with deduplication
- Cheap relevance filter (Haiku) scoring market relevance and urgency
- Escalation threshold and enqueueing
- Queue collapsing so a news burst produces one cycle

Check current API pricing and terms before architecting around a specific source.
Financial news APIs are often more practical than social feeds.

**Done when:** a real event triggers a cycle end to end, and three events in a
minute produce one cycle rather than three.

---

## Phase 5 — Resolver and measurement (1–2 weeks)

Where the project stops being a build and becomes an experiment.

- Resolver job: find unresolved decisions, compute outcomes for **all** decisions
  including HOLDs
- Argument-quality rubric, versioned
- Evaluator agent, graded without sight of outcomes
- Ablation harness: `full`, `no_bear`, `no_ml`, `claude_only`, plus a permanent
  random-entry baseline

**Done when:** ablation runs produce comparable numbers over the same bundles, and
you can state whether argument quality correlates with outcomes.

---

## Phase 6 — Replay dashboard (spread throughout)

Do not leave this to the end — it's needed for debugging by week three. Start
crude, improve continuously.

- Scrub to any decision and see the bundle, both arguments, the ML read, the
  judge's ruling, the gate's adjustment, and what happened next
- Agent scoreboard over time
- Counterfactual view: what the untaken trades would have done

**Done when:** a stranger can replay any decision without explanation.

---

## Before Phase 1

Three things to settle first:

1. **Pick the instrument.** Crypto is easier for data and runs 24/7; an equity
   index or FX pair responds far more legibly to political and macro text.
2. **Fix the evaluation horizon.** No measurement means anything until this is
   locked.
3. **Lock a holdout window** and don't look at it until Phase 5.

---

## Throughout

- **Keep an engineering log.** The debugging stories are the interview content and
  you will not remember them in six months.
- **A README that gets a stranger to a working demo in ten minutes** is worth more
  than another feature, and most projects fail this.
- **Update `docs/decisions.md` when a position changes.**