---
name: work-log
version: "3.0.0"
description: |
  Query session work logs. Hooks auto-record to ~/.claude/data/logs/ as JSONL.
  This skill queries and searches the recorded logs.
allowed-tools: Bash
---

Run the following command using Bash, passing `$ARGUMENTS` as arguments:

```
bash ${CLAUDE_PLUGIN_ROOT}/scripts/work-log.sh $ARGUMENTS
```

Output the result as-is. Do not add explanation.
If there is no output or "로그 없음", just say "로그 없음".
