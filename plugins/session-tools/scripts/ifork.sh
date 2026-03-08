#!/bin/bash
# ifork: Fork current Claude Code session into a new iTerm2 pane
# Requires: iTerm2, macOS

set -euo pipefail

# Walk up process tree to find the claude PID
WALK_PID=$$
CLAUDE_PID=""
while [ "$WALK_PID" -gt 1 ]; do
  CMD=$(ps -p "$WALK_PID" -o comm= 2>/dev/null || true)
  if [ "$CMD" = "claude" ]; then
    CLAUDE_PID="$WALK_PID"
    break
  fi
  WALK_PID=$(ps -p "$WALK_PID" -o ppid= 2>/dev/null | tr -d ' ')
done

# Fallback: find claude by TTY
if [ -z "$CLAUDE_PID" ]; then
  MY_TTY=$(ps -p $$ -o tty= 2>/dev/null | tr -d ' ')
  if [ -n "$MY_TTY" ]; then
    CLAUDE_PID=$(ps -t "$MY_TTY" -o pid=,comm= 2>/dev/null | awk '$2=="claude"{print $1; exit}')
  fi
fi

if [ -z "$CLAUDE_PID" ]; then
  echo "ERROR: Cannot find claude process"
  exit 1
fi

# Read session ID from PID mapping (written by SessionStart hook)
SESSION_ID=$(cat "/tmp/claude_session_${CLAUDE_PID}" 2>/dev/null || true)

if [ -z "$SESSION_ID" ]; then
  echo "ERROR: No session ID for claude PID=$CLAUDE_PID"
  exit 1
fi

# Write retry wrapper script (handles concurrency if session is locked)
RETRY_SCRIPT="/tmp/claude_fork_${SESSION_ID}.sh"
cat > "$RETRY_SCRIPT" << SCRIPT
#!/bin/bash
for i in 1 2 3 4 5; do
  claude --resume $SESSION_ID --fork-session && break
  echo "Retry \$i/5: session may be locked, waiting 2s..."
  sleep 2
done
rm -f "$RETRY_SCRIPT"
SCRIPT
chmod +x "$RETRY_SCRIPT"

# Open new iTerm2 pane
osascript -e "
tell application \"iTerm2\"
    tell current session of current tab of current window
        set newSession to (split vertically with default profile)
    end tell
    tell newSession
        write text \"bash $RETRY_SCRIPT\"
    end tell
end tell"

echo "Forked session $SESSION_ID (PID=$CLAUDE_PID) into new iTerm2 pane"
