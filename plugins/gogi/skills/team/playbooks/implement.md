# Playbook: implement / fix-bug

Read by the coordinator when the intent is **implement** or **fix-bug**. `conventions.md` binds everything here; this file adds only the implement protocol. Every code change comes from `dev`; `techlead` and `po` are read-only; only the coordinator talks to the user.

## Modes

- **Full** (implement: features, refactors, multi-AC tickets): po + techlead + dev.
- **Light** (fix-bug: small, findable cause): dev + techlead only; memo and agreement fit in one exchange each; **PO spawned on demand** the moment a behaviour question appears. The coordinator spawns **one `gogi:investigator`** on the symptom *before* the dev starts (or reuses an existing investigation report); the dev fixes the root cause at the shared site, red-then-green regression test, consumer-widened gates. Review: techlead only (PO acceptance review only if a PO was spawned). **Re-classify instead of growing**: if the bug turns out to be a design flaw, needs a behaviour decision, or touches more than a handful of files, stop, report, and continue in full mode — a "small fix" never silently becomes a feature.

## Step 1 — Stack + branch

The request is already resolved and classified by the coordinator (task type: feature | bug | refactor). Detect the stack(s) the change touches from the repo layout (a single app, or several sub-projects such as a backend and a frontend — gates run per stack touched). If on the default branch, create `feat/|fix/|refactor/<slug>`. Unrelated uncommitted changes already in the tree → tell the user and ask whether to proceed (at `full`: WIP-snapshot them per conventions, proceed, and flag it in the final report).

## Step 2 — Knowledge hub + spawn

`$RUN` exists and the **scout has already seeded `context.md`** (ticket text + ACs, governing docs with load-bearing excerpts, gate commands, file map, precedent, tagged open questions) and `facts.md` — SKILL.md Step 0. You do not read the code yourself. Spawn the roles for the mode **in one message** (the monitor is already running from Step 0), each prompt carrying `$RUN`, stack, branch, task type, mode, `$PREFS`, `$AUTONOMY`, `$LEAN`, and the instruction to start from `context.md`, extend `facts.md`, keep `$RUN/agents/<name>.md`, and message with pointers into the hub.

- **po** (full) — "Produce your behaviour brief (`$RUN/po-brief.md`, Summary ≤30 lines + appendix; tier every cut of requested scope per `least-code.md` at `$LEAN`); send me a pointer; stay available for behaviour consults from dev and techlead."
- **techlead** — "Produce your direction memo (`$RUN/techlead-memo.md`, Summary ≤30 lines + appendix; technical only — behaviour → po; every new file/abstraction/dependency with the `least-code.md` question it cleared; *not built* list); send me a pointer; stay available for consults."
- **dev** — "Prep-read from the hub; write no code until the brief and memo are agreed — check them against your prep and agree or object with reasons. Consult techlead (how) and po (what)."
- **investigator** (light, first) — "Root-cause this symptom along the lane in `context.md § Hypothesis lanes`; report to `$RUN/investigation.md`." Hand the report's pointer to the dev.

When the brief and memo arrive, write pointers + the key rulings + the combined **not built** list into `$RUN/agreement.md` and point the dev and each other owner at it (never forward bodies). Any `[big]` question in the brief goes to the user **now**, before the agreement (at `high`/`full` the PO has already decided it in the brief — verify each is tagged with its tier and level; only hard stops at `high` still go to the user); record answers in `agreement.md`. Once agreed, write the *Agreed direction* section — that is what "done" names.

## Step 3 — Agreement → implementation

- **No code before the logged agreement** (dev agrees to both documents; po and techlead cross-check each other's). Objections loop back to the owner. "Done" must name the agreement.
- **Build bottom-up in dependency order** — contract/schema → domain → application → infra → adapter/UI → wiring → tests — so each layer compiles against a finished one below it and the gates can run early on the lower layers.
- **Direction change** → dev stops editing; owners re-agree; PO tiers; `[big]` → **snapshot first** (WIP commit per conventions), then `AskUserQuestion` with the PO's recommendation — or, at `high`/`full`, the PO's own decision per the autonomy table; you ratify and relay.
- Stay out of consults unless the PO escalates a `[big]` — **or a decision reverses twice**. The monitor reads every new `comms.md` entry and reports `reversal — <topic>` with both citations; that is your cue: close it in `agreement.md` (both states acceptable → pick the one the dev is currently building — you do not weigh the arguments), tell all roles it is closed, forbid re-opening. Don't wait to be asked.
- **Rotate on budget.** The monitor reports `rotate <agent>` when `session.md` flags one; run the rotation protocol (conventions § Context budget). The dev is the usual candidate on long builds — rotate it between layers, never mid-edit; a successor `dev-2` resumes from `agents/dev.md`. Re-address the other roles in the same message.

## Step 4 — Done → freeze → reviews

1. Check the dev's report: gates listed with results (if vague, ask the dev to re-run and quote — never run or read them yourself); bug task → red-then-green evidence present.
2. **Freeze the tree** per conventions: tell the monitor `phase: freeze`; it reports `frozen` after one unchanged tick. Then `phase: review`.
3. **Parallel reviews on the frozen tree**: techlead — technical + impact range → `$RUN/review-techlead.md`; po (if present) — acceptance against the brief and logged decisions → `$RUN/review-po.md`. Blockers → dev fixes → re-freeze → re-review only the fix; max 3 rounds, then stop and report. Suggestions/notes → final report.
4. `git reset --soft` any WIP snapshots. Tell all roles the run is complete — but keep `techlead` addressable: any code change after this point (user follow-up, merge from the default branch, migration renumber) gets a **targeted techlead re-check of the delta** before it is reported, or is recorded as *user-accepted, unreviewed*. Re-run `session-stats.sh` after every follow-up.

## Step 5 — PR-PRE

Fill `${CLAUDE_PLUGIN_ROOT}/skills/team/playbooks/pr-pre.md` from the **working tree vs the default branch** (`git diff <default> --stat`, `git diff <default>`, `git status --short` — nothing is committed, so never `<default>...HEAD`) and the agreement/decisions, and write it to `$RUN/PR-PRE.md`. If the repo has a PR template (`.github/**/PULL_REQUEST_TEMPLATE*.md`), follow its section order.

## Step 6 — Standing habits, harvest, final report, stop

Run the `[habit]` steps `$PREFS` lists for "after implementation" (e.g. merge the default branch + renumber migrations, broad smoke-test for batch/DB features) — each is a post-review change, so it gets the techlead delta re-check. **Harvest** new preferences into `$PREFS`. Then the final report per conventions, plus: what changed (file list, one line each) · gates · consults + rulings · **decisions made on your behalf** · **not built / add when** + ceilings marked · techlead review (blockers fixed, open suggestions, `Removable:` line) · PO acceptance (AC coverage, scope drift, notes) · open questions · PR-PRE content + path · **session stats** totals · `$RUN` · next step: "review the diff; when happy, open the PR yourself". Then do nothing further.
