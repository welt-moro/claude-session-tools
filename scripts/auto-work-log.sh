#!/bin/bash
# Stop hook: session work log
# Claude fills in domain/kind/summary via prompt output

GUARD="/tmp/claude-work-log-guard"

# Loop guard: skip if triggered within last 30s
if [ -f "$GUARD" ]; then
  age=$(($(date +%s) - $(stat -f %m "$GUARD")))
  if [ "$age" -lt 30 ]; then
    rm -f "$GUARD"
    exit 0
  fi
fi
touch "$GUARD"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
PROJECT=$(basename "$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")")

NOW_DATE=$(date +%Y-%m-%d)
NOW_TIME=$(date +%H:%M)
TS=$(date +%Y-%m-%dT%H:%M:%S%z)
TS_FILE=$(date +%Y-%m-%dT%H-%M-%S)

LOG_DIR="$HOME/.claude/data/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${TS_FILE}_${SESSION_ID}_result.jsonl"

cat <<EOF
[WORK-LOG] 세션 작업을 기록하세요.

작업이 없었으면 (잡담/질문만) 기록하지 말고 "기록할 작업 없음"만 출력하세요.

대화 전체를 분석하여 아래 Bash 명령을 실행하세요:

jq -n -c \\
  --arg type "result" \\
  --arg ts "$TS" \\
  --arg session "$SESSION_ID" \\
  --arg project "$PROJECT" \\
  --arg branch "$BRANCH" \\
  --arg domain "분석한_도메인" \\
  --arg kind "bug-fix|feature|refactor|plan|docs|config|test|deploy" \\
  --arg summary "세션 전체 작업 한줄 요약 (한국어)" \\
  '{type: \$type, ts: \$ts, session: \$session, project: \$project, branch: \$branch, payload: {domain: \$domain, kind: \$kind, summary: \$summary}}' \\
  > "$LOG_FILE"
EOF
