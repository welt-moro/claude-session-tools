---
description: Resume a Claude session in a new iTerm2 pane
allowed-tools: Bash
---

Requires a full session UUID. If the user provides a partial ID (e.g. 8 chars from /work-log),
look up the full UUID from log files in `~/.claude/data/logs/` (session ID is in the filename after `_`)
before passing it to the script.

Run the following command using Bash:

```
bash ${CLAUDE_PLUGIN_ROOT}/scripts/iresume.sh <full_session_id>
```

Do not provide any additional explanation. Just execute and confirm the result.
