#!/usr/bin/env bash
# session-stats.sh <RUN_DIR> [SESSION_ID]
# Aggregates token usage for the current Claude Code session: the main (coordinator) transcript
# plus every subagent transcript. Writes $RUN_DIR/session.json and $RUN_DIR/session.md.
# Re-runnable: overwrites both files, so call it at every heartbeat for a live view and once at the end.
set -euo pipefail

RUN_DIR="${1:?usage: session-stats.sh <RUN_DIR> [SESSION_ID]}"
PROJ_DIR="$HOME/.claude/projects/$(pwd | sed 's#[/.]#-#g')"
[ -d "$PROJ_DIR" ] || { echo "no project transcript dir: $PROJ_DIR" >&2; exit 1; }

SESSION_ID="${2:-$(ls -t "$PROJ_DIR"/*.jsonl | head -1 | xargs -n1 basename | sed 's/\.jsonl$//')}"
MAIN="$PROJ_DIR/$SESSION_ID.jsonl"
SUB_DIR="$PROJ_DIR/$SESSION_ID/subagents"
mkdir -p "$RUN_DIR"

# One JSON object per transcript. Streaming emits several assistant records per message.id with the
# same usage, so we keep one record per id (the last one) before summing.
stats_for() { # <file> <label>
  jq -sc --arg agent_name "$2" '
    def dedupe: map(select(.type=="assistant")) | group_by(.message.id) | map(last);
    (map(select(.type=="assistant")) | first // {}) as $first
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
                          | .input.command // "" | select(test("^sleep [0-9]+"))) | length)
      }
    | .total_input_tokens = (.input_tokens + .cache_creation_tokens + .cache_read_tokens)
  ' "$1"
}

{
  stats_for "$MAIN" "coordinator"
  if [ -d "$SUB_DIR" ]; then
    for f in "$SUB_DIR"/agent-*.jsonl; do
      [ -e "$f" ] || continue
      name="$(basename "$f" .jsonl | sed -E 's/^agent-a?//; s/-[0-9a-f]{16}$//')"
      stats_for "$f" "$name"
    done
  fi
} | jq -s --arg sid "$SESSION_ID" --arg cwd "$(pwd)" --arg run "$RUN_DIR" '
  {
    session_id: $sid, cwd: $cwd, run_dir: $run,
    generated_at: (now | todate),
    branch: (map(.branch) | map(select(. != null)) | first),
    claude_code_version: (map(.version) | map(select(. != null)) | first),
    started: (map(.started) | map(select(. != null)) | min),
    ended:   (map(.ended)   | map(select(. != null)) | max),
    agents: .,
    heartbeat_ticks: (map(select(.agent=="coordinator") | .heartbeat_ticks) | add // 0),
    totals: {
      turns: (map(.turns) | add),
      input_tokens: (map(.input_tokens) | add),
      cache_creation_tokens: (map(.cache_creation_tokens) | add),
      cache_read_tokens: (map(.cache_read_tokens) | add),
      total_input_tokens: (map(.total_input_tokens) | add),
      output_tokens: (map(.output_tokens) | add),
      tool_calls: (map(.tool_calls | to_entries) | add // [] | group_by(.key) | map({key: .[0].key, value: (map(.value) | add)}) | from_entries)
    }
  }' > "$RUN_DIR/session.json"

# Markdown view
jq -r '
  def n: tostring;
  def ts: sub("\\.[0-9]+Z$"; "Z") | fromdate;
  def dur: if .started and .ended then (((.ended|ts) - (.started|ts)) / 60 | floor | tostring) + "m" else "-" end;
  "# Session stats",
  "",
  "- Session: `\(.session_id)`  ·  Claude Code \(.claude_code_version // "?")  ·  branch `\(.branch // "?")`",
  "- Window: \(.started // "?") → \(.ended // "?")  (\(dur))  ·  generated \(.generated_at)",
  "- Run dir: `\(.run_dir)`  ·  heartbeat ticks: \(.heartbeat_ticks) (expect ≈ run minutes; 0 = heartbeat was skipped)",
  "",
  "| Agent | Model | Turns | Input (fresh) | Cache write | Cache read | Total input | Output | Tool calls |",
  "|---|---|---:|---:|---:|---:|---:|---:|---|",
  (.agents[] | "| \(.agent) | \(.model // "-") | \(.turns) | \(.input_tokens|n) | \(.cache_creation_tokens|n) | \(.cache_read_tokens|n) | \(.total_input_tokens|n) | \(.output_tokens|n) | \(.tool_calls | to_entries | map("\(.key) \(.value)") | join(", ")) |"),
  (.totals | "| **all** |  | \(.turns) | \(.input_tokens|n) | \(.cache_creation_tokens|n) | \(.cache_read_tokens|n) | **\(.total_input_tokens|n)** | **\(.output_tokens|n)** | \(.tool_calls | to_entries | map("\(.key) \(.value)") | join(", ")) |"),
  "",
  "_Fresh input = uncached prompt tokens; cache write/read are prompt-cache tokens (billed at different rates). Total input = sum of the three. Streaming duplicates are deduped by message id._"
' "$RUN_DIR/session.json" > "$RUN_DIR/session.md"

echo "$RUN_DIR/session.md"
