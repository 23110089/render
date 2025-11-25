#!/bin/bash
set -e

TOKEN="${TM_TOKEN:-FCiP25z9uFLVqDRnFK3nguKfOPwBlftOr1JtYgQtLbA=}"
DEVICE="${TM_DEVICE:-idx}"

echo "=== Starting Render Web Service with TraffMonetizer ==="

# Tìm binary traffmonetizer
TM_BIN=""

# 1) Kiểm tra /usr/local/bin (nơi Dockerfile copy vào)
if [ -x "/usr/local/bin/traffmonetizer" ]; then
  TM_BIN="/usr/local/bin/traffmonetizer"
# 2) Tìm trong /tmroot
elif [ -d "/tmroot" ]; then
  TM_BIN=$(find /tmroot -type f \( -name "Tm" -o -name "traffmonetizer" \) 2>/dev/null | head -n1)
fi

if [ -n "$TM_BIN" ] && [ -x "$TM_BIN" ]; then
  echo "Found traffmonetizer binary at: $TM_BIN"
  
  # Chạy traffmonetizer background
  nohup "$TM_BIN" start accept --token "$TOKEN" --device-name "$DEVICE" > /tmp/tm.log 2>&1 &
  TM_PID=$!
  echo "Started traffmonetizer with PID $TM_PID"
  
  # Lưu PID để cleanup
  echo "$TM_PID" > /tmp/tm.pid
else
  echo "WARNING: traffmonetizer binary không tìm thấy hoặc không thực thi được"
  echo "Listing /tmroot:"
  find /tmroot -type f 2>/dev/null | head -20 || true
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
