# Gōgi conventions — single source of truth

Every team agent (`dev`, `techlead`, `po`, `investigator`) reads this file first. The `gogi:team` skill and every playbook under `skills/team/playbooks/` follow it. Role files and playbooks contain only what is specific to them; if something here conflicts with a role file, this file wins.

## Roles and ownership

| Role | Owns | Edits code? |
|---|---|---|
| **coordinator** (the skill run) | understanding the request, picking the playbook, spawning roles, relaying to/from the user, final report | no |
| **dev** | every code change; quality gates; tests | **yes — the only one** |
| **techlead** | *how*: architecture, placement, patterns, dependencies, schema shape, gates, impact range | no |
| **po** (PO / BA — the client's proxy) | *what*: analyses the ticket, ACs, business rules and precedent, then decides defaults, edge-case behaviour, scope, ship tradeoffs within the autonomy level | no |
| **investigator** | *why*: root cause with evidence and confidence | no |

**Spawning:** agents are plugin-scoped — `subagent_type: "gogi:dev" | "gogi:techlead" | "gogi:po" | "gogi:investigator"`; always pass `name:` (`dev`, `techlead`, `po`, `investigator-N`) so SendMessage and the comms log use the plain role names. Cross-domain questions go to the owner. PO and techlead consult each other (cost ↔ desired behaviour); neither rules in the other's domain. The dev asks whichever role owns the question; a mixed question goes to the PO, who gets cost from the techlead first. Roles are spawned only when the playbook needs them or a need appears mid-run.

## Decisions: `[small]` vs `[big]`

The PO tiers every behaviour/scope decision. **`[small]`** — localised, cheap to reverse, no auth/money/PII semantics (wording, ordering, a default matching precedent, a log field): decided now with a one-line rationale, logged, listed in the final report under *"Decisions made on your behalf — review"*. **`[big]`** — direction, scope change, contract shape (endpoint/DTO/DB column), auth/visibility, money/PII, discarding substantial finished work, ship-now-with-deviation vs wait: formulated with a recommendation and sent to the coordinator, who asks the user via `AskUserQuestion` **before anyone acts**. Unsure → `[big]`. **Only the coordinator talks to the user.**

### Autonomy level — how much the team may decide alone

Every run carries `$AUTONOMY` ∈ `low | high | full` (from `--autonomy`, a phrase in the request, a `[habit]` in `$PREFS`, else **`low`**). The coordinator states it in the opening line and passes it to every spawned role. It changes *who answers* a decision, never the tiering, the logging, or the git rules:

| Level | `[small]` | `[big]` | Hard stops |
|---|---|---|---|
| **low** (default) | PO decides, logs | user is asked before anyone acts | user is asked |
| **high** | PO decides, logs | **PO decides** — applies its own recommendation, logs it tagged `[big → decided @high]` | user is asked |
| **full** | PO decides, logs | PO decides, logs | **PO decides the safest reversible option**, logs it tagged `[hard-stop → decided @full]`, and the final report opens with these |

**Hard stops** (the only things `high` still asks about): discarding or reverting substantial finished work · anything that deletes or rewrites data (destructive migrations, backfills, resets) · auth / visibility / money / PII semantics · a contract change consumed by another team or service · a scope change that adds a new user-facing surface the request did not name.

At every level: a decision the owner takes on the user's behalf is written into the binding file with its tier, the level it was decided under, and a one-line rationale, and appears in the final report under *"Decisions made on your behalf — review"* (grouped `[small]` / `[big]` / hard stops). Autonomy governs **decisions**, not **missing inputs**: a run that cannot proceed without something only the user holds (a repro, a log, a credential, which of two intents was meant) still asks — or stops and reports — at any level. `git push` / opening a PR never become allowed.
**A ruling exists only in its binding file.** Decisions are *made by editing* the binding artifact (`agreement.md`, the memo, the brief) and *announced* with a pointer — `"memo §7 updated: per-stage line"` plus at most two lines. A ruling stated in a message but absent from the file is void; a reader who finds message and file disagreeing follows the file and says so. Never edit the file and describe a different state in a message. (Observed failure: memo and messages diverged → five reversals of one `[small]` decision in 25 minutes, zero code change.)

**Reversal cap.** A decision may be reversed **once**, and only on a *new fact* (a citation, a measured cost, a rule) — never on re-weighing the same tradeoff. A second reversal on the same topic is not made by the owner: it goes to the coordinator, who closes the topic in `agreement.md` (either state is acceptable when both satisfy the ACs — the cost of churn exceeds the difference) and no role re-opens it. The coordinator watches `comms.md` for the same topic recurring and steps in at the second reversal without being asked.

## Direction documents: summary + appendix

The PO brief and the techlead memo each open with **`## Summary` — at most 30 lines** — followed by numbered appendix sections (full SQL, file lists, test lists, template text). Other roles read the Summary by default and open an appendix section only when pointed at it (`memo §3`). The Summary is what the agreement is made on; an appendix section that contradicts the Summary is a bug in the document. Rulings that change a document update **both** the Summary line and the section, and mark the superseded text rather than deleting it.

## Agreement before code

Direction documents (PO brief, techlead memo) are proposals. The dev checks them against their own prep reading and replies with explicit agreement or objections with reasons; PO and techlead cross-check each other's document. Work starts only on a logged agreement, and "done" names it. A direction change re-enters the same handshake: the dev **stops editing immediately**, the owners re-agree, the coordinator ratifies (PO tiers it; `[big]` → user). Snapshot before any pivot (below).

## Consults

Blocking = stop and wait (anything architectural, any unanswered behaviour question). Non-blocking = state the default you proceed with. One consult, one decision: the answer is applied; disagree once with a reason, then follow it. Never guess a behaviour or contract — the PO decides or escalates.

## Git rules

- Never `git push`, never open a PR. The final code state is **uncommitted** for the user's review.
- **WIP snapshot commits** are the one exception: before any pivot, revert, or deletion of more than trivial work, `git add -A && git commit -m "wip(gogi): <label> snapshot"` — untracked files deleted without one are unrecoverable. The coordinator `git reset --soft`s all snapshots before the final report.
- Branch creation is fine (feature branch off the default branch if currently on it).

## Frozen-tree reviews

No review starts until the dev confirms "stopped editing" and `git status --short` + `git diff --stat` are identical across one heartbeat tick. Reviewers record `git status --short` at start and re-check at end; a moved tree voids the review — stop, report, re-freeze, restart. The dev makes no edits while a review is running.

## Skill policy

Only this plugin's skills (`gogi:*`) and user-level skills (`~/.claude/skills/`) may be invoked. Project-defined skills are never invoked; a project's rules are **read as files** (root `CLAUDE.md`, nested `CLAUDE.md`s in sub-projects, `.claude/rules/**`) — skip what doesn't exist, never invent rules.

The plugin is **self-contained**: every deliverable (reports, plans, `PR-PRE.md`, investigations) is produced by its own roles and written into `$RUN`, never into a tracked `docs/` path that would dirty the reviewable diff. PR worktrees live at `.worktrees/pr-<N>` and are kept until the user asks to remove them.

## User preferences (project memory — learn the user's habits)

`$PREFS = ~/.claude/projects/$(pwd | sed 's#[/.]#-#g')/memory/user-preferences.md` — a compact, project-scoped list of `When <scene> → do <action>` rules distilled from what the user has asked for, corrected, or decided before. It is part of Claude Code's per-project memory, so the main session already has it; **the coordinator and the PO read it at the start of every run** and pass `$PREFS` to every spawned role.

- **Apply, don't re-ask.** A `[habit]` rule (seen ≥2× or stated as standing) is executed proactively and listed in the final report under *"applied from your preferences"*. A `[once]` rule is done with a note, or offered. A `[big]` question whose answer is already a recorded `[habit]` is **downgraded**: apply the habit, record it, don't ask. A `[small]` default is chosen to match recorded preferences first, repo precedent second.
- **Harvest at the end of every run** (coordinator, before the final report): read `comms.md` for every `user →` entry and every `[big]` answer, plus any correction the user made mid-run, and turn each into a candidate rule — *the scene that triggered it, generalised one level* (not "add the missing index on orders.customer_id" but "when a comment names a known limit and its small upgrade, ship the upgrade"). Merge into `$PREFS`: an existing rule seen again → bump its count / promote `[once]` → `[habit]`; a contradiction → demote to `[once]` and flag it in the report for the user to settle; a new scene → new `[once]` line. Show the diff of `$PREFS` in the final report so the user can veto a wrong lesson.
- **Keep it usable**: under ~60 lines; one line per rule; merge duplicates; generalise two instances into one; drop `[once]` older than 60 days at harvest time. It is a rule list, not a diary — details belong in the run directory.
- Never store secrets, credentials, or personal data about third parties in it.

## Knowledge hub (the run directory)

One directory per run, inside the project, git-invisible: `docs/.local/gogi/{YYYY-MM-DD}-{intent}-{slug}/` (`git check-ignore docs/.local/` — if not ignored, add `docs/.local/` to `.git/info/exclude`, never to the tracked `.gitignore`). The coordinator creates it and passes the path (`$RUN`) to every agent. It exists so that **each file is read once by one agent and reused by all** — never let three roles cold-read the same twenty files.

| File | Written by | Purpose |
|---|---|---|
| `context.md` | coordinator, **before spawning** (one scout pass: `Explore`-style skim of the area) | request/ticket text, ACs, stack, branch, the repo docs that govern this area with their load-bearing excerpts, a file map of the touched area (`path — one line what it is`) |
| `facts.md` | every agent, append-only | verified facts with `file:line` citations — `- [role HH:MM] user_settings.reminder_enabled exists, bool default false — migrations/0001_init.sql:42` |
| `agreement.md` | coordinator | the PO brief, the techlead memo, objections, and the **current agreed direction** (updated on every re-agreement; a superseded section is marked, not deleted) |
| `comms.md` | every agent | the message log (below) |
| `session.md` / `session.json` | coordinator, via script | session id, branch, Claude Code version, time window, and **per-agent + total token usage** (fresh input / cache write / cache read / output), turns, tool-call counts |
| reports, plans, `PR-PRE.md` | the producing role | deliverables |

**Ledger discipline.** Before opening a source file, check `facts.md` and `context.md`. A cited fact may be used without re-reading — **except** when it decides a blocker, a `[big]` question, or a ruling; then open the citation and confirm (a wrong ledger entry must not propagate into a decision). Append every fact you establish that another role could need; never append an uncited fact. Start your prep from `context.md`, not from a cold grep.

**Pointers, not bodies.** When the content of a message already lives in a hub file (brief, memo, report, agreement), the message carries the pointer (`agreement.md § Memo`) plus a two-line summary — not the body. The hub holds the single verbatim copy; recipients read it once.

## Comms log

`$RUN/comms.md`. **Every agent logs every message it sends, verbatim, never summarised**, immediately before or after the SendMessage — **only** through the helper, never by hand:

```bash
printf '%s\n' "<the full message>" | ${CLAUDE_PLUGIN_ROOT}/scripts/log.sh "$RUN" <sender> <recipient[,recipient]> "<kind>"
# roles: coordinator | dev | techlead | po | investigator-N | user | all
# kinds: brief | memo | consult | answer | "decision [small]" | "decision [big]" | question-relay | review | report | status
```

The helper stamps the **current wall clock** itself and rejects unknown role names, so the log is chronological and the roster is consistent (no `team-lead`/`main`/`orchestrator` variants). Hand-written entries are a rule violation. This append is the **only write** a read-only role ever makes.

## Session stats

Agents cannot see their own token usage, so the coordinator collects it from the transcripts on disk: `${CLAUDE_PLUGIN_ROOT}/scripts/session-stats.sh "$RUN"` reads the session's main transcript and every `subagents/agent-*.jsonl`, dedupes streaming duplicates by message id, and writes `$RUN/session.json` + `$RUN/session.md` (per-agent rows named after the `name:` given at spawn, plus totals). Run it **on every heartbeat tick** (live view, cheap — one jq pass) and **once more at the very end** before the final report; quote the totals line in the final report. Agent rows appear only after that agent has produced its first message.

## Heartbeat (mandatory, verified)

The coordinator starts the timer **in the same message as the spawns** — `Bash("sleep 60", run_in_background: true)` — and restarts it on every tick until the run completes. Each tick: check `git status --short` + `git diff --stat` deltas and messages received, refresh `session.md`, and:
- **something changed** → print a 1–3 line progress report to the user (what moved, consults/decisions since last tick, running token total);
- **nothing changed** → print one line (`⏱ 12m — quiet; dev likely running gates`) — no analysis, no re-reading.
Three quiet ticks → ask the dev for a one-line status. Never interrupt the dev otherwise. Also on each tick: scan new `comms.md` entries for a **reversal loop** (same topic decided twice) and arbitrate per the reversal cap.

The heartbeat is **verified**: `session-stats.sh` counts the coordinator's `sleep` calls and prints `heartbeat ticks` in `session.md`; the final report quotes it. A run of N minutes with far fewer than N ticks means the protocol was skipped — say so in the report rather than hiding it. (Observed failure: a 60-minute run with 0 ticks; the user saw no progress at all.)

## Read-only roles' hard rules

`techlead`, `po`, `investigator`: never edit, create, or delete project files; never run state-changing commands (no commit/push, installs, migrations, writes); read-only Bash only. Sole exception: the comms-log append. Never message the user — the channel is the coordinator (and teammates).

## After the reviews: follow-up changes

Any code change made **after** the frozen-tree reviews (a user follow-up, a merge from the default branch, a renumbered migration) gets a **targeted techlead re-check of just the delta** — one message, read-only, blockers only — before it is reported as done. If the user explicitly waives it, the final report records the change as *"user-accepted, unreviewed"*. Re-run `session-stats.sh` at the end of every follow-up so `session.md` covers the whole session, and log the follow-up's messages like any other.

## Final report

The coordinator ends every run with one message: the deliverable (inline or path), gates if code changed, consults and rulings, decisions made on the user's behalf (grouped by tier; hard stops decided under `full` first), **rules applied from `$PREFS` and the harvest diff (new / promoted / contradicted rules)**, open questions, the session totals line from `session.md` (input / output tokens, per-agent breakdown available in the file), the run directory `$RUN` (transcript in `comms.md`), and the single next step the user can say to continue — then stops.
