# gogi — 合議

*Gōgi* (合議): a decision reached by a council deliberating together, not by one person alone.

A Claude Code plugin (+ its marketplace) that turns any engineering request into a small, role-based team run: a coordinator, a dev, a tech lead, a PO/BA (the client's proxy) and investigators agree on the direction before anyone writes code, and every decision made on your behalf is tiered, logged and reported.

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

- **1.1.0** — the `pm` role is replaced by `po` (PO / BA): one agent that analyses the ticket and then decides as the client's proxy, within the autonomy level. `gogi:pm` no longer exists; the run artifacts are `po-brief.md` and `review-po.md`. The `dev` agent now runs on Sonnet at `xhigh` effort.
- **1.0.0** — first release.

## Use

```
/gogi:team <request>                       # one entry point — classifies the intent, runs that playbook
/gogi:team --autonomy high <request>       # let the PO decide the [big] gaps too; only hard stops are asked
/gogi:team --autonomy full <request>       # never ask; every decision is logged for review in the final report
```

Intents: implement · fix-bug · investigate · review-code · review-pr · pr-comments · breakdown · explain.
Roles (agents): `gogi:dev` (only one that edits code), `gogi:techlead` (how), `gogi:po` (what — PO/BA, the client's proxy: analyses, then decides), `gogi:investigator` (why).

**Autonomy** (`--autonomy`, default `low`) sets how much the team may decide without you. Every decision is tiered the same way at every level; the level only changes who answers:

| Level | `[small]` gaps | `[big]` blockers | Hard stops (destructive, data, auth/money/PII, cross-team contracts) |
|---|---|---|---|
| `low` | PO decides | you are asked | you are asked |
| `high` | PO decides | PO decides | you are asked |
| `full` | PO decides | PO decides | PO picks the safest reversible option; reported first |

Missing inputs (a repro, a log, which of two intents you meant) are still asked at every level. No level ever allows a push or a PR. A standing choice can be saved as a `[habit]` in your preferences (`When running /gogi:team → autonomy high`).

## What a run leaves behind

`docs/.local/gogi/<date>-<intent>-<slug>/` in the project (git-ignored; the plugin adds `docs/.local/` to `.git/info/exclude` if needed):
`context.md` (scout pass) · `facts.md` (cited ledger) · `agreement.md` · `comms.md` (verbatim transcript) · `session.md`/`.json` (per-agent token usage) · reports / `PR-PRE.md`.

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
