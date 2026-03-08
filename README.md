# session-tools

Claude Code plugin for session management: work logging, session forking, and session resuming.

## Features

### Commands

| Command | Description |
|---------|-------------|
| `/session-tools:work-log` | Query session work logs with time filters, keyword search, and multiple output formats |
| `/session-tools:ifork` | Fork current session into a new iTerm2 pane |
| `/session-tools:iresume <id>` | Resume a past session in a new iTerm2 pane with auto-directory detection |

### Hooks (auto-installed)

| Event | What it does |
|-------|-------------|
| `SessionStart` | Maps session ID to Claude PID (enables `/ifork`) |
| `UserPromptSubmit` | Logs every user prompt as JSONL |
| `PostToolUse (Skill)` | Tracks skill invocations |
| `Stop` | Prompts Claude to record a work summary |

## Requirements

- **macOS** (uses `osascript` for iTerm2 integration)
- **iTerm2** (for `ifork` and `iresume`)
- **jq** (for JSON processing)

## Installation

### From marketplace

```bash
# Add the marketplace
/plugin marketplace add welt/claude-session-tools

# Install the plugin
/plugin install session-tools@welt-claude-session-tools
```

### Local development

```bash
claude --plugin-dir ./path/to/claude-session-tools
```

## Data Storage

Logs are stored in `~/.claude/data/logs/` as individual JSONL files. Each event creates one file — no concurrency issues.

### JSONL Schema

```json
{
  "type": "input|result|skill-usage",
  "ts": "ISO 8601 timestamp",
  "session": "session_id",
  "project": "git root basename",
  "branch": "git branch name",
  "payload": { ... }
}
```

## License

MIT
