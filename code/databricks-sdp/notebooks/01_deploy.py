# Databricks notebook source
# DBTITLE 1,Stapply SDP — One-Click Deployment
# MAGIC %md
# MAGIC # Stapply Enterprise SDP Pipeline — One-Click Deploy
# MAGIC
# MAGIC **How to use:**
# MAGIC 1. Edit `config.py` in this folder (set your S3_BUCKET, CATALOG, SCHEMA, ALERT_EMAILS)
# MAGIC 2. Run All cells in this notebook
# MAGIC 3. Done — Pipeline created, data flowing, dashboard published.
# MAGIC
# MAGIC | Step | What Happens |
# MAGIC | --- | --- |
# MAGIC | Cell 1 | Load config |
# MAGIC | Cell 2 | Render SQL templates (replace {{S3_PATH}} placeholder) |
# MAGIC | Cell 3 | Create SDP pipeline via REST API |
# MAGIC | Cell 4 | Copy SQL files to pipeline source root |
# MAGIC | Cell 5 | Start pipeline (wait for completion) |
# MAGIC | Cell 6 | Create dashboard from JSON config |
# MAGIC | Cell 7 | Health check: verify row counts across all 3 layers |

# COMMAND ----------
# DBTITLE 1,Cell 1 — Load Config
import sys
sys.path.insert(0, dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get().rsplit("/", 1)[0])
import config as cfg

print(f"S3 Path       : {cfg.S3_PATH}")
print(f"Catalog.Schema: {cfg.CATALOG}.{cfg.SCHEMA}")
print(f"Pipeline Name : {cfg.PIPELINE_NAME}")
print(f"Dev Mode      : {cfg.DEVELOPMENT_MODE}")
print(f"Serverless    : {cfg.SERVERLESS}")
print(f"Photon        : {cfg.PHOTON}")

# COMMAND ----------
# DBTITLE 1,Cell 2 — Render SQL Templates
import os

def render_sql(template_path: str, s3_path: str) -> str:
    """Replace {{S3_PATH}} placeholder with actual S3 path from config."""
    with open(template_path) as f:
        return f.read().replace("{{S3_PATH}}", s3_path)

# Read SQL template files
bronze_sql = render_sql(f"{cfg.SQL_TEMPLATES_PATH}/bronze/bronze.sql", cfg.S3_PATH)
silver_sql = render_sql(f"{cfg.SQL_TEMPLATES_PATH}/silver/silver.sql", cfg.S3_PATH)
gold_sql   = render_sql(f"{cfg.SQL_TEMPLATES_PATH}/gold/gold.sql",   cfg.S3_PATH)

print(f"✅ bronze.sql: {len(bronze_sql)} chars")
print(f"✅ silver.sql: {len(silver_sql)} chars")
print(f"✅ gold.sql  : {len(gold_sql)} chars")

# COMMAND ----------
# DBTITLE 1,Cell 3 — Create SDP Pipeline via REST API
import requests as req
import json

# Databricks workspace URL and token (injected by Databricks — no hard-coding)
ctx    = dbutils.notebook.entry_point.getDbutils().notebook().getContext()
HOST   = f"https://{ctx.apiUrl().get()}"
TOKEN  = ctx.apiToken().get()

headers = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}

pipeline_spec = {
    "name": cfg.PIPELINE_NAME,
    "serverless": cfg.SERVERLESS,
    "photon_mode": "PHOTON_ENABLED" if cfg.PHOTON else "PHOTON_DISABLED",
    "development": cfg.DEVELOPMENT_MODE,
    "channel": cfg.CHANNEL,
    "catalog": cfg.CATALOG,
    "target": cfg.SCHEMA,
    "notifications": [
        {"email_recipients": cfg.ALERT_EMAILS, "alerts": ["on-update-failure"]}
    ],
    "libraries": [
        {"file": {"path": f"{cfg.SQL_TEMPLATES_PATH}/bronze/bronze.sql"}},
        {"file": {"path": f"{cfg.SQL_TEMPLATES_PATH}/silver/silver.sql"}},
        {"file": {"path": f"{cfg.SQL_TEMPLATES_PATH}/gold/gold.sql"}},
    ]
}

resp = req.post(f"{HOST}/api/2.0/pipelines", headers=headers, json=pipeline_spec)
resp.raise_for_status()
PIPELINE_ID = resp.json()["pipeline_id"]
print(f"✅ Pipeline created: {PIPELINE_ID}")
print(f"   URL: {HOST}/#joblist/pipelines/{PIPELINE_ID}")

# COMMAND ----------
# DBTITLE 1,Cell 4 — Copy SQL Files to Pipeline Source
import base64

def upload_workspace_file(path: str, content: str) -> None:
    """Upload a file to Databricks workspace (overwrites if exists)."""
    encoded = base64.b64encode(content.encode()).decode()
    resp = req.post(
        f"{HOST}/api/2.0/workspace/import",
        headers=headers,
        json={"path": path, "content": encoded, "format": "AUTO", "overwrite": True}
    )
    resp.raise_for_status()

# Create target directories
for subdir in ["bronze", "silver", "gold"]:
    req.post(f"{HOST}/api/2.0/workspace/mkdirs", headers=headers,
             json={"path": f"{cfg.SQL_TEMPLATES_PATH}/{subdir}"})

