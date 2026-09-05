# Playbook: investigate — method, impact mapping, report

Used by `investigator` agents (method + report) and by the coordinator (intake flags, adjudication). `conventions.md` binds everything here.

## Intake (scout, on the coordinator's behalf)

The request may carry hints; the **scout** parses them into `context.md § Request` and drafts the `## Hypothesis lanes` (2–3, one line each: family · starting file · falsifying observation) the coordinator spawns investigators on. The coordinator never reads the entry points itself.

| Flag / phrase | Meaning | How it is treated |
|---|---|---|
| `--hint "<text>"` / "I think it's X" | the user's guess | a **prior, not a conclusion**: investigate it first, but explicitly test ≥2 alternatives before agreeing; if wrong, say so and why |
| `--logs <paths>` | log files / pastes | grep the error + timestamps; capture the **first** occurrence and any correlation ids; cross-reference ids into code |
| `--repro "<cmd>"` | a reproducer | run only if read-only/side-effect-free; otherwise report it as *proposed, not run* |
| `--scope <paths>` | narrow the area | restrict greps/reads there first; expand only if the trail leads out |
| `--since <ref/date>` | recency window | bound `git log` to it (default: last 30 days / 50 commits) |

Too vague to frame ("it's broken") → the scout tags a `[user]` question; the coordinator asks it with one `AskUserQuestion` before spawning any investigator.

## Method (investigator)

1. **Frame**: observed / expected / when-where (always? env? data slice?) / recency / hint verbatim / open questions (not blockers).
2. **Evidence, read-only first**: `git log --oneline -50` (+`--since`), `git status`/`diff`, `rg` the symbol and the error text verbatim, read implicated files **in full**, `git log -S`/`blame` the divergent lines.
3. **Hypotheses — 5–8, including boring ones**, each with a **falsification test** ("if true, I should see X at Y"). Standard families: recent change · unhandled input/data shape · race / ordering / retry / idempotency · config or env drift · external dependency behaviour · time / timezone / locale / encoding · caching or stale state · migration / schema vs code mismatch.
4. **Diagnostics**: read-only commands, static analyzers (`go vet`, `eslint --no-fix`, `tsc --noEmit`), local read-only queries. **Never** builds/tests/migrations/network/writes — if one is the only way to decide, list it under *proposed, not run* with the hypothesis it would test.
5. **Narrow**: mark each hypothesis **Confirmed / Refuted / Open** with the citation. Stop when exactly one is Confirmed and the rest Refuted — or when only user input (repro, prod log, env check) can separate the last 2–3. Traps: confirming the hint without ruling out alternatives; finding *a* bug and assuming it's *the* bug; stopping at the symptom ("nil pointer") instead of *why*.
6. **Map the impact — four angles, each answered or "none identified"**:
   - **Same-bug surface**: other sites sharing the cause (same anti-pattern, same input class, same commit) → *must fix now* or *follow-up*.
   - **Downstream callers / features**: who routes through the broken code; same symptom, different symptom, or masked.
   - **Data impact**: bad rows written/skipped? how to identify them (a query *shape*, not a prod query); recoverable (retry/backfill) or lost; damage ongoing or bounded. Read-path-only → say so in one line.
   - **Fix side-effects**: cohorts relying on the broken behaviour, tests codifying it, callers catching the current error, contract changes, migration ordering, back-compat window.
7. **Fix direction**: the smallest change **at the shared site**, before/after snippet, why it fixes it (tie to the falsification test), regression risk, how to verify (a test that fails before / passes after). Must cover every *must fix now* item.

## Verdict and confidence

| Verdict | When |
|---|---|
| **ROOT CAUSE FOUND** | one hypothesis Confirmed by direct evidence; alternatives Refuted |
| **2 / 3 CANDIDATES** | that many remain Open; ranked, each with the observation that would separate them |
| **INSUFFICIENT EVIDENCE** | framing too vague or no diagnostics available — ask for a repro/log and stop |

Confidence **high** = traced to a line/data/config, reproduced or matched to a log, alternatives ruled out · **medium** = well-supported but one key piece (live repro, prod log, DB state) missing · **low** = code reading only; treat the fix as exploratory.

## Report (`$RUN/investigation.md`; append a dated `## Investigation — YYYY-MM-DD` section if it exists)

```markdown
# Investigation: {title}
**Verdict**: … · **Confidence**: … · **Branch/commit**: … · **Lane**: {hypothesis owned, if parallel}

## Issue framing            — symptom quoted, restated; observed / expected / when-where / recency / hint / repro / logs
## What was investigated    — files read (path — why); commands run (cmd — purpose — 1-line result); proposed-not-run
## Hypotheses               — | # | hypothesis | falsification test | verdict | evidence (file:line / log / commit) |
## Root cause  (or: Top candidates, max 3)
   cause · why it manifests exactly as described · 3–5 step trace from entry to the failing line
## Affected / impact        — same-bug surface · downstream callers · data impact · fix side-effects · summary table (must fix now / coordinate / watch)
## Fix direction            — where · before/after · why it fixes it · side-effects · verification
## Confidence notes         — why this level; what would raise it; what would lower it
## Open questions           — for the user (the coordinator asks; the investigator never does)
```

Style: lead with the cause, not the journey · cite, don't claim · show the failure path as a trace · symptom ≠ cause · be specific about uncertainty.
