#!/bin/bash
set -e

# Token và device name lấy từ biến môi trường (set trên Render)
TOKEN="${TM_TOKEN:-FCiP25z9uFLVqDRnFK3nguKfOPwBlftOr1JtYgQtLbA=}"
DEVICE="${TM_DEVICE:-idx}"

# Chạy traffmonetizer ở background, lưu PID
# Giả sử lệnh 'traffmonetizer' có sẵn trong image traffmonetizer/cli_v2
traffmonetizer start accept --token "$TOKEN" --device-name "$DEVICE" &
TM_PID=$!

echo "Started traffmonetizer with PID $TM_PID"

# Khi nhận SIGTERM/SIGINT thì kill background process sạch
_term() {
  echo "Received SIGTERM/SIGINT. Stopping traffmonetizer (pid $TM_PID) ..."
  kill -TERM "$TM_PID" 2>/dev/null || true
  wait "$TM_PID" || true
  exit 0
}

trap _term SIGTERM SIGINT

# Đợi 2s cho chắc
sleep 2

# Lấy PORT từ env (Render set $PORT)
PORT="${PORT:-10000}"

# exec uvicorn để nó trở thành PID 1 (nhận tín hiệu)
exec uvicorn app:app --host 0.0.0.0 --port "$PORT" --proxy-headers
