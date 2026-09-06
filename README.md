# gogi — 合議

*Gōgi* (合議): a decision reached by a council deliberating together, not by one person alone.

A Claude Code plugin that runs any engineering request as a small team of agents with fixed roles. A scout reads first, a PO and a tech lead agree on the direction, one dev writes the code, reviewers check a frozen tree, and a coordinator that never reads code ties it together. Every decision made on your behalf is tiered, logged and reported. Small tasks skip the council; large ones get broken down first. Nothing is pushed; the diff is left for your review.

## Install

```bash
# from GitHub
/plugin marketplace add huukhanh/gogi
/plugin install gogi@gogi

# from a local clone
/plugin marketplace add /path/to/gogi
/plugin install gogi@gogi

# try on one project without installing
claude --plugin-dir /path/to/gogi/plugins/gogi
```

Enable per project in `.claude/settings.json` (`enabledPlugins`) or globally in `~/.claude/settings.json`.

**Upgrade:** `/plugin marketplace update gogi` then `/plugin update gogi@gogi` (local clone: `git pull` first; `--plugin-dir`: `git pull` then `/reload-plugins`). See [CHANGELOG.md](CHANGELOG.md) for what changed between versions.

## Use

```
/gogi:team <request>                                   # one entry point; the intent is classified for you
/gogi:team --autonomy high <request>                   # the PO decides the [big] gaps too; only hard stops are asked
/gogi:team --weight quick <request>                    # force the short path for a small change
/gogi:team --lean strict <request>                     # the smallest thing that satisfies the ACs; anything more becomes a question
/gogi:team slim <diff | branch | path | repo>          # what can be deleted, folded or replaced by what already exists
```

A request may carry a file path, a ticket URL, a PR number or a branch name. The scout fetches it.

**Intents** — implement · fix-bug · investigate · review-code · review-pr · pr-comments · breakdown · slim · explain. Each has a playbook and spawns only the roles it needs.

## Roles

| Role | Model | Does | Edits code |
|---|---|---|---|
| coordinator | your session's | classifies, spawns, relays to you, rotates agents, reports — never reads code or decides content | no |
| `gogi:scout` | Sonnet | reads first: ticket, governing docs, file map, gate commands, toolbox; confirms the weight with evidence; answers *explain* | no |
| `gogi:monitor` | Sonnet | owns the heartbeat; wakes the coordinator only with actionable events | no |
| `gogi:po` | Opus | *what*: restates ACs testably, finds gaps, tiers and decides within the autonomy level, acceptance review | no |
| `gogi:techlead` | Opus | *how*: direction memo, consults, technical + impact-range + over-build review | no |
| `gogi:investigator` | Opus | *why*: one hypothesis lane each, root cause with evidence | no |
| `gogi:dev` | Sonnet (Opus on heavy) | every code change, gates, red-then-green tests | **yes** |

## Three dials

**Weight** sizes the run. Decided per request, confirmed by the scout with evidence, overridable with `--weight`.

| Weight | Triggers | Runs as | Gates |
|---|---|---|---|
| `quick` | ≤3 files, no consumers outside them, no contract/schema/auth/money/PII, clear ACs, known cause | scout → dev → scout check; Sonnet only, no monitor, no agreement | lint, type-check, tests covering the touched files |
| `standard` | everything else | the intent's playbook | scoped to changed packages, widened to consumers of shared code |
| `heavy` | shared code used by several packages, schema/contract, several stacks, migrations | breakdown first, then each task as a full run; dev on Opus | full suite per stack + consumers, architecture checker |

**Autonomy** (`--autonomy`, default `low`) sets who answers a decision. Tiering never changes.

| Level | `[small]` | `[big]` | Hard stops (destructive, data, auth/money/PII, cross-team contracts) |
|---|---|---|---|
| `low` | PO decides | you are asked | you are asked |
| `high` | PO decides | PO decides | you are asked |
| `full` | PO decides | PO decides | PO picks the safest reversible option; reported first |

**Lean** (`--lean`, default `full`) sets how hard *is this needed now?* is pushed against the request. Protective code is never cut at any level.

| Level | Builds | Who challenges the request |
|---|---|---|
| `lite` | what the ticket asks; the leaner alternative is named | nobody, information only |
| `full` | only what an AC or a decision needs; every *not built* is logged with its *add when* | the PO tiers each cut of requested scope |
| `strict` | the smallest thing per AC; anything more is a `[big]` question | the PO challenges the requirement itself |

Missing inputs (a repro, a log, which intent you meant) are asked at every level. A standing choice can be saved as a `[habit]` in your preferences.

## Rules every role follows

- **Least code that works.** Before adding anything: not needed now → already in this repo → standard library → platform feature → installed dependency → one line → only then the minimum. Reviews end with `Removable: ~N lines`.
- **Comments pass two checks.** Can the code explain itself? Would deleting the comment make a wrong edit more likely? The run itself (roles, decisions, agreements) never appears in code, test names or commit messages.
- **Agreement before code.** The PO brief and the techlead memo are agreed by the dev before the first edit. Rulings live in files, not messages; a decision may be reversed once, on a new fact.
- **Frozen-tree reviews.** Reviews run on a tree that has stopped moving, verified by the monitor.
- **Context budget.** Every agent keeps a worklog; when its last-turn context exceeds 300k tokens (`GOGI_CONTEXT_BUDGET`) it is rotated onto a successor that resumes from the worklog.
- **One tool round-trip is the unit of cost.** Independent calls are batched into one message.
- **Git.** Never push, never open a PR. The final state is uncommitted.

## What a run leaves behind

`docs/.local/gogi/<date>-<intent>-<slug>/` in the project, git-invisible:

| File | Holds |
|---|---|
| `context.md` | the scout's pass: request, ticket, governing docs, gates, file map, toolbox |
| `facts.md` | cited facts, appended by every role |
| `agreement.md` | pointers to brief and memo, the agreed direction, what was not built |
| `comms.md` | every message, verbatim, timestamped |
| `agents/*.md` | one worklog per agent, with generations |
| `session.md` | per-agent and per-role token usage, last-turn context, rotations, heartbeat ticks |
| reports | `investigation.md`, `review-*.md`, `plan.md`, `slim.md`, `PR-PRE.md` |

Learned preferences go to `~/.claude/projects/<project>/memory/user-preferences.md` as `When <scene> → do <action>` rules; `[habit]` rules are applied without asking.

## Layout

```
plugins/gogi/
├── .claude-plugin/plugin.json
├── agents/                   scout, monitor, dev, techlead, po, investigator
├── skills/team/
│   ├── SKILL.md              the coordinator (the only invocable skill)
│   ├── conventions.md        single source of truth; change a rule once here
│   ├── least-code.md         the stop order, the lean level, the over-build review
│   ├── code-comments.md      the two checks
│   └── playbooks/            read only for the intent that runs
│       ├── quick.md          weight quick: scout → dev → check
│       ├── implement.md      full / light / heavy modes
│       ├── investigate.md    hypothesis method, impact map, verdict rubric
│       ├── review.md         checklist A–H, severity, report
│       ├── pr-comments.md    triage and reply style
│       ├── breakdown.md      approaches, design coverage, TASK-n
│       └── pr-pre.md         PR description template
└── scripts/                  log.sh (comms log), watch.sh (heartbeat), session-stats.sh (token stats)
```
