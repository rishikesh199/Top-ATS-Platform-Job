# Stapply DE Pipeline — Source Code

This folder contains the **sanitized, production-equivalent** source code for the
*Top ATS Platform Jobs — Stapply Job Market Data Engineering Pipeline*.

> **Note:** All sensitive values (`S3_BUCKET`, emails, workspace URLs, run IDs)
> have been replaced with `<YOUR_S3_BUCKET>`, `<YOUR_EMAIL>`, etc.
> See `databricks-sdp/config.py` for the full list of placeholders to fill in
> before deploying.

---

## Folder Structure

```
code/
├── aws-fargate/                    # AWS ECS Fargate microservice
│   ├── app.py                      # ATS scraper + S3 Parquet writer
│   └── Dockerfile                  # python:3.12-slim, 1024 CPU / 2048 MiB
│
└── databricks-sdp/                 # Databricks Streaming Delta Pipeline (SDP)
    ├── config.py                   # ← EDIT THIS FIRST (S3_BUCKET, emails)
    ├── transformations/
    │   ├── bronze/bronze.sql       # Auto Loader + Auto CDC FROM SNAPSHOT (SCD Type 2)
    │   ├── silver/silver.sql       # 1 Materialized View: 9 cleaning transforms + role taxonomy
    │   └── gold/gold.sql           # 6 Materialized Views (KPIs, explorer, daily movement)
    ├── notebooks/
    │   ├── 01_deploy.py            # One-click deployment notebook (REST API)
    │   └── 02_handover_guide.py    # Health check + ops runbook for new engineers
    └── gen2-reference/
        └── sql/ddl/gold_tables.sql # Gen2 DDL (reference only — superseded by Gen3)
```

---

## Quick Start (New Account Deployment)

### Prerequisites
- AWS account with ECS + ECR + EventBridge + S3 access
- Databricks workspace with Unity Catalog enabled
- Docker installed locally

### Step 1 — Deploy AWS Fargate

```bash
# Build and push Docker image
docker build -t stapply-scraper ./aws-fargate
aws ecr create-repository --repository-name stapply-scraper --region eu-north-1
docker tag stapply-scraper:latest <ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/stapply-scraper:latest
docker push <ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/stapply-scraper:latest
```

Create ECS Task Definition with:
- CPU: 1024, Memory: 2048 MiB
- Environment: `S3_BUCKET=<your-bucket>`, `AWS_DEFAULT_REGION=eu-north-1`
- Image: the ECR URI above

Create EventBridge rule → schedule `cron(30 3 * * ? *)` (= 09:00 IST) → target ECS task.

### Step 2 — Deploy Databricks SDP

```python
# In Databricks workspace:
# 1. Import the databricks-sdp/ folder to /Shared/stapply-deployment/
# 2. Edit config.py — set S3_BUCKET, ALERT_EMAILS
# 3. Open 01_deploy.py and Run All
```

### Step 3 — Verify

```python
# Run 02_handover_guide.py → all cells should show ✅
```

---

## Architecture

```
EventBridge (cron 09:00 IST)
  └─► ECS Fargate Task (app.py)
        └─► S3: raw/stapply/snapshots/snapshot_date=YYYY-MM-DD/all.parquet
              └─► Databricks SDP Pipeline (bronze.sql → silver.sql → gold.sql)
                    └─► Lakeview Dashboard (4 pages, 22 datasets)
```

| Component | Technology | Key Detail |
|-----------|-----------|------------|
| Scraper | Python 3.12 + boto3 | 8 MiB chunk stream, 64 MiB S3 multipart |
| Container | Docker on ECS Fargate | 1024 CPU / 2048 MiB, `eu-north-1` |
| Storage | AWS S3 | Parquet, Hive-partitioned by `snapshot_date` |
| Ingestion | Databricks Auto Loader | Checkpoint-based, schema evolution |
| CDC | Auto CDC FROM SNAPSHOT | SCD Type 2 on `url` key |
| Transform | Materialized Views | 1 Silver MV (9 transforms), 6 Gold MVs |
| Catalog | Unity Catalog | `workspace.default.*` |
| Dashboard | Databricks Lakeview | 22 datasets, 4 pages |

---

## Known Issues & Mitigations

| Issue | File | Mitigation |
|-------|------|------------|
| `DEVELOPMENT_MODE=True` default | `config.py` | Set to `False` before production deploy |
| Hard-coded S3 URI in bronze | `bronze.sql` Gen3 Newacc | Use `{{S3_PATH}}` template placeholder |
| Handover path references old user | `02_handover_guide.py` | Replaced with self-contained notebook |
| 414K expectation warnings | Silver MV | Monitor via pipeline event log; tunable with CONSTRAINT adjustments |
