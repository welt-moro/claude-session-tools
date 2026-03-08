#!/bin/bash
# UserPromptSubmit hook: log user input to individual JSONL file

INPUT=$(cat)

USER_PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
[ -z "$USER_PROMPT" ] && exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
PROJECT=$(basename "$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")")

TS=$(date +%Y-%m-%dT%H:%M:%S%z)
TS_FILE=$(date +%Y-%m-%dT%H-%M-%S)

LOG_DIR="$HOME/.claude/data/logs"
mkdir -p "$LOG_DIR"

jq -n -c \
  --arg type "input" \
  --arg ts "$TS" \
  --arg session "$SESSION_ID" \
  --arg project "$PROJECT" \
  --arg branch "$BRANCH" \
  --arg cwd "$CWD" \
  --arg prompt "$USER_PROMPT" \
  '{type: $type, ts: $ts, session: $session, project: $project, branch: $branch, cwd: $cwd, payload: {prompt: $prompt}}' \
  > "$LOG_DIR/${TS_FILE}_${SESSION_ID}.jsonl"

exit 0
