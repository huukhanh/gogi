# gogi — 合議

*Gōgi* (合議): a decision reached by a council deliberating together, not by one person alone.

A Claude Code plugin (+ its marketplace) that turns any engineering request into a small, role-based team run: a coordinator that only coordinates, a cheap scout that reads first, a monitor that watches the clock so the coordinator never does, a dev, a tech lead, a PO/BA (the client's proxy) and investigators agree on the direction before anyone writes code, and every decision made on your behalf is tiered, logged and reported. Every agent keeps a worklog and is rotated onto a fresh context when it outgrows its budget, so long runs do not pay for bloated contexts.

## Install

```bash
# try it on one project, no install
claude --plugin-dir /path/to/gogi/plugins/gogi

# install for good (local marketplace)
/plugin marketplace add /path/to/gogi
/plugin install gogi@gogi

# or from GitHub once pushed
/plugin marketplace add huukhanh/gogi
/plugin install gogi@gogi
```

Enable per project in `.claude/settings.json` (`enabledPlugins`) or globally in `~/.claude/settings.json`.

## Upgrade

Versions are tracked in `plugins/gogi/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (both bumped together).

```bash
# installed from the GitHub marketplace
/plugin marketplace update gogi          # re-fetch the catalog so it sees the new version
/plugin update gogi@gogi                 # install it (or leave auto-update on under /plugin → Marketplaces)

# installed from a local clone
git -C /path/to/gogi pull                # get the new version
/plugin marketplace update gogi
/plugin update gogi@gogi

# loaded with --plugin-dir
git -C /path/to/gogi pull
/reload-plugins                          # picks up the new files in the running session
```

Restart or `/reload-plugins` after updating so the new agent definitions are loaded. See the changelog below for renames that affect how you address roles.

## Changelog

- **1.3.0** — *least code that works.* A shared rule (`skills/team/least-code.md`) binds every role: before anything is added, walk a stop order — not needed now → already in this repo → standard library → platform feature → installed dependency → one line → only then the least code in the fewest files — and never cut what protects users (trust-boundary validation, data-loss handling, security, accessibility, explicit asks). The techlead memo names the question each new file/abstraction/dependency cleared; the techlead review has an over-build pass (checklist H, tagged `drop/have/std/platform/installed/fold`, ending in `Removable: ~N lines`); the PO tiers cuts of requested scope as decisions; the scout records a *toolbox* (installed deps, platform, test pattern) so the questions are answered once. New `--lean lite|full|strict` level (default `full`) sets how hard the "is this needed?" question is pushed against the request itself. New **slim** intent: an over-build-only report on a diff, branch, area or the whole repo, no edits. Final reports and `PR-PRE.md` list what was *not built* and when to add it, plus every deliberate ceiling.
- **1.2.0** — the coordinator is now a pure coordinator: it never reads code, scouts, reviews or rules on content (it runs on the most expensive model). A new `gogi:scout` agent (Sonnet) goes first: fetches the ticket/PR, seeds `context.md` + `facts.md` (governing docs, gate commands, file map, precedent), drafts hypothesis lanes for investigations, and answers *explain* requests. Every agent keeps a worklog at `$RUN/agents/<name>.md` (Mission / Done / Doing / Next / Pointers / Open threads / Handoff / Generations); `session-stats.sh` reports each agent's last-turn context size and flags agents over budget (default 120k tokens or 60 turns, `GOGI_CONTEXT_BUDGET` / `GOGI_TURN_BUDGET`), and the coordinator rotates them onto a successor (`dev-2`) that resumes from the worklog. A new `gogi:monitor` agent (Sonnet) owns the heartbeat: it waits inside `watch.sh` (one Bash call, up to 9 minutes of one-minute ticks that refresh the stats and write `heartbeat.log`) and returns early only on something actionable, then wakes the coordinator with at most three lines (`rotate`, `reversal`, `frozen`, `tree moved`, `report`, `big`, `digest`, `quiet`). The coordinator no longer sleeps or reads the comms log; idle time costs no turns. Turn discipline (batch independent tool calls into one message) now binds every role. `code-comments.md` is reduced to two checks: can the code explain itself, and would deleting the comment make a wrong edit more likely; reviewers flag comments that fail.
- **1.1.0** — the `pm` role is replaced by `po` (PO / BA): one agent that analyses the ticket and then decides as the client's proxy, within the autonomy level. `gogi:pm` no longer exists; the run artifacts are `po-brief.md` and `review-po.md`. The `dev` agent now runs on Sonnet at `xhigh` effort.
- **1.0.0** — first release.

## Use

```
/gogi:team <request>                       # one entry point — classifies the intent, runs that playbook
/gogi:team --autonomy high <request>       # let the PO decide the [big] gaps too; only hard stops are asked
/gogi:team --autonomy full <request>       # never ask; every decision is logged for review in the final report
/gogi:team --lean strict <request>         # smallest thing that satisfies the ACs; everything beyond becomes a question
/gogi:team slim <diff | branch | path | repo>   # over-build report only: what can be deleted, folded, or replaced by what exists
```

Intents: implement · fix-bug · investigate · review-code · review-pr · pr-comments · breakdown · slim · explain.
Roles (agents): `gogi:scout` (reads first — Sonnet; seeds the hub, answers *explain*), `gogi:monitor` (the heartbeat — Sonnet; wakes the coordinator only with actionable events), `gogi:dev` (only one that edits code), `gogi:techlead` (how), `gogi:po` (what — PO/BA, the client's proxy: analyses, then decides), `gogi:investigator` (why). The coordinator itself never reads code or decides content.

**Context budget.** Every agent keeps `$RUN/agents/<name>.md` (what it did, is doing, will do, plus pointers into the hub). On each tick the monitor's `watch.sh` refreshes `session.md`; an agent whose last-turn context exceeds `GOGI_CONTEXT_BUDGET` (default 120000) or whose turns exceed `GOGI_TURN_BUDGET` (default 60) is reported to the coordinator, told to finish its atomic step, write a handoff and stop, and a successor (`dev-2`, …) is spawned that resumes from the worklog. Nothing is lost: facts live in `facts.md`, rulings in the binding files, messages in `comms.md`, and the worklog points at all of them.

**Autonomy** (`--autonomy`, default `low`) sets how much the team may decide without you. Every decision is tiered the same way at every level; the level only changes who answers:

| Level | `[small]` gaps | `[big]` blockers | Hard stops (destructive, data, auth/money/PII, cross-team contracts) |
|---|---|---|---|
| `low` | PO decides | you are asked | you are asked |
| `high` | PO decides | PO decides | you are asked |
| `full` | PO decides | PO decides | PO picks the safest reversible option; reported first |

Missing inputs (a repro, a log, which of two intents you meant) are still asked at every level. No level ever allows a push or a PR. A standing choice can be saved as a `[habit]` in your preferences (`When running /gogi:team → autonomy high`).

**Lean level** (`--lean`, default `full`) sets how hard the team pushes the first question of the stop order, *is this needed now?*, against the request itself. Protected things (validation at trust boundaries, data-loss handling, security, accessibility, anything you explicitly asked for) are never cut at any level.

| Level | What gets built | Who challenges the request |
|---|---|---|
| `lite` | what the ticket asks; the leaner alternative is named in the memo and the report | nobody, information only |
| `full` | only what an AC or a decision needs; every *not built* is logged with its *add when* | the PO tiers each cut of requested scope as a `[small]` or `[big]` decision |
| `strict` | the smallest thing that satisfies each AC; anything beyond is a `[big]` question, recommendation *don't* | the PO challenges the requirement itself |

## What a run leaves behind

`docs/.local/gogi/<date>-<intent>-<slug>/` in the project (git-ignored; the plugin adds `docs/.local/` to `.git/info/exclude` if needed):
`context.md` (the scout's pass) · `facts.md` (cited ledger) · `agreement.md` · `comms.md` (verbatim transcript) · `agents/*.md` (one worklog per agent, with generations) · `heartbeat.log` (one line per monitor tick) · `session.md`/`.json` (per-agent token usage, last-turn context, rotate flags, heartbeat ticks) · reports / `PR-PRE.md`.

Code changes are left **uncommitted** for review. The plugin never pushes or opens a PR.

## Learned preferences

`~/.claude/projects/<project>/memory/user-preferences.md` — `When <scene> → do <action>` rules harvested from each run; `[habit]` rules are applied without asking. Per project, compacted automatically.

## Self-contained

No other skill or plugin is required: reviews, PR triage, root-cause work and PR materials are all produced by the plugin's own roles and templates.

## Layout

```
plugins/gogi/
├── .claude-plugin/plugin.json
├── skills/team/
│   ├── SKILL.md              the coordinator (the only invocable skill)
│   ├── conventions.md        single source of truth — change a rule once here
│   ├── code-comments.md      optional convention for comments the dev writes
│   └── playbooks/            read on demand, only for the intent that runs
│       ├── implement.md      implement (full) / fix-bug (light) protocol
│       ├── investigate.md    hypothesis method, four-angle impact map, verdict rubric, report
│       ├── review.md         review checklist A–G, severity rubric, report (all reviews)
│       ├── pr-comments.md    triage VALID / NOT_VALID / discuss, reply style, report
│       ├── breakdown.md      approach comparison, design coverage, TASK-n format
│       └── pr-pre.md         PR-PRE.md template
├── agents/                   dev.md, techlead.md, po.md, investigator.md
└── scripts/                  log.sh (chronological comms log), session-stats.sh (token stats)
```

`conventions.md` binds every skill and agent; change a rule once there.
