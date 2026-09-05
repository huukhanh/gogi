# Playbook: breakdown — from a request to a plan the team can implement

`po` owns the behaviour half, `techlead` the technical half; they reconcile; the coordinator asks the user the `[big]` questions before the plan is final. No dev. `conventions.md` binds everything here.

## 1. Requirements (po)

Restate the goal. Fill the gaps the request leaves — surface (API / job / CLI / UI), data scope (entities, fields, relationships), constraints (performance, security, compliance), success (observable outcomes) — as **testable ACs**. Decide `[small]` gaps and record them; list `[big]` gaps as questions **with a recommendation and the tradeoff**, grouped so the coordinator can ask them in one call. At `$AUTONOMY` `high`/`full` decide them yourself (apply the recommendation, tag `[big → decided @high]`/`@full`) and list them under *Decisions*; only hard stops at `high` remain questions. Scope: explicitly in / explicitly out (follow-ups named).

## 2. Technical design (techlead)

Start from `context.md` (the scout's file map, precedent and governing docs); read the affected code, not assumptions.

- **Classify the change**: schema-only · behavioural · infra · mixed. It sets the shape of the plan.
- **Explore 2–3 approaches, lead with the recommendation**:
  - Recommended — why it fits *now* (risk, effort, compatibility with what exists)
  - Alternative A — tradeoffs · Alternative B — tradeoffs
  Ground each in a concrete file/pattern that already exists; "reuse X" beats "build Y".
- **Cover, for the recommended approach**: data model (domain + DB, migrations) · API surface (paths, methods, request/response shapes, back-compat) · validation, errors and their HTTP mapping · authz · observability (logs, metrics, counters) · testing plan (unit / integration / what proves each AC) · rollout & backward compatibility (deploy order, flags, data backfill).
- **Verify placement** of every new package/port against the repo's dependency checker and an existing sibling before writing it down.
- **When a contract changes for another team** (FE, another service, infra), add a *Collaboration needed* block: what changes, who is impacted, what input is needed — in the plan, not as a fait accompli.
- YAGNI: strike anything not required by an AC.

## 3. Reconcile

Each reads the other's half. Behaviour that is expensive → po reconsiders or escalates `[big]`. Technical choice that changes a behaviour → po's call. Disagreements are settled in the plan file, once (reversal cap applies).

## 4. Tasks

Split into implementable units in **dependency order** (bottom-up: schema/contract → domain → application → infra → adapter/UI → wiring → tests), each:

```
### TASK-n  {imperative title}                     size: S | M | L
Scope:      what this task does and does not do
Files/areas: …
Depends on: TASK-m | none
ACs covered: A1, A3
Done when:  the observable check (test name, endpoint behaviour, log line)
Risks:      …
```

Prefer tasks that ship independently; a task that cannot be verified alone is two tasks or one bigger one.

## Plan (`$RUN/plan.md`)

```markdown
# Plan: {title}
## Goal & context          — one paragraph; links to ticket/docs in context.md
## Acceptance criteria     — A1… (testable; domain terms from the ticket kept verbatim, in the ticket's language)
## Decisions               — [small] made (rationale) · [big] asked → answer
## Approach                — recommended vs alternatives, tradeoffs
## Design                  — data model · API · validation/errors · authz · observability · rollout/back-compat
## Tasks                   — TASK-1…n as above, dependency order
## Risks & open questions
## Collaboration needed    — if a contract changes for another team
```

End by offering: "say *implement TASK-n* to run the implement playbook on one task."
