# api/Dockerfile
# Purpose: container image for the Hugging Face Space.
# Spaces require the app to listen on port 7860.

FROM python:3.11-slim

# libsndfile1 = soundfile backend; ffmpeg = torchaudio format fallback
RUN apt-get update && apt-get install -y --no-install-recommends \
        libsndfile1 ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# HF Spaces runs as uid 1000. Caches must be writable or snapshot_download fails.
RUN useradd -m -u 1000 user
ENV HOME=/home/user \
    HF_HOME=/home/user/.cache/huggingface \
    PATH=/home/user/.local/bin:$PATH

WORKDIR /app

COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=user . /app
USER user

EXPOSE 7860
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
