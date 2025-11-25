# Stage 1: lấy nội dung từ image traffmonetizer (chứa binary)
FROM traffmonetizer/cli_v2 AS tm_stage

# Stage 2: runtime python
FROM python:3.11-slim

WORKDIR /app

# Cài những gói cần thiết
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates findutils \
    && rm -rf /var/lib/apt/lists/*

# Copy toàn bộ filesystem của image traffmonetizer vào /tmroot (để tìm binary)
COPY --from=tm_stage / /tmroot/

# Copy app files
COPY requirements.txt /app/requirements.txt
COPY app.py /app/app.py
COPY start.sh /app/start.sh

# Cài Python deps
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Quyền thực thi
RUN chmod +x /app/start.sh

# Port minh hoạ; Render sẽ set $PORT runtime
EXPOSE 10000

CMD ["/app/start.sh"]
