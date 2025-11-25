# Stage 1: lấy nội dung từ image traffmonetizer (chứa binary)
FROM traffmonetizer/cli_v2 AS tm_stage

# Stage 2: runtime python
FROM python:3.11-slim

WORKDIR /app

# Cài những gói cần thiết
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates findutils procps dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Copy toàn bộ filesystem của image traffmonetizer vào /tmroot
COPY --from=tm_stage / /tmroot/

# Tìm và copy binary traffmonetizer vào /usr/local/bin
RUN TM_BIN=$(find /tmroot -type f -name "Tm" -o -type f -name "traffmonetizer" 2>/dev/null | head -n1) && \
    if [ -n "$TM_BIN" ]; then \
        cp "$TM_BIN" /usr/local/bin/traffmonetizer && \
        chmod +x /usr/local/bin/traffmonetizer && \
        echo "Found and copied: $TM_BIN"; \
    else \
        echo "Listing /tmroot structure:" && \
        find /tmroot -type f 2>/dev/null | head -50; \
    fi

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
