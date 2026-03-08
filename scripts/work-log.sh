#!/bin/bash
# work-log: Query work logs from ~/.claude/data/logs/
# Usage: bash work-log.sh [action] [args...] [--full|--scroll]

set -euo pipefail

LOG_DIR="$HOME/.claude/data/logs"

if [ ! -d "$LOG_DIR" ] || [ -z "$(ls "$LOG_DIR"/*.jsonl 2>/dev/null)" ]; then
  echo "로그 없음"
  exit 0
fi

# Parse flags from all arguments
MODE="compact"  # compact | full | scroll
GREP_KW=""
ARGS=()
i=1
for arg in "$@"; do
  case "$arg" in
    --full)  MODE="full" ;;
    --scroll) MODE="scroll" ;;
    *)       ARGS+=("$arg") ;;
  esac
done

ACTION="${ARGS[0]:-}"
ARG="${ARGS[1]:-}"
ARG3="${ARGS[2]:-}"
ARG4="${ARGS[3]:-}"

# Determine grep keyword
if [ "$ACTION" = "grep" ]; then
  GREP_KW="$ARG"
elif [ "$ARG" = "grep" ] && [ -n "$ARG3" ]; then
  GREP_KW="$ARG3"
elif [ "$ARG3" = "grep" ] && [ -n "$ARG4" ]; then
  GREP_KW="$ARG4"
fi

# --- Formatters ---