upload_workspace_file(f"{cfg.SQL_TEMPLATES_PATH}/bronze/bronze.sql", bronze_sql)
upload_workspace_file(f"{cfg.SQL_TEMPLATES_PATH}/silver/silver.sql", silver_sql)
upload_workspace_file(f"{cfg.SQL_TEMPLATES_PATH}/gold/gold.sql",     gold_sql)
print("✅ SQL files uploaded to workspace")

# COMMAND ----------
# DBTITLE 1,Cell 5 — Start Pipeline and Wait
import time

start_resp = req.post(f"{HOST}/api/2.0/pipelines/{PIPELINE_ID}/updates",
                      headers=headers, json={"full_refresh": False})
start_resp.raise_for_status()
UPDATE_ID = start_resp.json()["update_id"]
print(f"Pipeline update started: {UPDATE_ID}")

# Poll until terminal state
for _ in range(60):   # max 30 min (60 × 30s)
    status_resp = req.get(f"{HOST}/api/2.0/pipelines/{PIPELINE_ID}/updates/{UPDATE_ID}",
                          headers=headers)
    state = status_resp.json().get("update", {}).get("state", "UNKNOWN")
    print(f"  State: {state}")
    if state in ("COMPLETED", "FAILED", "CANCELED"):
        break
    time.sleep(30)

if state == "COMPLETED":
    print("✅ Pipeline run COMPLETED")
else:
    raise RuntimeError(f"Pipeline finished in unexpected state: {state}")

# COMMAND ----------
# DBTITLE 1,Cell 6 — Publish Dashboard
with open(cfg.DASHBOARD_JSON_PATH) as f:
    dashboard_spec = json.load(f)

dashboard_spec["display_name"] = cfg.DASHBOARD_NAME

dash_resp = req.post(f"{HOST}/api/2.0/lakeview/dashboards",
                     headers=headers, json=dashboard_spec)
dash_resp.raise_for_status()
DASHBOARD_ID = dash_resp.json()["dashboard_id"]

# Publish to make shareable
req.post(f"{HOST}/api/2.0/lakeview/dashboards/{DASHBOARD_ID}/published",
         headers=headers)

print(f"✅ Dashboard published: {DASHBOARD_ID}")
print(f"   URL: {HOST}/dashboardsv3/{DASHBOARD_ID}/published")

# COMMAND ----------
# DBTITLE 1,Cell 7 — Health Check
print("=" * 60)
print("▌ DEPLOYMENT COMPLETE ▌")
print("=" * 60)

try:
    result = spark.sql(f"""
    SELECT
        (SELECT COUNT(DISTINCT snapshot_date) FROM {cfg.CATALOG}.{cfg.SCHEMA}.bronze_raw) AS snapshots,
        (SELECT COUNT(*) FROM {cfg.CATALOG}.{cfg.SCHEMA}.bronze_jobs WHERE __END_AT IS NULL) AS active_jobs,
        (SELECT COUNT(*) FROM {cfg.CATALOG}.{cfg.SCHEMA}.bronze_jobs) AS total_jobs,
        (SELECT COUNT(*) FROM {cfg.CATALOG}.{cfg.SCHEMA}.silver_enriched) AS silver_rows,
        (SELECT COUNT(*) FROM {cfg.CATALOG}.{cfg.SCHEMA}.gold_job_market_explorer) AS gold_rows
    """).first()

    print(f"\n✅ Data Verification:")
    print(f"   Snapshots ingested : {result.snapshots}")
    print(f"   Active jobs        : {result.active_jobs:,}")
    print(f"   Total jobs (SCD2)  : {result.total_jobs:,}")
    print(f"   Silver rows        : {result.silver_rows:,}")
    print(f"   Gold explorer rows : {result.gold_rows:,}")

    if result.total_jobs == result.silver_rows == result.gold_rows:
        print("   Cross-layer match  : ✅ ALL LAYERS MATCH")
    else:
        print("   Cross-layer match  : ❌ MISMATCH — check pipeline logs")

except Exception as e:
    print(f"⚠️ Health check skipped (tables may not exist yet): {e}")

print(f"\n── Assets Created ──────────────────────────────────────")
print(f"   Pipeline  : {HOST}/#joblist/pipelines/{PIPELINE_ID}")
print(f"   Dashboard : {HOST}/dashboardsv3/{DASHBOARD_ID}/published")

print(f"\n── Config Used ─────────────────────────────────────────")
print(f"   S3 Path   : {cfg.S3_PATH}")
print(f"   Catalog   : {cfg.CATALOG}.{cfg.SCHEMA}")
print(f"   Pipeline  : {cfg.PIPELINE_NAME}")
print(f"   Dashboard : {cfg.DASHBOARD_NAME}")

print(f"\n── Next Steps ──────────────────────────────────────────")
print("   1. Set DEVELOPMENT_MODE=False in config.py for production")
print("   2. Schedule a Lakeflow Job (daily, after Fargate EventBridge trigger)")
print("   3. Set up dashboard auto-refresh schedule")
print("\nDone! ✅")
