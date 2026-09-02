# Playbook: pr-comments — triage review comments, fix the approved ones

Coordinator fetches and filters; `techlead` triages (behaviour-level comments → `pm`); the user picks; `dev` applies. Nothing is ever posted to GitHub. `conventions.md` binds everything here.

## 1. Fetch (coordinator)

```bash
gh api repos/{owner}/{repo}/pulls/<N>/comments --paginate      # inline review comments
gh pr view <N> --json title,headRefName,baseRefName,reviews,comments   # review bodies + conversation
git fetch origin pull/<N>/head:pr-<N> && git worktree add .worktrees/pr-<N> pr-<N>   # if not already checked out
```

Filters from the request: `--by <login>` · `--file <path>` · `--comment <id>` · default = **all unresolved root comments**. Per comment keep: `id`, `user.login`, `path`, `line`/`original_line`, `diff_hunk`, `body`, `in_reply_to_id`, `created_at`.

- **Root comments only** — skip replies (`in_reply_to_id` set); the thread is read as context for its root.
- **Skip bot boilerplate** ("Thank you for using…", walkthrough summaries) — list them under *Skipped* with the reason. Bot *findings* (e.g. an actionable CodeRabbit item) are triaged like any other.

## 2. Triage (techlead; pm for behaviour questions)

For each root comment: read the **full file** at the current head (not the hunk), the referenced lines, and the thread. Decide:

- **VALID** — a real bug or logic error · a violation of a project rule (`.claude/rules/**`, cited) · a security concern · missing error handling / edge case · a change that genuinely improves the code.
- **NOT_VALID** — reviewer misread the code or context · conflicts with a project convention · already handled elsewhere (cite where) · style preference not backed by a rule · the suggestion would introduce another problem.
- **NEEDS DISCUSSION** — a behaviour/scope/contract question → `pm` rules (`[small]` decided, `[big]` to the user).

For VALID: what's wrong, before/after fix, related effects (other files, tests). For NOT_VALID: a **drafted reply** — 1–3 sentences, addresses the exact point, cites the rule or the code that handles it, "we" for team decisions; never dismissive ("Actually…", "You're wrong"), always acknowledges what was asked.

## 3. Decide (coordinator → user)

Show the triage table; **one `AskUserQuestion`**: which VALID fixes to apply (grouped), which replies to keep. Nothing is applied before the answer. At `$AUTONOMY` `high`/`full` skip the question: every VALID fix is applied, every NOT_VALID reply kept, and NEEDS DISCUSSION rulings follow the autonomy table (hard stops still ask at `high`); the table is shown in the final report instead.

## 4. Apply (dev), re-check (techlead)

Dev applies the approved fixes on the PR branch (in the worktree or the checkout the user names), uncommitted; consults techlead on anything architectural. Techlead does a frozen-tree impact-range check of the delta.

## Report (`$RUN/pr-comments.md`)

```markdown
# PR #{N} comments — {title}   · filter: {all | by | file | comment}
| total | valid (fixed / pending) | not valid (reply drafted) | needs discussion | skipped |

## Valid
### V1. {issue} — @{reviewer} on `file:line` · "{quoted}" · Rule: … · What's wrong · Fix (before/after) · Related effects · Status: fixed | pending
## Not valid
### N1. {concern} — @{reviewer} on `file:line` · "{quoted}" · Reason: misread | handled elsewhere | conflicts with convention | preference
   Suggested reply: > … · Evidence: …
## Needs discussion   — question · pm ruling / [big] answer
## Skipped            | id | by | file | reason |
```
