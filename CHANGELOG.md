# Changelog

Versions are tracked in `plugins/gogi/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` and `skills/team/SKILL.md`, bumped together.

## 1.4.1

- The run never appears in code: comments, test names and suggested commit messages may not mention a role, brief, memo, agreement, decision id, tier, level or run path (`code-comments.md`). `Provisional:` and ceiling comments state the assumption or limit only. Reviewers and the quick check treat a violation as a finding.

## 1.4.0

- **Weight.** Every implement / fix-bug run is sized `quick | standard | heavy` (`--weight`, else from the request, confirmed by the scout with evidence: file count, consumer grep, contract touch).
- *Quick* (a label, a constant, a config value, a one-liner with a known cause: ≤3 files, no external consumers, no contract/schema/auth/money/PII, no open behaviour question) runs scout → dev → scout check on Sonnet only, no monitor, no brief/memo/agreement, gates limited to what the touched files trigger, and ends with a diff plus a commit message. Own playbook: `playbooks/quick.md`.
- *Heavy* (shared code with consumers in several packages, schema/contract, several stacks, migrations) runs breakdown first, then each task as a full implement with the dev on Opus and full-suite gates.
- Any role that sees a criterion break says `re-weigh` and the coordinator moves the run up.

## 1.3.1

- Rotation budget is 300k last-turn context tokens per agent (`GOGI_CONTEXT_BUDGET`, was 120k); the turn-count budget is removed.
- `session.md` rows are named from the spawn name (via the transcript's `.meta.json`); every spawned agent keeps its row for the whole session; a per-role table sums all generations of a rotated role.

## 1.3.0

- **Least code that works** (`skills/team/least-code.md`) binds every role: before anything is added, walk a stop order — not needed now → already in this repo → standard library → platform feature → installed dependency → one line → only then the least code in the fewest files — and never cut what protects users.
- The techlead memo names the question each new file/abstraction/dependency cleared; the techlead review has an over-build pass (checklist H, tagged `drop/have/std/platform/installed/fold`, ending in `Removable: ~N lines`); the PO tiers cuts of requested scope as decisions; the scout records a *toolbox* (installed deps, platform, test pattern).
- New `--lean lite|full|strict` level (default `full`). New **slim** intent: an over-build-only report on a diff, branch, area or repo, no edits. Final reports and `PR-PRE.md` list what was *not built* and every deliberate ceiling.

## 1.2.0

- The coordinator is a pure coordinator: it never reads code, scouts, reviews or rules on content.
- New `gogi:scout` agent (Sonnet) goes first: fetches the ticket/PR, seeds `context.md` + `facts.md`, drafts hypothesis lanes for investigations, answers *explain* requests.
- Every agent keeps a worklog at `$RUN/agents/<name>.md`; `session-stats.sh` reports each agent's last-turn context and flags agents over budget; the coordinator rotates them onto a successor (`dev-2`) that resumes from the worklog.
- New `gogi:monitor` agent (Sonnet) owns the heartbeat via `watch.sh` (one Bash call, one-minute ticks, up to 9 minutes) and wakes the coordinator only with actionable events (`rotate`, `reversal`, `frozen`, `tree moved`, `report`, `big`, `digest`, `quiet`). Idle time costs no turns.
- Turn discipline (batch independent tool calls into one message) binds every role. `code-comments.md` reduced to two checks.

## 1.1.0

- The `pm` role is replaced by `po` (PO / BA): analyses the ticket, then decides as the client's proxy within the autonomy level. Run artifacts are `po-brief.md` and `review-po.md`. The `dev` agent runs on Sonnet at `xhigh` effort.

## 1.0.0

- First release.
