# Code comments — a convention for comments the dev writes

Origin: a reviewer's note that AI-authored diffs tend to comment "things the reader does not need to know", drowning the few comments that matter. The rule is repo-independent, so it lives here rather than in any one project's docs.

**Scope: this guides the comments *you add* in a diff. It is not a mandate to delete or rewrite existing comments — never touch a comment you didn't write because of this file.** Stack-agnostic; the examples happen to be TS/Vue.

## The one test

> Would deleting this comment make a later **wrong edit** more likely?

Yes → write it. No → leave it out; if it is worth saying, it goes in the PR description (`PR-PRE.md`), not the source.

The author's three conditions for a comment that passes: ① it describes the **present** (not history), ② it refers to something **referenceable** (a behaviour, a link, a rule), ③ its **scope is closed** to the code it sits on.

## Keep — three shapes

- **Framework/library behaviour invisible in the code**
  `<!-- Vuetify keeps a visited VTabsWindowItem mounted and hides it with display:none, so the inactive panel's headings stay in the document. Hence v-if on the body, not v-show. -->`
- **A deliberate rejection of the obvious alternative** — without it, someone "fixes" it back
  `// A reactive meta list, not useSeoMeta({ description }): the empty case then emits nothing by construction instead of depending on how the head library treats undefined.`
- **A suppression with its reason and upstream link**
  `// @ts-expect-error Nuxt rejects arrays of objects here even though they are JSON-serializable. See: https://github.com/nuxt/nuxt/issues/34847`

## Leave out — four shapes

- Restating the line under it (`// h2, not h1`)
- Citing where the requirement came from (`// The SEO spec makes each title a heading`)
- Narrating history (`// used to render the name twice`)
- The same paragraph pasted at N call sites — if four sites need the identical explanation, none does

## Let the name carry the purpose

A comment that says *what a thing is for* is a rename waiting to happen: `PARSE_BASE` + comment → `DUMMY_PARSE_BASE`. The reader should know the purpose from the name and the comment's first line.

## Fact first, reason separate

Open with the fact in one line. When a reason is genuinely needed, put it **at the site it protects**, prefixed `Why:` (or the repo's own marker, if it has one), in one or two lines — not woven into a narrative block on the declaration.

```ts
/** Dummy base URL used only to parse query params with new URL(). Do not use for anything else. */
const DUMMY_PARSE_BASE = "http://parse.invalid";

// Never pass the caller's origin to new URL(path, origin)
// Why: an opaque origin yields the string "null" and new URL() throws — inside router.afterEach that breaks the navigation.
const { pathname, searchParams } = new URL(fullPath, DUMMY_PARSE_BASE);
```

## Length

Default **one line**. A two-to-three-line `Why:` block where a reason is genuinely needed. Beyond that, the comment must earn its lines with a real trap plus a link; a block that reads like prose is a PR description in the wrong file.

## Always allowed (never "noise")

- A `Provisional:` comment recording a deferred decision, in whatever form the repo's `CLAUDE.md` prescribes (some repos mandate a fixed marker or a bilingual one — follow it).
- A lint/type suppression that states its reason.
- A ceiling comment naming a known limit and its upgrade path, using the repo's marker if it defines one.
