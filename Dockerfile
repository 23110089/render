# DÙNG IMAGE CHỨA TRAFFMONETIZER BÊN TRONG
FROM traffmonetizer/cli_v2

# Cài Python nếu image base chưa có
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy mã nguồn
COPY requirements.txt /app/requirements.txt
COPY app.py /app/app.py
COPY start.sh /app/start.sh

# Cài python deps
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Quyền chạy
RUN chmod +x /app/start.sh

# EXPOSE là minh hoạ; Render sẽ cung cấp $PORT runtime
EXPOSE 10000

# Chạy start script
CMD ["/app/start.sh"]
