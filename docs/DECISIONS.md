# Decisions

Why the design is the way it is. Update this when a position changes — the
"we tried X, it didn't work, we do Y now" entries are both a guardrail against
re-litigating settled questions and the raw material for the eventual writeup.

---

## Framing: this is a measurement project, not a profit-seeking bot

Paper trading only. The architecture answers "how do we decide?" — it does not
contain an edge hypothesis, and building one would be a different project
entirely (structural trades like funding-rate capture, not prediction).

This is deliberate and should be stated plainly rather than discovered later.
The deliverable is a system whose reasoning can be inspected and measured, plus
findings about whether LLM argument quality predicts decision quality. Expected
P&L is approximately zero before costs and negative after them. That is the
correct expectation, not a failure.

Describe it as a multi-agent LLM decision system with an experimental evaluation
harness, tested on simulated trading. "AI trading bot" invites "did it make
money?", and the honest answer moves the conversation away from the parts that
were actually done well.

---

## Adversarial roles instead of domain specialists

The reference implementation splits agents by domain — a technical analyst and a
sentiment analyst reporting to a synthesizer. This splits by *position*: a bull
and a bear arguing opposing cases from identical evidence.

Specialists produce complementary reports. Adversaries produce a stress test.
The difference is real, not cosmetic — it changes what the judge is doing from
averaging two views to adjudicating a conflict.

**Known risk:** an agent asked to argue a side will always find something, so the
bear may bias the system toward HOLD. Inaction looks excellent in a backtest — no
fees, no losses — while producing nothing. Track how often trades the bear
objected to would have worked. If objected and unobjected trades perform the same,
the bear is adding cost and nothing else.

---

## The ML model is evidence, not a vote

It runs during bundle assembly as an ordinary function call, not an agent. Its
output — a calibrated probability, the model version, its historical accuracy, and
a regime label — becomes a field in the bundle that both agents and the judge read.

It does not vote, is not weighted against the agents by a formula, and cannot veto.
The judge may override it entirely, and when it does, that is a logged, inspectable
event worth measuring: how often does the judge override the ML, and is it right
when it does?

Why include it at all:

- **Independent failure modes.** Bull and bear are both LLMs reasoning over the
  same text and can be wrong in the same direction for the same reason. A
  gradient-boosted model pattern-matching over historical candles fails differently.
- **A known error rate.** You cannot say "Claude is right 57% of the time at this
  task" with confidence. You can say it about a model validated on held-out data.
  Nothing else in the system provides a calibrated prior.
- **It grounds the debate.** Both agents must engage with a number that
  contradicts one of them, which gives the evaluator something concrete to grade.

**Sequencing:** phases 1–2 use a stub returning 0.5. The debate works fine with a
neutral signal, and this avoids blocking the interesting part on three weeks of
feature engineering.

---

## The evaluator is strictly observational

It grades arguments without seeing outcomes, and nothing it produces feeds back
into a decision.

The moment argument scores influence trades, it becomes impossible to test whether
argument quality predicts outcomes — the experiment would be measuring itself.
This is the project's most distinctive contribution and the constraint protecting
it is non-negotiable.

The finding is interesting either way: correlation means LLM reasoning quality has
signal; no correlation is a sobering result about reasoning under noise, and worth
reporting.

---

## Single cycle worker, one queue

Two producers (scheduler, event ingester) enqueue; one worker consumes serially
and is the only process that touches portfolio state.

The alternative — parallel cycles with locking — is a genuine distributed-systems
problem and not the interesting part of this project. Serial processing costs
seconds of latency in a system that is not competing on latency.

Bursts are handled by collapsing: the worker drains all queued requests for the
same instrument and merges their triggers into one bundle.

---

## Response caching keyed by prompt version

`hash(bundle_hash + role + prompt_version + model)`, stored in the database.

LLM calls are non-deterministic even at temperature 0. Without caching:

- Code changes cannot be distinguished from model randomness on re-runs
- Ablations are noisy, because "with bear" and "without bear" also differ by chance
- Every backtest re-run costs full price

With it, a re-run is byte-identical, changing only the judge prompt replays bull
and bear from cache, and an ablation becomes a controlled experiment where the
bear's presence is genuinely the only variable.

`prompt_version` must be in the key. Omitting it means silently serving stale
answers after a prompt edit — the most likely bug in this area.

---

