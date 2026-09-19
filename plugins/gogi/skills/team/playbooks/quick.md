# Playbook: quick — a small change without the council

For implement / fix-bug runs at weight `quick` (criteria in `conventions.md § Weight`: ≤3 files, no consumer of a touched symbol outside them, no schema/contract/migration/auth/money/PII, ACs unambiguous, bug cause already known). Scout and dev on Sonnet; the `techlead` is spawned once, at the end, to check the frozen diff — on its normal Opus. No monitor, no brief, no memo, no agreement. Quality rules are unchanged: `least-code.md`, `code-comments.md`, root cause for bugs, the git rules.

## Steps

1. **Scout** (already spawned in SKILL.md Step 0) confirms `quick` with one line of evidence per criterion and writes `context.md § Change`: `file — the exact edit (before → after)` · the gate commands the touched files trigger (lint, type-check, the test files covering the module; full suite only if the repo is tiny) · what must not change. That section is the whole direction.
2. **Coordinator** spawns `dev` with `$WEIGHT quick` and a pointer to `context.md § Change`. Nothing else is spawned yet.
3. **Dev** reads conventions, `least-code.md` and `§ Change`; makes exactly that edit; runs the listed gates as one command; updates its worklog; reports in ≤10 lines — files, one line of gate output each, a suggested conventional commit message.
4. **Coordinator** spawns `techlead` (`name: techlead`, `$WEIGHT quick`, `$RUN`, pointer to `context.md § Change`) with one instruction: check the frozen diff. Spawned **now**, not at the start — the check costs one Opus spawn on a diff-sized context, not an Opus agent sitting through the build.
5. **Techlead** reads `§ Change` and the frozen diff (`git diff`, `git status --short`) — no source beyond the changed files, no re-design, no suggestions, blockers only — and replies `ok` or `blockers:` in ≤5 lines: the diff does exactly what was asked · touches nothing outside `§ Change` · the listed gates ran and the report quotes them · added comments pass the two checks and mention nothing about the run · no new dependency. It does not re-run the gates — a report that does not quote them is itself the blocker (`blockers: gates not quoted — re-run and quote`). It records `git status --short` at the start and re-checks it at the end; a moved tree voids the check.
6. Blockers → dev → check again. **Two failed rounds → re-weigh** (below).
7. **Coordinator**: harvest preferences, final report — diff summary, gates as reported, the commit message, `weight: quick` — and stop. No `PR-PRE.md`.

## Re-weigh

Any role that sees a criterion break — a consumer outside the listed files, an AC that reads two ways, a bug whose cause is not what the request says, a needed dependency, a second failed check — stops and reports `re-weigh: <evidence>`. The coordinator spawns the monitor and continues the same `$RUN` in `implement.md` light or full mode; the dev's edit so far is kept as a WIP snapshot per conventions. A `techlead` already spawned for the check continues as the run's techlead — never spawn a second one. A quick run never grows silently.
