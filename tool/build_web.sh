#!/usr/bin/env bash
set -euo pipefail

# Vercel 默认环境没有 Flutter。没有 flutter 命令时，临时下载一份稳定版 SDK 用于构建。
if ! command -v flutter >/dev/null 2>&1; then
  export FLUTTER_HOME="${FLUTTER_HOME:-/tmp/flutter}"
  if [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

flutter --version
flutter pub get

# 线上构建只把前端指向同源代理，不把 OPENAI_API_KEY 打进 Flutter Web 包。
flutter build web \
  --release \
  --dart-define=AI_DIAGNOSIS_ENDPOINT=/api/diagnosis \
  --dart-define=AI_DIAGNOSIS_MODEL="${AI_DIAGNOSIS_MODEL:-gpt-5.5}"
