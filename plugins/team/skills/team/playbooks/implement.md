# Playbook: implement / fix-bug

Read by the coordinator when the intent is **implement** or **fix-bug**. `conventions.md` binds everything here; this file adds only the implement protocol. Every code change comes from `dev`; `techlead` and `pm` are read-only; only the coordinator talks to the user.

## Modes

- **Full** (implement: features, refactors, multi-AC tickets): pm + techlead + dev.
- **Light** (fix-bug: small, findable cause): dev + techlead only; memo and agreement fit in one exchange each; **PM spawned on demand** the moment a behaviour question appears. The coordinator spawns **one `team:investigator`** on the symptom *before* the dev starts (or reuses an existing investigation report); the dev fixes the root cause at the shared site, red-then-green regression test, consumer-widened gates. Review: techlead only (PM acceptance review only if a PM was spawned). **Re-classify instead of growing**: if the bug turns out to be a design flaw, needs a behaviour decision, or touches more than a handful of files, stop, report, and continue in full mode — a "small fix" never silently becomes a feature.

## Step 1 — Stack + branch

The request is already resolved and classified by the coordinator (task type: feature | bug | refactor). Detect the stack(s) the change touches from the repo layout (a single app, or several sub-projects such as a backend and a frontend — gates run per stack touched). If on the default branch, create `feat/|fix/|refactor/<slug>`. Unrelated uncommitted changes already in the tree → tell the user and ask whether to proceed (at `full`: WIP-snapshot them per conventions, proceed, and flag it in the final report).

## Step 2 — Knowledge hub + spawn

Create `$RUN = docs/.local/team/{date}-{implement|fix-bug}-{slug}/` per conventions and **seed `context.md` first** — one scout pass (an `Explore` agent or your own skim): ticket text + ACs, governing repo docs with load-bearing excerpts, a file map. Then spawn the roles for the mode **in one message** (plus the heartbeat timer in that same message), each prompt carrying `$RUN`, stack, branch, task type, mode, `$PREFS`, `$AUTONOMY`, and the instruction to start from `context.md`, extend `facts.md`, and message with pointers into the hub.

- **pm** (full) — "Produce your behaviour brief (`$RUN/pm-brief.md`, Summary ≤30 lines + appendix); send me a pointer; stay available for behaviour consults from dev and techlead."
- **techlead** — "Produce your direction memo (`$RUN/techlead-memo.md`, Summary ≤30 lines + appendix; technical only — behaviour → pm); send me a pointer; stay available for consults."
- **dev** — "Prep-read from the hub; write no code until the brief and memo are agreed — check them against your prep and agree or object with reasons. Consult techlead (how) and pm (what)."
- **investigator** (light, first) — "Root-cause this symptom; report to `$RUN/investigation.md`." Hand the report to the dev.

When the brief and memo arrive, write pointers + the key rulings into `$RUN/agreement.md` and point the dev and each other owner at it (never forward bodies). Any `[big]` question in the brief goes to the user **now**, before the agreement (at `high`/`full` the PM has already decided it in the brief — verify each is tagged with its tier and level; only hard stops at `high` still go to the user); record answers in `agreement.md`. Once agreed, write the *Agreed direction* section — that is what "done" names.

## Step 3 — Agreement → implementation

- **No code before the logged agreement** (dev agrees to both documents; pm and techlead cross-check each other's). Objections loop back to the owner. "Done" must name the agreement.
- **Build bottom-up in dependency order** — contract/schema → domain → application → infra → adapter/UI → wiring → tests — so each layer compiles against a finished one below it and the gates can run early on the lower layers.
- **Direction change** → dev stops editing; owners re-agree; PM tiers; `[big]` → **snapshot first** (WIP commit per conventions), then `AskUserQuestion` with the PM's recommendation — or, at `high`/`full`, the PM's own decision per the autonomy table; you ratify and relay.
- Stay out of consults unless the PM escalates a `[big]` — **or a decision reverses twice**. On each heartbeat tick scan new `comms.md` entries; the same topic ruled a second time is your cue: close it in `agreement.md` (both states acceptable → pick the one the dev is currently building), tell all roles it is closed, forbid re-opening. Don't wait to be asked.

## Step 4 — Done → freeze → reviews

1. Check the dev's report: gates listed with verbatim results (spot-check if vague); bug task → red-then-green evidence present.
2. **Freeze the tree** per conventions.
3. **Parallel reviews on the frozen tree**: techlead — technical + impact range → `$RUN/review-techlead.md`; pm (if present) — acceptance against the brief and logged decisions → `$RUN/review-pm.md`. Blockers → dev fixes → re-freeze → re-review only the fix; max 3 rounds, then stop and report. Suggestions/notes → final report.
4. `git reset --soft` any WIP snapshots. Tell all roles the run is complete — but keep `techlead` addressable: any code change after this point (user follow-up, merge from the default branch, migration renumber) gets a **targeted techlead re-check of the delta** before it is reported, or is recorded as *user-accepted, unreviewed*. Re-run `session-stats.sh` after every follow-up.

## Step 5 — PR-PRE

Fill `${CLAUDE_PLUGIN_ROOT}/skills/team/playbooks/pr-pre.md` from the **working tree vs the default branch** (`git diff <default> --stat`, `git diff <default>`, `git status --short` — nothing is committed, so never `<default>...HEAD`) and the agreement/decisions, and write it to `$RUN/PR-PRE.md`. If the repo has a PR template (`.github/**/PULL_REQUEST_TEMPLATE*.md`), follow its section order.

## Step 6 — Standing habits, harvest, final report, stop

Run the `[habit]` steps `$PREFS` lists for "after implementation" (e.g. merge the default branch + renumber migrations, broad smoke-test for batch/DB features) — each is a post-review change, so it gets the techlead delta re-check. **Harvest** new preferences into `$PREFS`. Then the final report per conventions, plus: what changed (file list, one line each) · gates · consults + rulings · **decisions made on your behalf** · techlead review (blockers fixed, open suggestions) · PM acceptance (AC coverage, scope drift, notes) · open questions · PR-PRE content + path · **session stats** totals · `$RUN` · next step: "review the diff; when happy, open the PR yourself". Then do nothing further.
