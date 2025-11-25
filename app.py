import os
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"status": "ok"}

@app.get("/health")
def health():
    # Nếu muốn kiểm tra process traffmonetizer, có thể check PID file hoặc tên process
    return {"alive": True}
