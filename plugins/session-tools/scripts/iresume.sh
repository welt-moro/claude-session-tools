#!/bin/bash
# iresume: Resume a Claude session in a new iTerm2 pane
# Automatically detects the project directory from log files.
# Requires: iTerm2, macOS

set -euo pipefail

SESSION_ID="${1:-}"
LOGS_DIR="$HOME/.claude/data/logs"

if [ -z "$SESSION_ID" ]; then
  echo "Usage: iresume <session_id>"
  echo "Get session IDs from /session-tools:work-log"
  exit 1
fi

# Extract directory from the most recent log file for this session
PROJECT_DIR=""
LOG_FILE=$(ls -t "$LOGS_DIR"/*"$SESSION_ID"*.jsonl 2>/dev/null | head -1)
if [ -n "$LOG_FILE" ]; then
  CWD=$(head -1 "$LOG_FILE" | jq -r '.cwd // empty' 2>/dev/null)
  if [ -n "$CWD" ] && [ -d "$CWD" ]; then
    PROJECT_DIR="$CWD"
  fi
fi

# Build the command: cd if directory found, then resume
if [ -n "$PROJECT_DIR" ]; then
  RESUME_CMD="cd $PROJECT_DIR && claude --resume $SESSION_ID"
  echo "Project directory: $PROJECT_DIR"
else
  RESUME_CMD="claude --resume $SESSION_ID"
  echo "Warning: Could not detect project directory. Resuming in current directory."
fi

# Open new iTerm2 pane and resume session
osascript -e "
tell application \"iTerm2\"
    tell current session of current tab of current window
        set newSession to (split vertically with default profile)
    end tell
    tell newSession
        write text \"$RESUME_CMD\"
    end tell
end tell"

echo "Resumed session $SESSION_ID in new iTerm2 pane"
