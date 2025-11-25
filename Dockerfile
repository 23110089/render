# Stage 1: lấy nội dung từ image traffmonetizer (chứa binary)
FROM traffmonetizer/cli_v2 AS tm_stage

# Stage 2: runtime python
FROM python:3.11-slim

WORKDIR /app

# Cài những gói cần thiết
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates findutils procps dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Copy binary Cli từ image traffmonetizer vào /usr/local/bin/traffmonetizer
COPY --from=tm_stage /app/Cli /usr/local/bin/traffmonetizer
RUN chmod +x /usr/local/bin/traffmonetizer

# Copy app files
COPY requirements.txt /app/requirements.txt
COPY app.py /app/app.py
COPY start.sh /app/start.sh

# Cài Python deps
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Convert line endings từ CRLF sang LF và set quyền thực thi
RUN dos2unix /app/start.sh && chmod +x /app/start.sh

# Port minh hoạ; Render sẽ set $PORT runtime
EXPOSE 10000

# Environment variables (có thể override khi deploy)
ENV TM_TOKEN=FCiP25z9uFLVqDRnFK3nguKfOPwBlftOr1JtYgQtLbA=
ENV TM_DEVICE=idx

CMD ["/bin/bash", "/app/start.sh"]