format_compact() {
  jq -r '
    sort_by(.ts) | reverse |
    ["| 시각 | 세션 | 디렉토리 | 입력 |",
     "|------|------|---------|------|"] +
    [.[] |
      "| " +
      (.ts | split("T") | (.[0] | .[5:]) + " " + (.[1] | split("+")[0] | .[0:5])) + " | " +
      ((.session // "-") | .[0:8]) + " | " +
      .project + " | " +
      (if .type == "input" then (.payload.prompt // .payload.user_input // "-")
       elif .type == "skill-usage" then (.payload.command // .payload.skill // "-")
       elif .type == "result" then (.payload.summary // "-")
       else "-" end | gsub("\n"; " ") | .[0:60] | if length >= 60 then . + "…" else . end) + " |"
    ] | .[]'
}

format_full() {
  jq -r '
    sort_by(.ts) | reverse | .[] |
    "───────────────────────────────────────────────\n" +
    (.ts | split("T") | (.[0] | .[5:]) + " " + (.[1] | split("+")[0] | .[0:5])) +
    " | " + ((.session // "-") | .[0:8]) +
    " | " + .project +
    (if .branch != "" then " @ " + .branch else "" end) +
    " [" + .type + "]\n" +
    (if .type == "input" then (.payload.prompt // .payload.user_input // "-")
     elif .type == "skill-usage" then (.payload.command // .payload.skill // "-")
     elif .type == "result" then (.payload.summary // "-")
     else "-" end)'
}

format_output() {
  case "$MODE" in
    full)   format_full ;;
    scroll) format_compact | less -S ;;
    *)      format_compact ;;
  esac
}

# --- Filters ---

filter_by_hours() {
  local hours="$1"
  local cutoff
  cutoff=$(date -v-${hours}H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -d "$hours hours ago" +%Y-%m-%dT%H:%M:%S)
  jq --arg cutoff "$cutoff" 'select(.ts >= $cutoff)'
}

filter_by_keyword() {
  if [ -n "$GREP_KW" ]; then
    jq --arg kw "$GREP_KW" 'select(tostring | test($kw; "i"))'
  else
    cat
  fi
}

grep_header() {
  if [ -n "$GREP_KW" ]; then
    echo " (키워드: \`$GREP_KW\`)"
  fi
}

mode_hint() {
  if [ "$MODE" = "compact" ]; then
    echo ""
    echo "> --full: 전체 내용 보기 | --scroll: 가로 스크롤"
  fi
}

# --- Usage ---

show_usage() {
  cat <<'EOF'
## work-log 사용법

```
/session-tools:work-log <범위> [옵션]
```

### 시간 범위
| 명령 | 설명 |
|------|------|
| `1h` | 최근 1시간 (기본 추천) |
| `2h` | 최근 2시간 |
| `4h` | 최근 4시간 |
| `today` | 오늘 전체 |
| `yesterday` | 어제 전체 |
| `week` | 최근 7일 |

### 필터
| 명령 | 설명 |
|------|------|
| `project <name>` | 특정 프로젝트만 |
| `session <id>` | 특정 세션만 (앞 8자리 가능) |
| `skill` | 스킬 사용 로그만 |
| `stats` | 스킬별 사용 집계 |
| `2026-03-07` | 특정 날짜 |

### 키워드 검색
| 명령 | 설명 |
|------|------|
| `grep <keyword>` | 전체 로그에서 키워드 검색 |
| `today grep <keyword>` | 오늘 로그에서 키워드 검색 |
| `2h grep <keyword>` | 최근 2시간에서 키워드 검색 |

### 출력 모드
| 옵션 | 설명 |
|------|------|
| (기본) | 컴팩트 테이블 (내용 60자 제한) |
| `--full` | 리스트 형식 (전체 내용 표시) |
| `--scroll` | 가로 스크롤 (less -S) |

> 팁: `1h` 로 최근 작업부터 확인해보세요.
EOF
}

# --- Main ---

case "$ACTION" in
  "")
    show_usage
    ;;
  grep)
    [ -z "$GREP_KW" ] && echo "Usage: work-log grep <keyword>" && exit 1
    echo "## 전체 로그 검색$(grep_header)"
    echo ""
    cat "$LOG_DIR"/*.jsonl 2>/dev/null | filter_by_keyword | jq -s '.' | format_output
    mode_hint
    ;;
  [0-9]*h)
    HOURS="${ACTION%h}"
    DATE=$(date +%Y-%m-%d)
    echo "## 최근 ${HOURS}시간 로그$(grep_header)"
    echo ""
    cat "$LOG_DIR/${DATE}"*.jsonl 2>/dev/null | filter_by_hours "$HOURS" | filter_by_keyword | jq -s '.' | format_output
    mode_hint
    ;;
  today)
    DATE=$(date +%Y-%m-%d)
    echo "## 오늘 로그 ($DATE)$(grep_header)"
    echo ""
    cat "$LOG_DIR/${DATE}"*.jsonl 2>/dev/null | filter_by_keyword | jq -s '.' | format_output
    mode_hint
    ;;
  yesterday)
    DATE=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)
    echo "## 어제 로그 ($DATE)$(grep_header)"
    echo ""
    cat "$LOG_DIR/${DATE}"*.jsonl 2>/dev/null | filter_by_keyword | jq -s '.' | format_output
    mode_hint
    ;;
  week)
    echo "## 최근 7일 로그$(grep_header)"
    echo ""
    for i in $(seq 0 6); do
      DATE=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "$i days ago" +%Y-%m-%d)
      cat "$LOG_DIR/${DATE}"*.jsonl 2>/dev/null
    done | filter_by_keyword | jq -s '.' | format_output
    mode_hint
    ;;
  skill)
    echo "## 스킬 사용 로그$(grep_header)"
    echo ""
    cat "$LOG_DIR"/*_skill.jsonl 2>/dev/null | filter_by_keyword | jq -s '.' | format_output
    mode_hint
    ;;
  stats)
    echo "## 스킬별 집계"
    echo ""
    cat "$LOG_DIR"/*_skill.jsonl 2>/dev/null | jq -s '
      group_by(.payload.skill) |
      map({skill: .[0].payload.skill, count: length}) |
      sort_by(-.count) |
      ["| 스킬 | 횟수 |", "|------|------|"] +
      [.[] | "| " + .skill + " | " + (.count | tostring) + " |"] |
      .[]' -r
    ;;
  project)
    [ -z "$ARG" ] && echo "Usage: work-log project <name>" && exit 1
    echo "## 프로젝트: $ARG$(grep_header)"
    echo ""
    cat "$LOG_DIR"/*.jsonl 2>/dev/null | jq --arg p "$ARG" 'select(.project==$p)' | filter_by_keyword | jq -s '.' | format_output
    mode_hint
    ;;
  session)
    [ -z "$ARG" ] && echo "Usage: work-log session <id>" && exit 1
    echo "## 세션: $ARG$(grep_header)"
    echo ""
    cat "$LOG_DIR"/*.jsonl 2>/dev/null | jq --arg s "$ARG" 'select(.session | startswith($s))' | filter_by_keyword | jq -s '.' | format_output
    mode_hint
    ;;
  20[0-9][0-9]-[0-1][0-9]-[0-3][0-9])
    echo "## $ACTION 로그$(grep_header)"
    echo ""
    cat "$LOG_DIR/${ACTION}"*.jsonl 2>/dev/null | filter_by_keyword | jq -s '.' | format_output
    mode_hint
    ;;
  *)
    show_usage
    exit 1
    ;;
esac
