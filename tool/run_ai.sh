#!/usr/bin/env bash
###
 # @Author: yanxiao@dreame.tech
 # @Date: 2026-05-25 10:06:59
 # @Description: 
### 
set -euo pipefail

if [[ -f .env.local ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env.local
  set +a
fi

: "${OPENAI_API_KEY:?Set OPENAI_API_KEY in .env.local or your shell environment.}"

AI_DIAGNOSIS_ENDPOINT="${AI_DIAGNOSIS_ENDPOINT:-https://unifyapi.xyz/v1/responses}"
AI_DIAGNOSIS_MODEL="${AI_DIAGNOSIS_MODEL:-gpt-5.4}"
AI_DIAGNOSIS_API_STYLE="${AI_DIAGNOSIS_API_STYLE:-responses}"

flutter run -d chrome \
  --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY" \
  --dart-define=AI_DIAGNOSIS_ENDPOINT="$AI_DIAGNOSIS_ENDPOINT" \
  --dart-define=AI_DIAGNOSIS_MODEL="$AI_DIAGNOSIS_MODEL" \
  --dart-define=AI_DIAGNOSIS_API_STYLE="$AI_DIAGNOSIS_API_STYLE"
