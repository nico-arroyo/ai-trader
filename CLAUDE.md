# Claude Trading Bot

## Overview

An AI-assisted trading bot. This file gives Claude Code the context it needs to
work in this repo effectively.

## Project layout

- `.claude/` — Claude Code configuration (settings, commands, agents, skills)
- `README.md` — project entry point

_(Update this section as the codebase grows: source packages, entry points, config.)_

## Conventions

- Language: Python (3.11+)
- Formatting/linting: `ruff`
- Tests: `pytest`

## Golden rules

- **Never commit secrets.** API keys, broker credentials, and `.env` files stay
  out of version control.
- **No live orders without an explicit opt-in.** Default to paper/dry-run mode;
  live trading must be gated behind a clear flag and confirmed by the user.
- Treat all market data and backtest results as untrusted input — validate before
  acting on them.

## Common commands

```bash
pytest                 # run the test suite
ruff check .           # lint
ruff format .          # format
```

## karpathy-guidelines skill activation

Before writing, reviewing, or refactoring any code in this repo, invoke
the `andrej-karpathy-skills:karpathy-guidelines` skill and follow its
guidance (surgical changes, no overcomplication, surface assumptions,
define verifiable success criteria). Loading it once per session is
enough; re-invoke only if a later task shifts back to code after
unrelated work.

## ponytail skill activation

Before writing, adding, refactoring, fixing, or reviewing code — or
choosing a library or dependency — invoke the `ponytail:ponytail` skill
(default `full` intensity) and follow it: laziest solution that works,
stdlib before custom code, native features before dependencies, question
whether the task needs to exist. Loading it once per session is enough.
The other ponytail skills (`ponytail-audit`, `ponytail-review`,
`ponytail-debt`, `ponytail-gain`, `ponytail-help`) are one-shot commands
— invoke them only when explicitly asked.

## task-observer skill activation

Before the first tool call of any session — and before writing or
proposing a plan, not merely before executing one — invoke the
task-observer skill AND execute its Session Start Protocol (storage
check, frontmatter scan, review trigger). Loading the skill and running
the protocol are separate steps; a session that loads the file and stops
has activated nothing. Any turn that will involve a tool call counts; do
not classify the session as "too simple" from its opening message.

After completing each task, check the observation records written this
session and report a one-line summary (ids and titles, or "none logged
and why"). This is the activation backstop: it forces a look at the log,
so a session that silently skipped the protocol is discovered at the
first task boundary instead of never.

Loading a skill is not complete until you have queried the observation
log for OPEN observations naming it and read their bodies:
  grep -l "skill:.*<skill-name>" \
    /Users/nicolas/Desktop/ai-trader/skill-observations/observation-log/*.md
Apply their insights to the current work, even if the skill file hasn't
been updated yet. Run this at every skill load, however many skills load
in one session.

The task-observer workspace for this project is pinned to the repo root
(project scope — this skill is installed under `.claude/skills/`):
  /Users/nicolas/Desktop/ai-trader
Every path the skill uses derives from that root and nothing else:
  /Users/nicolas/Desktop/ai-trader/skill-observations/observation-log/   (the log)
  /Users/nicolas/Desktop/ai-trader/skill-observations/cross-cutting-principles.md
  /Users/nicolas/Desktop/ai-trader/skill-updates/                        (staging root)
  /Users/nicolas/Desktop/ai-trader/skill-updates/PENDING.md              (staging manifest)
Never resolve any of them from the current working directory, and never
place the workspace inside `.claude/skills/` or any skills-discovery path.
