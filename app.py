import os
import subprocess
from fastapi import FastAPI

app = FastAPI(title="Render Web Service")

@app.get("/")
def root():
    return {"status": "ok", "service": "render-webservice"}

@app.get("/health")
def health():
    # Kiểm tra process traffmonetizer đang chạy không
    tm_running = False
    try:
        result = subprocess.run(
            ["pgrep", "-f", "traffmonetizer"],
            capture_output=True,
            text=True
        )
        tm_running = result.returncode == 0
    except Exception:
        pass
    
    return {
        "alive": True,
        "traffmonetizer_running": tm_running
    }

@app.get("/logs")
def logs():
    # Đọc log của traffmonetizer nếu có
    log_content = ""
    try:
        if os.path.exists("/tmp/tm.log"):
            with open("/tmp/tm.log", "r") as f:
                # Lấy 100 dòng cuối
                lines = f.readlines()
                log_content = "".join(lines[-100:])
    except Exception as e:
        log_content = f"Error reading log: {str(e)}"
    
    return {"logs": log_content}
