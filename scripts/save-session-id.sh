#!/bin/bash
# SessionStart hook: Save session ID mapped to Claude PID for /ifork
# Phase 1: Immediately save session_id from stdin
# Phase 2: Background process fixes for forked sessions

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')

if [ "$SESSION_ID" = "unknown" ]; then
  exit 0
fi

CLAUDE_PID=$PPID
echo "$SESSION_ID" > "/tmp/claude_session_${CLAUDE_PID}"

# Background: wait for jsonl to be created, then fix with real session ID
(
  sleep 3
  PROJECT_DIR=$(echo "$CWD" | sed 's|^/||; s|/|-|g')
  SESSION_DIR="$HOME/.claude/projects/-${PROJECT_DIR}"

  # Find jsonl files created within last 10 seconds
  NOW=$(date +%s)
  BEST_FILE=""
  BEST_DIFF=999999
  for f in "$SESSION_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    BIRTH=$(stat -f "%B" "$f" 2>/dev/null)
    DIFF=$((NOW - BIRTH))
    if [ "$DIFF" -ge 0 ] && [ "$DIFF" -lt 10 ] && [ "$DIFF" -lt "$BEST_DIFF" ]; then
      BEST_DIFF=$DIFF
      BEST_FILE=$f
    fi
  done

  if [ -n "$BEST_FILE" ]; then
    REAL_ID=$(basename "$BEST_FILE" .jsonl)
    echo "$REAL_ID" > "/tmp/claude_session_${CLAUDE_PID}"
  fi
) &
disown
