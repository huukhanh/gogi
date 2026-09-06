#!/usr/bin/env bash
# session-stats.sh <RUN_DIR> [SESSION_ID]
# Aggregates token usage for the current Claude Code session (main transcript + every subagent transcript)
# into $RUN_DIR/session.json and $RUN_DIR/session.md. Overwrites both, so it can run on every heartbeat.
# GOGI_CONTEXT_BUDGET sets the per-agent rotation threshold on last-turn context (conventions § Context budget).
set -euo pipefail

RUN_DIR="${1:?usage: session-stats.sh <RUN_DIR> [SESSION_ID]}"
CONTEXT_BUDGET="${GOGI_CONTEXT_BUDGET:-300000}"
HB_TICKS="$( [ -f "$RUN_DIR/heartbeat.log" ] && wc -l < "$RUN_DIR/heartbeat.log" | tr -d ' ' || echo 0 )"
PROJ_DIR="${GOGI_PROJ_DIR:-$HOME/.claude/projects/$(pwd | sed 's#[/.]#-#g')}"
[ -d "$PROJ_DIR" ] || { echo "no project transcript dir: $PROJ_DIR" >&2; exit 1; }

SESSION_ID="${2:-$(ls -t "$PROJ_DIR"/*.jsonl | head -1 | xargs -n1 basename | sed 's/\.jsonl$//')}"
MAIN="$PROJ_DIR/$SESSION_ID.jsonl"
SUB_DIR="$PROJ_DIR/$SESSION_ID/subagents"
mkdir -p "$RUN_DIR"

