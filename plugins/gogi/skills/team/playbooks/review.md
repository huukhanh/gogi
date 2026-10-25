# Playbook: review — checklist, severity, report

Used by `techlead` for every technical review (implement's frozen-tree review, review-code, review-pr) and by `po` for the acceptance half. `conventions.md` binds everything here.

## Ground rules

- **Read the full file, never just the hunk.** Group files by layer/area so the right rule slice applies. If the diff is too large to read fully, say so and list *fully read* vs *sampled*.
- **Cite, don't opine.** Every Critical/Important finding names a project rule (`.claude/rules/…md § section`), a concrete failure mode, or a doc requirement. Preference goes under Suggestions, labelled as such.
- **No invented findings.** A category with nothing real is omitted, not padded — except the coverage tables (*Edge cases considered*, *Impact range*, *System state & concurrency*), always present when code changed (not in `slim.md` or `review-po.md`): `none — <why>` is a verdict, an absent table is not, and *Overall* cannot be PASS while one is absent or a listed consumer has no verdict.
- **Static in a worktree** (review-pr): no builds, tests, linters, generators, migrations — no runtime, secrets or generated artifacts there; list them under *Checks not performed*. In the main checkout (implement / review-code) the gates are the dev's; the reviewer re-runs only what it needs to verify a finding.
- **Prior threads are input** (review-pr / pr-comments): don't re-raise what the author already answered or fixed.

## Checklist (skip categories with no relevant changes)

**A. Project-rule conformance (strict)** — for each file, the applicable `.claude/rules/**` / `CLAUDE.md` sections, line by line; cite file + section. No rule covers it → say so; don't substitute taste.

**B. Internal consistency of the change** — naming matches the codebase and itself across the diff · every changed signature/DTO/error/API shape has all call sites, tests, mocks, docs updated · dependency direction (imports inward only; no layer skipping; the repo's checker rules) · error handling follows the codebase pattern · schema/contract/migration/generated code agree · no dead code, debug logs, commented blocks, new TODO/FIXME · **added comments pass both checks** in `code-comments.md` (code cannot be made self-explanatory; deleting the comment would make a wrong edit more likely) and **mention nothing about the run** (no role, brief, memo, agreement, decision id, tier, `$RUN` path — in comments, test names or suggested commit messages) — a failing one is an Important finding, not a suggestion.

**C. Edge cases (reason from the code, proactively)** — for every changed function, branch and file, enumerate what it can meet, including inputs and states its own tests never exercise, and record each in *Edge cases considered*: nil/empty/zero inputs · off-by-one, boundaries, empty collections · timeouts, a slow or failing dependency · unbounded growth (memory, queues, logs, retries) · transactions (partial failure, rollback, side effects before commit, N+1) · authz (missing checks, IDOR, tenant isolation) · validation at trust boundaries · time/timezone/DST · pagination & ordering determinism · resource leaks (rows, handles, bodies, `defer cancel`) · swallowed errors · backward compatibility of API/DB changes · security (injection, XSS, SSRF, path traversal, secrets in logs). **Concurrency and parallel execution** — for every state the change reads or writes that something else can touch at the same time (memory, file, DB row, cache, queue, lock, external resource), name the concurrent actors (threads, async tasks, concurrent requests, other processes or instances, scheduled re-runs, retries, parallel agents) and reason the interleavings: check-then-act / TOCTOU · lost update on read-modify-write · double execution under retry or redelivery (idempotency) · ordering assumptions · lock order / deadlock · closure capture · cancellation or crash mid-write leaving partial state. A finding names the interleaving step by step.

**D. Tests** — proportionate to risk · failure paths, not just happy path · no flakiness sources (sleeps, real network/time, order assumptions) · fakes match real signatures · every behaviour change has a test that would catch its revert.

**E. Impact range and system state outside the diff** — **Consumers**: for every changed exported/shared symbol *and* every changed contract a consumer can rely on without importing it (API endpoint/DTO shape, UI component props, shared module, DB table/column read elsewhere, schema, config key, env var, CLI flag or output format, file path or format, event/message, default value, ordering, error type), grep consumers beyond the diff, list them, and give each a verdict on still functional and on unintended side effects (changed default, ordering, error shape, timing, new writes or output) — compiling is not working. Each is verified by a gate that ran and covers it, or by tracing it in the code; say which. Verified only at the task's own call site, or neither gated nor traced = Critical. **Side effects**: everything the change writes, sends, deletes, caches or logs beyond its return value, and which callers relied on the old behaviour. **System state**: what is left after success, after a failure midway, and when state written by the previous version (rows, files, caches, queued messages, config, names on disk) meets the new code — upgrade, rollback, old and new side by side. In a static review every trace is by reading; consumer test runs, and for each suspected race or state risk the runtime check that would confirm it (race detector, stress run, migration dry-run) with the risk it tests, go under *Checks not performed*.

**F. Reuse / duplication** — new code vs existing helpers, utils, patterns across the repo; duplicated logic with behavioural divergence is a finding.

**H. Over-build (`least-code.md`)** — a separate pass from A–G: for every added function, type, file, layer, dependency, config value and fixture, which stop-order question should have stopped it? One tagged line each — `drop:` (no AC needs it) · `have:` (a repo helper already does it) · `std:` (standard library) · `platform:` (DB/browser/framework/OS does it natively) · `installed:` (an existing dependency does it) · `fold:` (same logic, fewer lines — show the shorter form) — ranked biggest cut first, ending in `Removable: ~N lines · M files · K dependencies` or `Nothing to cut.` Important by default; Critical when a new dependency or a new layer was added for what already existed. Never flag the single check that guards the logic, and never flag what `least-code.md` protects.

**G. Doc / spec gap analysis (when a ticket, AC list, or `--docs` exists — the PO owns this in team runs)** — two-way: every requirement → traceable to code *and* a test (missing = finding); every meaningful change → covered by the doc (undocumented = scope creep / silent contract change); mismatches quoted both sides. No docs → one line saying it was skipped and which doc would have helped.

## Severity

| | Use when |
|---|---|
| **Critical / blocker** | broken or misbehaving at runtime, explicit rule violation, data leak, contradicts a stated requirement, shared-code change unverified at other consumers, a race with a concrete interleaving that loses an update, corrupts data or leaves inconsistent state — must not merge as-is |
| **Important** | works but deviates from convention, untested non-trivial logic, real unhandled edge case, quiet contract change, shared state touched by named concurrent actors with no guard (harmful interleaving plausible, not shown) — fix before merge |
| **Suggestion** | preference, micro-improvement, future-proofing — author may decline without justification |

## Report (`$RUN/review-techlead.md`, `review-po.md`, `review.md`, `review-pr.md` — or `slim.md`, which holds only the *Over-build* section, the scope line and *Files reviewed*)

```markdown
# Review: {target}   — **Overall**: PASS | NEEDS FIXES | BLOCKED
Scope: files changed / fully read / sampled · +A/−D · tests touched · migrations touched · public contract changed · worktree (if any)
Frozen tree: git status at start == at end ✔

## Critical            C1. title — Location `file:line` · Rule/source · Problem · Evidence ```…``` · Fix ```…``` · Related effects
## Important           I1. …
## Suggestions         `file:line` — one line each
## Edge cases considered   | changed file/area | cases reasoned through | verdict |     ← one row per changed file/area; makes coverage visible even when nothing is wrong
## Impact range        | changed surface | consumer (file:line) | verified by (gate / traced) | still functional | side effects |
## System state & concurrency   | (i) state & consistency · (ii) concurrency & parallel execution · (iii) stability | state / actors reasoned | finding id or none identified — <why> |
## Over-build          <file>:<line>  drop: | have: | std: | platform: | installed: | fold:  … → `Removable: ~N lines · M files · K dependencies` — or "Nothing to cut."
## Not built (from the memo/agreement) — honoured? | item | add when | status |
## Doc / spec gap      Doc→Code missing · Code→Doc undocumented · Mismatches (doc says / code does)   — or "skipped: no docs"
## Consistency         cross-file drift (naming, error mapping) — or "none"
## Done well           concrete, cited
## Checklist           | rule conformance | dependency direction | naming | error handling | validation | concurrency/tx | security | tests | schema/migration coherence | doc alignment | back-compat | dead code | → PASS/FAIL/N/A
## Checks not performed   (runtime-only: tests, lint, build, migration dry-run, generators)
## Files reviewed      | file | full / sampled | note |
```

Tone: specific over general · show code, not prose · acknowledge what's good · don't pad.
