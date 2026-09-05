# Least code that works — the stop order

Every line the team writes must be paid for: read, reviewed, tested, kept working, and re-sent as context on every later turn. So the default answer to "should we build this?" is *no*, and the burden of proof is on the code. This rule binds every role; `conventions.md` points here.

## Understand first, then cut

This rule makes the **change** smaller; it never makes the **investigation** smaller. The stop order runs after the hub has been read and the real flow traced end to end (every caller, not just the file the request names). A tiny diff in the wrong place is not lean, it is a second bug. The dev's root-cause rule (fix once, at the shared site all callers route through) is this rule applied to bugs: one guard in the shared function is less code than a guard per caller.

## The stop order

For each thing you are about to add — a function, a type, a file, a layer, a dependency, a config value, a test fixture — walk down and **stop at the first question that answers yes**:

| # | Question | If yes |
|---|---|---|
| 1 | Is it needed by an AC or an agreed decision *now*? No → | drop it; say so in one line (`not built: X — add when Y`) |
| 2 | Does this repo already have it — a helper, type, pattern, precedent? | reuse it; `context.md § Precedent` and `§ Toolbox` are where to look first |
| 3 | Does the language's standard library do it? | use it |
| 4 | Does the platform do it natively — the database (constraint, index), the browser (`<input type=date>`, CSS), the framework, the OS? | use it |
| 5 | Does a dependency **already installed** do it? | use it |
| 6 | Can it be one line where you are? | one line |
| 7 | None of the above | write the least code that passes the check, in the fewest files |

Two questions both hold → take the higher one. Never add a dependency for what a few lines cover; a **new dependency** is only ever question 7 with a written reason in the memo Summary.

## What is never built without being asked

- An interface, base class or port with one implementation; a factory for one product; a registry with one entry.
- Configuration for a value that does not change; feature flags for a feature that ships on.
- A wrapper that only delegates; a "utils" file for one caller; a layer whose only job is to call the next one.
- Scaffolding "for later", generic parameters "in case", error hierarchies for one error.
- Test infrastructure the repo does not already use: new fixtures, factories, mocking frameworks, per-function suites. Tests follow the repo's own pattern and cover the behaviour change (dev rules: red-then-green for bugs), nothing wider.

Prefer removing to adding, the obvious construct to the ingenious one, and one touched file to three. When the request itself asks for something a smaller thing covers, that is a **scope question for the PO**, not a silent cut and not a silent build (below).

## What is never cut

Validation at trust boundaries · error handling that prevents data loss or corruption · authorization, secrets handling, injection defences · accessibility basics · observability the repo's rules require · anything the ticket or the user explicitly asks for · correctness on edge cases (between two equally short options, take the one that is right on the boundary case). Leanness is about less code, never a weaker algorithm.

## Deliberate ceilings

When you knowingly ship the simpler thing with a known limit (a global lock, a linear scan, a heuristic that covers today's data), mark it at the site with the repo's ceiling marker if it defines one, otherwise one line naming the limit and the upgrade path — this is one of the comment shapes `code-comments.md` always allows. The final report lists every ceiling.

## Lean level — `$LEAN`

Like `$AUTONOMY`, every run carries `$LEAN` ∈ `lite | full | strict` (from `--lean`, a phrase in the request — "keep it minimal" / "do less" → `strict`, "build it as specified" → `lite` —, a `[habit]` in `$PREFS`, else **`full`**). It changes how hard question 1 is pushed, never what is protected:

| Level | Question 1 | Who challenges the request |
|---|---|---|
| **lite** | build what the ticket asks; the techlead names the leaner alternative in the memo, the final report lists it | nobody — information only |
| **full** (default) | build only what an AC or decision needs; every "not built" is logged with its "add when" | the PO tiers each cut of *requested* scope as a decision (`[small]` when the smaller thing plainly covers the AC, else `[big]`) |
| **strict** | the smallest thing that satisfies the AC ships first; anything beyond is a `[big]` question with the recommendation *don't* | the PO challenges the requirement itself: "AC-3 is covered by X; do you still need Y?" |

At every level the memo names, per new file/abstraction/dependency, the stop-order question it cleared; the review flags anything that did not.

## Reviewing for over-build (techlead, checklist H)

A separate pass from correctness. One line per finding, tagged with the question that should have stopped it:

```
<file>:<line>  drop:      not needed by any AC — <what>. Replace with nothing.
<file>:<line>  have:      <repo helper> already does this. Use it.
<file>:<line>  std:       <stdlib call> does this. Use it.
<file>:<line>  platform:  <native feature> does this. Use it.
<file>:<line>  installed: <existing dependency> does this. Use it.
<file>:<line>  fold:      same logic in <n> lines: <the shorter form>.
```

End with the only number that matters: `Removable: ~N lines · M files · K dependencies` — or `Nothing to cut.` Findings are Important by default (Critical when a new dependency or a new layer was added for what existed). A single check that guards the logic is never flagged as over-build. Correctness, security and performance findings go in the other sections, not here.

## Output discipline

Code first, then at most three lines: what was not built and when to add it. If justifying a simplification takes more text than the simplification saved, the justification is the new bloat; the exception is what the user or the playbook explicitly asks for (a report, the PR description, the brief).