# One JSON object per transcript. Streaming emits several assistant records per message.id with the
# same usage, so we keep one record per id (the last one) before summing.
stats_for() { # <file> <label>
  jq -sc --arg agent_name "$2" --argjson ctx_budget "$CONTEXT_BUDGET" '
    def dedupe: map(select(.type=="assistant")) | group_by(.message.id) | map(last);
    def ctx_of: (.message.usage.input_tokens // 0) + (.message.usage.cache_creation_input_tokens // 0) + (.message.usage.cache_read_input_tokens // 0);
    (map(select(.type=="assistant")) | first // {}) as $first
    | (map(select(.type=="assistant" and (ctx_of > 0))) | last // {}) as $last
    | (dedupe) as $msgs
    | {
        agent: $agent_name,
        model: ($first.message.model // null),
        version: ($first.version // null),
        branch: ($first.gitBranch // null),
        started: (map(.timestamp) | map(select(. != null)) | min),
        ended:   (map(.timestamp) | map(select(. != null)) | max),
        turns: ($msgs | length),
        input_tokens:          ($msgs | map(.message.usage.input_tokens // 0) | add // 0),
        cache_creation_tokens: ($msgs | map(.message.usage.cache_creation_input_tokens // 0) | add // 0),
        cache_read_tokens:     ($msgs | map(.message.usage.cache_read_input_tokens // 0) | add // 0),
        output_tokens:         ($msgs | map(.message.usage.output_tokens // 0) | add // 0),
        tool_calls: ($msgs | map(.message.content[]? | select(.type=="tool_use") | .name)
                     | group_by(.) | map({key: .[0], value: length}) | from_entries),
        heartbeat_ticks: ($msgs | map(.message.content[]? | select(.type=="tool_use" and .name=="Bash")
                          | .input.command // "" | select(test("^sleep [0-9]+"))) | length),
        context_tokens: ($last | if . == {} then 0 else ctx_of end)
      }
    | .total_input_tokens = (.input_tokens + .cache_creation_tokens + .cache_read_tokens)
    | .rotate = (.agent != "coordinator" and .context_tokens >= $ctx_budget)
  ' "$1"
}

{
  stats_for "$MAIN" "coordinator"
  if [ -d "$SUB_DIR" ]; then
    for f in "$SUB_DIR"/agent-*.jsonl; do
      [ -e "$f" ] || continue
      meta="${f%.jsonl}.meta.json"
      id="$(basename "$f" .jsonl | sed -E 's/^agent-a?//')"
      name="$( [ -f "$meta" ] && jq -r --arg id "${id: -8}" '.name // (.agentType + "@" + $id)' "$meta" || echo "$id" )"
      stats_for "$f" "$name"
    done
  fi
} | jq -s --arg sid "$SESSION_ID" --arg cwd "$(pwd)" --arg run "$RUN_DIR" --argjson ctx_budget "$CONTEXT_BUDGET" --argjson hb_ticks "$HB_TICKS" '
  (map(.agent)) as $names
  | def lineage(n): (n | sub("-[0-9]+$"; "")) as $p
      | if (n | test("-[0-9]+$")) and ($names | index($p)) != null then lineage($p) else n end;
  def successor_re(a): "^" + (a | gsub("(?<c>[.^$*+?()\\[\\]{}|])"; "\\" + .c)) + "-[0-9]+$";
  (map(. + { lineage: lineage(.agent),
             superseded: (.agent as $a | $names | map(select(test(successor_re($a)))) | length > 0) })
   | map(.rotate = (.rotate and (.superseded | not)))) as $agents
  | {
    session_id: $sid, cwd: $cwd, run_dir: $run,
    generated_at: (now | todate),
    branch: (map(.branch) | map(select(. != null)) | first),
    claude_code_version: (map(.version) | map(select(. != null)) | first),
    started: (map(.started) | map(select(. != null)) | min),
    ended:   (map(.ended)   | map(select(. != null)) | max),
    agents: $agents,
    context_budget: $ctx_budget,
    rotate: ($agents | map(select(.rotate) | .agent)),
    heartbeat_ticks: (if $hb_ticks > 0 then $hb_ticks else (map(select(.agent=="coordinator") | .heartbeat_ticks) | add // 0) end),
    totals: {
      turns: (map(.turns) | add),
      input_tokens: (map(.input_tokens) | add),
      cache_creation_tokens: (map(.cache_creation_tokens) | add),
      cache_read_tokens: (map(.cache_read_tokens) | add),
      total_input_tokens: (map(.total_input_tokens) | add),
      output_tokens: (map(.output_tokens) | add),
      tool_calls: (map(.tool_calls | to_entries) | add // [] | group_by(.key) | map({key: .[0].key, value: (map(.value) | add)}) | from_entries)
    },
    lineages: ($agents | group_by(.lineage) | map(sort_by(.started)) | map({
      lineage: .[0].lineage,
      generations: (map(.agent) | join(" → ")),
      count: length,
      turns: (map(.turns) | add),
      total_input_tokens: (map(.total_input_tokens) | add),
      output_tokens: (map(.output_tokens) | add)
    }) | map(select(.count > 1)))
  }' > "$RUN_DIR/session.json"

jq -r '
  def n: tostring;
  def ts: sub("\\.[0-9]+Z$"; "Z") | fromdate;
  def dur: if .started and .ended then (((.ended|ts) - (.started|ts)) / 60 | floor | tostring) + "m" else "-" end;
  "# Session stats",
  "",
  "- Session: `\(.session_id)`  ·  Claude Code \(.claude_code_version // "?")  ·  branch `\(.branch // "?")`",
  "- Window: \(.started // "?") → \(.ended // "?")  (\(dur))  ·  generated \(.generated_at)",
  "- Run dir: `\(.run_dir)`  ·  heartbeat ticks: \(.heartbeat_ticks) (monitor watch.sh ticks from heartbeat.log; expect ≈ run minutes; 0 = no monitor ran)",
  "- Budget: \(.context_budget) context tokens per agent (last turn)  ·  **rotate now: \(if (.rotate|length) > 0 then (.rotate|join(", ")) else "none" end)**",
  "",
  "| Agent | Model | Turns | Context (last turn) | Input (fresh) | Cache write | Cache read | Total input | Output | Tool calls |",
  "|---|---|---:|---:|---:|---:|---:|---:|---:|---|",
  (.agents[] | "| \(.agent)\(if .superseded then " (rotated)" else "" end) | \(.model // "-") | \(.turns) | \(.context_tokens|n)\(if .rotate then " ⚠ rotate" else "" end) | \(.input_tokens|n) | \(.cache_creation_tokens|n) | \(.cache_read_tokens|n) | \(.total_input_tokens|n) | \(.output_tokens|n) | \(.tool_calls | to_entries | map("\(.key) \(.value)") | join(", ")) |"),
  (.totals | "| **all** |  | \(.turns) |  | \(.input_tokens|n) | \(.cache_creation_tokens|n) | \(.cache_read_tokens|n) | **\(.total_input_tokens|n)** | **\(.output_tokens|n)** | \(.tool_calls | to_entries | map("\(.key) \(.value)") | join(", ")) |"),
  (if (.lineages | length) > 0 then
    "",
    "**Per role across generations** (rows of rotated agents are never merged or overwritten; this is their sum)",
    "",
    "| Role | Generations | Turns | Total input | Output |",
    "|---|---|---:|---:|---:|",
    (.lineages[] | "| \(.lineage) | \(.generations) | \(.turns) | \(.total_input_tokens|n) | \(.output_tokens|n) |")
  else empty end),
  "",
  "_Every spawned agent keeps its own row for the whole session, finished or not; all token columns are sums over all its turns. Context = total input of the most recent turn of that agent (what every further turn re-sends). Fresh input = uncached prompt tokens; cache write/read are prompt-cache tokens. Total input = sum of the three, over all turns. Streaming duplicates are deduped by message id._"
' "$RUN_DIR/session.json" > "$RUN_DIR/session.md"

echo "$RUN_DIR/session.md"
