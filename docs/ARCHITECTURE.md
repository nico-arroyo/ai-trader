# Architecture

## Central principle

A decision is a pure function of a frozen evidence bundle:

```
decision = f(evidence_bundle)
```

If that holds, reproducibility, replay, ablation, and clean measurement come for
free. If it doesn't — if an agent fetches live data mid-cycle, or the bundle
changes between the bull call and the bear call — all four are lost, and the
failure is silent. Most of the constraints in `CLAUDE.md` exist to protect this
one property.

## Processes

Four processes plus a database. Each has exactly one job.

| # | Process | Job | Touches portfolio state |
|---|---------|-----|------------------------|
| 1 | Scheduler | Emits a cycle request on a clock | No |
| 2 | Event ingester | Polls text feeds, dedupes, filters, emits cycle requests | No |
| 3 | Cycle worker | Runs one cycle start to finish | **Yes — only this one** |
| 4 | Resolver | Fills in outcomes, runs the evaluator | No |

Two producers, one queue, one consumer. Concurrency problems are designed out
rather than solved: there is no lock, no transaction contention, and no way for
two cycles to disagree about the current position. The worker being single is a
feature. A cycle takes roughly 10–30 seconds with bull and bear called in
parallel; events queue behind it, which is fine because this system does not
compete on latency.

The resolver and the dashboard are strictly downstream. They read what the worker
wrote and nothing they produce flows back into a decision. If the resolver ever
needs to influence the worker, stop — that is the moment the experiment stops
being measurable.

## The cycle: nine steps

**1. Trigger arrives.** A cycle request lands in the queue carrying a trigger type
(`scheduled` or `event`), a timestamp, and for events a reference to the source text.

**2. Worker picks it up.** The worker pops the request and drains any other queued
requests for the same instrument, merging their triggers into one cycle. Three news
events in a minute produce one cycle with all three in the bundle, not three cycles.

**3. Assemble the evidence bundle.** At a single `as_of` timestamp, gather:
market data and computed indicators; recent relevant text including whatever
triggered this cycle; the ML prediction; current portfolio state. Serialize to
JSON, hash it.

**4. Persist the bundle.** Write to the database *before* any LLM call. If the
cycle crashes at step 6, it can be replayed from here.

**5. Run bull and bear in parallel.** Both receive the identical frozen bundle.
Neither can fetch anything. Both return structured JSON.

**6. Run judge.** Receives the bundle plus both arguments. Returns an action, a
requested size, and a confidence.

**7. Gate.** Deterministic code, no model call. Checks the requested size against
position limits. Can shrink or veto, never enlarge. Records the reason for any
adjustment.

**8. Execute and log.** Simulated fill, update portfolio, write the decision, the
trade, and all agent responses — every row linked back to the bundle.

**9. Cycle ends.** The worker returns to the queue. The outcome is not yet known
and nothing further happens here.

## After the cycle: the resolver

Runs separately, on its own schedule.

**A. Find unresolved decisions.** Query for decisions whose evaluation horizon has
elapsed.

**B. Compute the outcome.** What did the price do over the horizon? Was the
decision directionally correct? Write to `outcomes`.

This runs for **every decision, including HOLDs.** A decision not to trade still
has an outcome. Scoring only executed trades throws away most of the data and
makes the sample-size problem much worse than it needs to be.

**C. Run the evaluator.** Grade the bull and bear arguments against a rubric —
evidence cited, internal consistency, whether the argument engaged the other side.
Write to `evaluations`.

The evaluator sees the arguments. It does **not** see the outcome. That separation
is the entire experiment: it lets you ask whether argument quality predicts
decision quality, which is unanswerable if the grader already knows who won.

## The event path

Three stages before a cycle is ever requested:

1. **Ingest** — poll or webhook, dedupe (the same story from three outlets is one
   event), store raw.
2. **Filter** — a cheap model call scoring market relevance and urgency for the
   traded instrument. Runs on everything, so it must be fast and cheap.
3. **Escalate** — above a threshold, enqueue a cycle request.

Realistic expectation: market-moving text is priced in within seconds, and this
pipeline takes seconds to minutes. It will not front-run the reaction. What it can
plausibly judge is the second-order question — whether the initial move was an
overreaction, whether it is durable, whether it changes the regime.

## Failure modes to design against

- **Bundle drift** — assembling the bundle lazily so one agent gets fresher data.
  Freeze explicitly, pass by value.
- **Partial cycles** — an LLM call fails halfway. Bundle is written first, every
  stage is idempotent, failed cycles are marked `failed` rather than deleted.
- **Silent JSON parse failures** — an almost-valid response swallowed into a HOLD.
  A rising parse-failure rate is a real signal that a prompt broke.
- **Clock and timezone bugs in replay** — the classic source of accidental
  lookahead. UTC everywhere, and in replay mode the bundle assembler must be
  physically unable to query past the simulated timestamp.

## Open questions

Not yet decided; both affect the data stack.

- **Instrument.** Crypto is easier for data access and runs 24/7. An equity index
  or FX pair responds far more legibly to political and macro text. If the text
  path matters, that argues against crypto.
- **Evaluation horizon.** The window over which the resolver scores a decision.
  Must be fixed before any measurement is meaningful.