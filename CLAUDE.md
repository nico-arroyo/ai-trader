# CLAUDE.md

Adversarial multi-agent trading system. Paper trading only — no real capital, ever.

A bull agent and a bear agent argue opposing cases from identical evidence. A judge
rules and sizes. An ML model contributes a calibrated probability as evidence. A
separate evaluator grades argument quality independently of outcomes — that
measurement is the point of the project, not the P&L.

## Hard constraints

Breaking any of these silently invalidates the experiment. They are not style preferences.

- **Agents receive data, never fetch it.** No tool calls to price or news APIs from
  inside an agent. The evidence bundle is assembled, frozen, and passed by value.
- **Bull and bear receive byte-identical bundles.** If one side sees anything the
  other doesn't, the debate is rigged and every downstream measurement is meaningless.
- **The data layer takes `as_of` and cannot return rows after it.** Enforced in the
  query layer, not by convention. This kills lookahead leakage as a category.
- **Every LLM response is cached** by `hash(bundle_hash + role + prompt_version + model)`.
  Log `cache_hit` on every response row.
- **Only the cycle worker touches portfolio state.** Scheduler, ingester, and resolver
  never write it.
- **The evaluator never sees outcomes**, and nothing it produces feeds back into a
  decision. It is strictly observational.
- **The gate can shrink or veto a position, never enlarge it.** Deterministic code,
  no model call.
- **Every row traces to a `bundle_id`.** That single join key is what makes replay
  and ablation possible.

## Conventions

- Prompts are versioned files. Bump `prompt_version` on any edit — a stale cache
  after a prompt change is the bug most likely to bite.
- All timestamps UTC. No local time anywhere, including logs.
- Descriptive names over clever ones (`bear_agent_response`, not `antagonist`).
- Log JSON parse failures loudly. Never `except: pass` into a HOLD.

## Commands

```
uv run pytest              # tests
uv run ruff check .        # lint
uv run ruff format .       # format
docker compose up          # all four processes + db
```

## See also

- `docs/architecture.md` — the four processes and the nine-step cycle
- `docs/schema.md` — tables, fields, and what writes them
- `docs/decisions.md` — why the design is the way it is, and what was cut
- `docs/roadmap.md` — phases and their done-criteria

## Skill activation

<!-- Appended by setup; delete a block to stop auto-loading that skill. -->

### karpathy-guidelines

Before writing, reviewing, or refactoring any code in this repo, invoke the
`andrej-karpathy-skills:karpathy-guidelines` skill and follow its guidance
(surgical changes, no overcomplication, surface assumptions, define verifiable
success criteria). Loading it once per session is enough; re-invoke only if a
later task shifts back to code after unrelated work.

### ponytail

Before writing, adding, refactoring, fixing, or reviewing code — or choosing a
library or dependency — invoke the `ponytail:ponytail` skill (default `full`
intensity) and follow it: laziest solution that works, stdlib before custom
code, native features before dependencies, question whether the task needs to
exist. Loading it once per session is enough. The other ponytail skills
(`ponytail-audit`, `ponytail-review`, `ponytail-debt`, `ponytail-gain`,
`ponytail-help`) are one-shot commands — invoke them only when explicitly asked.

### task-observer

Before the first tool call of any session — and before writing or proposing a
plan, not merely before executing one — invoke the task-observer skill AND
execute its Session Start Protocol (storage check, frontmatter scan, review
trigger). Loading the skill and running the protocol are separate steps; a
session that loads the file and stops has activated nothing. Any turn that will
involve a tool call counts; do not classify the session as "too simple" from its
opening message.

After completing each task, check the observation records written this session
and report a one-line summary (ids and titles, or "none logged and why"). This
is the activation backstop: it forces a look at the log, so a session that
silently skipped the protocol is discovered at the first task boundary instead
of never.

Loading a skill is not complete until you have queried the observation log for
OPEN observations naming it and read their bodies:
  grep -l "skill:.*<skill-name>" \
    /Users/nicolas/Desktop/ai-trader/skill-observations/observation-log/*.md
Apply their insights to the current work, even if the skill file hasn't been
updated yet. Run this at every skill load, however many skills load in one
session.

The task-observer workspace for this project is pinned to the repo root
(project scope — this skill is installed under `.claude/skills/`):
  /Users/nicolas/Desktop/ai-trader
Every path the skill uses derives from that root and nothing else:
  /Users/nicolas/Desktop/ai-trader/skill-observations/observation-log/   (the log)
  /Users/nicolas/Desktop/ai-trader/skill-observations/cross-cutting-principles.md
  /Users/nicolas/Desktop/ai-trader/skill-updates/                        (staging root)
  /Users/nicolas/Desktop/ai-trader/skill-updates/PENDING.md              (staging manifest)
Never resolve any of them from the current working directory, and never place
the workspace inside `.claude/skills/` or any skills-discovery path.
