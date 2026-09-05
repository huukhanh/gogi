# Code comments — the two checks

Code comments are noise by default. A comment survives only if it passes **both** checks, in order:

1. **Is the code clean enough to explain itself without it?** If not, fix the code first — rename, extract, split, reorder. A comment that explains unclear code is a rename waiting to happen (`PARSE_BASE` + comment → `DUMMY_PARSE_BASE`). Only when the code is already as clear as it can be does the comment get a second look.
2. **Would deleting the comment make a later wrong edit more likely?** If nobody would break anything by not knowing it, leave it out. Anything merely *worth saying* goes in `PR-PRE.md`, not the source.

Fail either check → no comment.

## Scope

- **Comments you add** in a diff must pass both checks.
- **Comments on lines you change**: re-check them after your edit. Stale or failing → delete; still passing → keep.
- **Comments you did not touch**: leave them. This file never licenses a sweep over untouched code.
- **Reviewers** (techlead, checklist B) flag any added comment that fails a check; it is a finding, not a preference.

## What passes check 2 — three shapes

- **Framework/library behaviour invisible in the code**
  `<!-- Vuetify keeps a visited VTabsWindowItem mounted (display:none), so the inactive panel's headings stay in the document. Hence v-if, not v-show. -->`
- **A deliberate rejection of the obvious alternative** — without it, someone "fixes" it back
  `// A reactive meta list, not useSeoMeta({ description }): the empty case then emits nothing by construction instead of depending on how the head library treats undefined.`
- **A suppression with its reason and upstream link**
  `// @ts-expect-error Nuxt rejects arrays of objects here even though they are JSON-serializable. See: https://github.com/nuxt/nuxt/issues/34847`

## What always fails

- Restating the line under it (`// h2, not h1`)
- Citing where the requirement came from (`// The SEO spec makes each title a heading`)
- Narrating history (`// used to render the name twice`)
- Section banners, `// TODO` without an owner and a ticket, commented-out code
- The same paragraph pasted at N call sites — if four sites need the identical explanation, none does

## Form, when one survives

Fact first, one line. When a reason is genuinely needed, put it **at the site it protects**, prefixed `Why:` (or the repo's own marker), in one or two lines. Beyond three lines the comment must carry a real trap plus a link, or it is a PR description in the wrong file.

```ts
/** Dummy base URL used only to parse query params with new URL(). Do not use for anything else. */
const DUMMY_PARSE_BASE = "http://parse.invalid";

// Never pass the caller's origin to new URL(path, origin)
// Why: an opaque origin yields the string "null" and new URL() throws — inside router.afterEach that breaks the navigation.
const { pathname, searchParams } = new URL(fullPath, DUMMY_PARSE_BASE);
```

## Always allowed

- A `Provisional:` comment recording a deferred decision, in the form the repo's `CLAUDE.md` prescribes.
- A lint/type suppression that states its reason.
- A ceiling comment naming a known limit and its upgrade path, in the repo's marker if it defines one.
