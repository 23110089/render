#!/bin/bash
set -e

TOKEN="${TM_TOKEN:-FCiP25z9uFLVqDRnFK3nguKfOPwBlftOr1JtYgQtLbA=}"
DEVICE="${TM_DEVICE:-idx}"

# Tìm binary traffmonetizer:
# 1) thử command trực tiếp
TM_BIN="$(command -v traffmonetizer || true)"

# 2) nếu không có, tìm trong /tmroot (multi-stage copy)
if [ -z "$TM_BIN" ]; then
  TM_BIN="$(find /tmroot -type f -name 'traffmonetizer' -print -quit || true)"
fi

if [ -z "$TM_BIN" ]; then
  echo "ERROR: traffmonetizer binary không tìm thấy."
  echo "Kiểm tra image gốc hoặc cung cấp đường dẫn binary."
  exit 1
fi

echo "Found traffmonetizer binary at: $TM_BIN"

# Chạy traffmonetizer background
"$TM_BIN" start accept --token "$TOKEN" --device-name "$DEVICE" &
TM_PID=$!

echo "Started traffmonetizer with PID $TM_PID"

# Forward signals để dừng sạch
_term() {
  echo "Stopping traffmonetizer (pid $TM_PID) ..."
  kill -TERM "$TM_PID" 2>/dev/null || true
  wait "$TM_PID" || true
  exit 0
}

trap _term SIGTERM SIGINT

# Đợi tí
sleep 2

# Lấy PORT do Render cấp
PORT="${PORT:-10000}"

# Exec uvicorn làm PID 1
exec uvicorn app:app --host 0.0.0.0 --port "$PORT" --proxy-headers
