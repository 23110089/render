#!/bin/bash
set -e

TOKEN="${TM_TOKEN:-FCiP25z9uFLVqDRnFK3nguKfOPwBlftOr1JtYgQtLbA=}"
DEVICE="${TM_DEVICE:-idx}"

echo "=== Starting Render Web Service with TraffMonetizer ==="

# Tìm binary traffmonetizer
TM_BIN=""

# 1) Thử command trực tiếp
if command -v traffmonetizer &>/dev/null; then
  TM_BIN="$(command -v traffmonetizer)"
fi

# 2) Tìm trong /tmroot (multi-stage copy)
if [ -z "$TM_BIN" ] && [ -d "/tmroot" ]; then
  TM_BIN="$(find /tmroot -type f -name 'traffmonetizer' 2>/dev/null | head -n1 || true)"
fi

# 3) Tìm trong /tmroot/usr/local/bin hoặc các path phổ biến
if [ -z "$TM_BIN" ]; then
  for path in /tmroot/usr/local/bin/traffmonetizer /tmroot/usr/bin/traffmonetizer /tmroot/app/traffmonetizer; do
    if [ -x "$path" ]; then
      TM_BIN="$path"
      break
    fi
  done
fi

if [ -z "$TM_BIN" ]; then
  echo "WARNING: traffmonetizer binary không tìm thấy, chỉ chạy web service."
else
  echo "Found traffmonetizer binary at: $TM_BIN"
  chmod +x "$TM_BIN" 2>/dev/null || true
  
  # Chạy traffmonetizer background
  nohup "$TM_BIN" start accept --token "$TOKEN" --device-name "$DEVICE" > /tmp/tm.log 2>&1 &
  TM_PID=$!
  echo "Started traffmonetizer with PID $TM_PID"
  
  # Lưu PID để cleanup
  echo "$TM_PID" > /tmp/tm.pid
fi

# Forward signals để dừng sạch
cleanup() {
  echo "Received shutdown signal..."
  if [ -f /tmp/tm.pid ]; then
    TM_PID=$(cat /tmp/tm.pid)
    echo "Stopping traffmonetizer (pid $TM_PID) ..."
    kill -TERM "$TM_PID" 2>/dev/null || true
    wait "$TM_PID" 2>/dev/null || true
  fi
  exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT

# Đợi traffmonetizer khởi động
sleep 3

# Lấy PORT do Render cấp (mặc định 10000)
PORT="${PORT:-10000}"

echo "=== Starting Web Server on port $PORT ==="

# Chạy uvicorn web server
exec uvicorn app:app --host 0.0.0.0 --port "$PORT" --proxy-headers --log-level info