## RL was cut

Originally planned as an exit and position-sizing layer, then dropped.

- **Sample efficiency.** PPO is data-hungry; a few thousand candles yields a few
  hundred trade episodes, orders of magnitude short of a stable policy. The likely
  outcome is something that trains, produces a plausible equity curve, and is
  overfit to one price path.
- **It conflicts with adaptive calibration.** An RL agent trained on episodes from
  one entry policy has a non-stationary environment if the entry policy is being
  reweighted over time.
- **Invisible work.** Weeks of reward-shaping debugging producing a policy nobody
  can inspect. For a project whose value is legibility, that is the worst ratio in
  the design.
- **Unbounded debugging time.** No reliable ceiling, and it would sit in the
  critical path near the end.

"I cut RL because sample efficiency made a validated policy unlikely at this data
volume" is a better answer than a half-working RL agent.

---

## Adaptive trust weighting was cut for v1

Tracking rolling accuracy per component and reweighting their influence sounded
like the best-value addition, but it is statistically underpowered here. Most
cycles are HOLDs and executed trades are few; distinguishing two components whose
accuracy is near 50% needs hundreds of resolved outcomes, not the ~50-decision
window originally proposed. With small N it fits noise and then acts on it, which
is worse than fixed weights.

Deferred, not abandoned. If revisited: use Bayesian shrinkage toward a prior
rather than a short rolling window, and score all decisions including HOLDs. Until
then it exists as an observability view, not a control loop.

---

## Backtest contamination is handled by anonymization

Claude's training data includes historical market commentary, so backtesting on
past periods risks the model effectively knowing what happened next. A
placebo/leakage test catches harness lookahead but **not** this — it is a property
of the model, not the pipeline.

Mitigations, in order of preference:

1. **Forward paper trading as the primary evidence.** The only test contamination
   cannot fake. Slow, and the plan must budget for the wait.
2. **Anonymize bundles fed to agents** — strip dates and ticker names, normalize
   price levels, present as "Asset A".
3. **Restrict backtests to post-cutoff data**, which drastically shrinks the
   usable window.

Any backtest number reported without addressing this is close to meaningless.

---

## Methodology commitments

- **Lock a holdout window before writing code** and do not look at it until the
  end. Iterating prompts, features, and rubrics against the same test data
  contaminates "out-of-sample" by dozens of implicit decisions.
- **Build the ablation harness before the layers it measures.** With several novel
  components, good performance is uninterpretable without knowing which part
  mattered. Planned configs: `claude_only`, `ml_only`, `no_bear`, `full`.
- **Keep a random-entry baseline permanently.** Random entries with identical
  position limits. If the debate pipeline does not beat it, that is a genuine
  finding, not a failure.
- **Benchmark against buy-and-hold too.** The reference implementation
  underperformed buy-and-hold in a bull market with honest methodology; that is the
  realistic prior.
- **Model fills conservatively.** Assume crossing the spread plus a slippage
  penalty. Mid-price fills flatter results in a way that will not survive contact
  with anything real.

---

## Relationship to the reference implementation

Roughly 70% shared architecture with the dev.to Claude crypto trading bot
(MIT-licensed): multi-agent pipeline, ML ensemble as a second opinion, structured
outputs, full logging, paper trading, dashboard, risk limits.

Genuinely different: adversarial rather than specialist agent structure;
event-driven text as a first-class asynchronous path; argument-quality scoring
decoupled from outcomes; anonymized backtesting for model contamination.

The differences are concentrated in the parts that produce findings rather than
features. Present it as building on a published design, changing the agent
structure, and running an experiment that design never ran — that framing is both
honest and stronger than claiming novelty.

Worth reading their execution layer before building ours. An afternoon there
teaches more than a week of designing from scratch, particularly about which of
their choices were forced by problems not yet encountered here.

---

## Deferred

Not cut on merit, just out of scope for v1:

- **Per-agent private track records and divergence measurement.** Give each agent
  its own history and measure whether they actually diverge over time.
- **Adversarial prompt injection testing.** Inject fake news into the text feed and
  see whether the pipeline trades on it.
- **Cross-model disagreement.** Run bull and bear across different model families
  and test whether disagreement predicts genuinely uncertain conditions.
- **Skills and subagents for repeated procedures** (e.g. "add a new agent role").
  Wait until a procedure has been done twice before encoding it.