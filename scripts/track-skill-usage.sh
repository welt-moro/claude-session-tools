#!/bin/bash
# PostToolUse hook: Skill tool invocation tracking

INPUT=$(cat)

SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill_name // .tool_input.skill // empty')
[ -z "$SKILL" ] && exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
PROJECT=$(basename "$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")")

TS=$(date +%Y-%m-%dT%H:%M:%S%z)
TS_FILE=$(date +%Y-%m-%dT%H-%M-%S)

LOG_DIR="$HOME/.claude/data/logs"
mkdir -p "$LOG_DIR"

# Reconstruct command from skill name + args
SKILL_ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // empty')
if [ -n "$SKILL_ARGS" ]; then
  COMMAND="/${SKILL} ${SKILL_ARGS}"
else
  COMMAND="/${SKILL}"
fi

jq -n -c \
  --arg type "skill-usage" \
  --arg ts "$TS" \
  --arg session "$SESSION_ID" \
  --arg project "$PROJECT" \
  --arg branch "$BRANCH" \
  --arg skill "/$SKILL" \
  --arg command "$COMMAND" \
  '{type: $type, ts: $ts, session: $session, project: $project, branch: $branch, payload: {skill: $skill, command: $command}}' \
  > "$LOG_DIR/${TS_FILE}_${SESSION_ID}_skill.jsonl"

exit 0
