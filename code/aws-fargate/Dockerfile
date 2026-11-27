# ============================================================
# Stapply ATS Scraper — Dockerfile
# ============================================================
# Base image: python:3.12-slim (official, minimal attack surface)
# Target:     AWS ECS Fargate (1024 CPU / 2048 MiB)
# Region:     eu-north-1 (Stockholm)
# Schedule:   EventBridge → 09:00 IST daily
# ============================================================

FROM python:3.12-slim

# Install OS deps: tzdata for IST timezone support
RUN apt-get update \
    && apt-get install -y --no-install-recommends tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps (pinned in production — use requirements.txt)
RUN pip install --no-cache-dir \
    boto3==1.34.* \
    requests==2.32.* \
    pyarrow==16.*

COPY app.py .

# ECS injects: S3_BUCKET, AWS_DEFAULT_REGION via Task Definition environment
CMD ["python", "app.py"]
