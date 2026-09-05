# PR-PRE template

Copy-paste-ready PR materials for an **uncommitted** working tree. Fill every section from the real diff (`git diff <default-branch>`, `git status --short`) and the run's `agreement.md`; never from memory. If the repo ships a PR template under `.github/`, keep its section order and put this content into it.

```markdown
# <type>(<scope>): <imperative title, ≤70 chars>
<!-- type: feat | fix | refactor | docs | chore | test · scope: the area / package / app the repo's commit history uses -->

## Description
<2–4 sentences: what changes for the user/system and why. Link the ticket. No implementation narrative.>

## Summary of Changes
- <one bullet per logical change, grouped by layer/area; name the key files>
- …

## Decisions worth knowing
<!-- from agreement.md: [small] decisions and [big] answers a reviewer would otherwise question; deviations from repo docs, stated plainly -->
- …

## Impacted areas / blast radius
<!-- from the techlead's impact-range check: shared symbols changed + their consumers outside the diff -->
- …

## How it was verified
- Gates: <build / lint / architecture check / type-check / scoped tests — verbatim pass/fail>
- Tests added: <list; for bug fixes, the red-then-green regression test>
- Manual / smoke: <what was exercised, against what data>

## Not built / follow-ups
<!-- from agreement.md's not-built list: each requested-or-tempting thing left out, what covers it today, when to add it; plus known gaps, provisional decisions, infra tickets, and every deliberate ceiling marked in the code -->
- <item — covered by … — add when …>

## Suggested commit messages
<!-- conventional commits, one per logical unit; no task-id suffixes, no co-author trailers; if existing commits are already well-structured, reuse them -->
1. `<type>(<scope>): …`
2. …

## Branch name
<!-- only if the current branch breaks the repo's convention ({type}/{short-kebab}); otherwise omit this section -->
Suggested: `<type>/<slug>` — `git branch -m <current> <suggested>`
```
