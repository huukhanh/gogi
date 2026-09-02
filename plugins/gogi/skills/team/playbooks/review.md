# Playbook: review — checklist, severity, report

Used by `techlead` for every technical review (implement's frozen-tree review, review-code, review-pr) and by `po` for the acceptance half. `conventions.md` binds everything here.

## Ground rules

- **Read the full file, never just the hunk.** Group files by layer/area so the right rule slice applies. If the diff is too large to read fully, say so and list *fully read* vs *sampled*.
- **Cite, don't opine.** Every Critical/Important finding names a project rule (`.claude/rules/…md § section`), a concrete failure mode, or a doc requirement. Preference goes under Suggestions, labelled as such.
- **No invented findings.** A category with nothing real is omitted, not padded.
- **Static in a worktree** (review-pr): no builds, tests, linters, generators, migrations — no runtime, secrets or generated artifacts there; list them under *Checks not performed*. In the main checkout (implement / review-code) the gates are the dev's; the reviewer re-runs only what it needs to verify a finding.
- **Prior threads are input** (review-pr / pr-comments): don't re-raise what the author already answered or fixed.

## Checklist (skip categories with no relevant changes)

**A. Project-rule conformance (strict)** — for each file, the applicable `.claude/rules/**` / `CLAUDE.md` sections, line by line; cite file + section. No rule covers it → say so; don't substitute taste.

**B. Internal consistency of the change** — naming matches the codebase and itself across the diff · every changed signature/DTO/error/API shape has all call sites, tests, mocks, docs updated · dependency direction (imports inward only; no layer skipping; the repo's checker rules) · error handling follows the codebase pattern · schema/contract/migration/generated code agree · no dead code, debug logs, commented blocks, new TODO/FIXME.

**C. Edge cases (reason from the code)** — nil/empty/zero inputs · off-by-one, boundaries, empty collections · concurrency (shared state, locks, closure capture, cancellation) · transactions (partial failure, rollback, side effects before commit, N+1) · authz (missing checks, IDOR, tenant isolation) · validation at trust boundaries · time/timezone/DST · pagination & ordering determinism · resource leaks (rows, handles, bodies, `defer cancel`) · swallowed errors · backward compatibility of API/DB changes · security (injection, XSS, SSRF, path traversal, secrets in logs).

**D. Tests** — proportionate to risk · failure paths, not just happy path · no flakiness sources (sleeps, real network/time, order assumptions) · fakes match real signatures · every behaviour change has a test that would catch its revert.

**E. Impact range outside the diff** — for every changed exported/shared symbol, grep consumers beyond the diff and confirm each still behaves; list them. Verified only at the task's own call site = Critical.

**F. Reuse / duplication** — new code vs existing helpers, utils, patterns across the repo; duplicated logic with behavioural divergence is a finding.

**G. Doc / spec gap analysis (when a ticket, AC list, or `--docs` exists — the PO owns this in team runs)** — two-way: every requirement → traceable to code *and* a test (missing = finding); every meaningful change → covered by the doc (undocumented = scope creep / silent contract change); mismatches quoted both sides. No docs → one line saying it was skipped and which doc would have helped.

## Severity

| | Use when |
|---|---|
| **Critical / blocker** | broken or misbehaving at runtime, explicit rule violation, data leak, contradicts a stated requirement, shared-code change unverified at other consumers — must not merge as-is |
| **Important** | works but deviates from convention, untested non-trivial logic, real unhandled edge case, quiet contract change — fix before merge |
| **Suggestion** | preference, micro-improvement, future-proofing — author may decline without justification |

## Report (`$RUN/review-techlead.md`, `review-po.md`, `review.md`, or `review-pr.md`)

```markdown
# Review: {target}   — **Overall**: PASS | NEEDS FIXES | BLOCKED
Scope: files changed / fully read / sampled · +A/−D · tests touched · migrations touched · public contract changed · worktree (if any)
Frozen tree: git status at start == at end ✔

## Critical            C1. title — Location `file:line` · Rule/source · Problem · Evidence ```…``` · Fix ```…``` · Related effects
## Important           I1. …
## Suggestions         `file:line` — one line each
## Edge cases considered   | area/file | cases reasoned through | verdict |     ← makes coverage visible even when nothing is wrong
## Impact range        | changed symbol | consumers checked (file:line) | result |
## Doc / spec gap      Doc→Code missing · Code→Doc undocumented · Mismatches (doc says / code does)   — or "skipped: no docs"
## Consistency         cross-file drift (naming, error mapping) — or "none"
## Done well           concrete, cited
## Checklist           | rule conformance | dependency direction | naming | error handling | validation | concurrency/tx | security | tests | schema/migration coherence | doc alignment | back-compat | dead code | → PASS/FAIL/N/A
## Checks not performed   (runtime-only: tests, lint, build, migration dry-run, generators)
## Files reviewed      | file | full / sampled | note |
```

Tone: specific over general · show code, not prose · acknowledge what's good · don't pad.
