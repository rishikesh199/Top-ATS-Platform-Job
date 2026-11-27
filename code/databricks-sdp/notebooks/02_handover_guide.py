# Databricks notebook source
# DBTITLE 1,Stapply SDP — Handover Guide
# MAGIC %md
# MAGIC # Stapply Enterprise SDP — Handover Guide
# MAGIC
# MAGIC This notebook is a self-contained handover document for a new data engineer
# MAGIC taking over this pipeline. Run all cells to perform a full health check and
# MAGIC get a live status of the deployment.
# MAGIC
# MAGIC ## Architecture Overview
# MAGIC ```
# MAGIC EventBridge (09:00 IST daily)
# MAGIC   └── ECS Fargate Task (app.py)
# MAGIC         └── S3: raw/stapply/snapshots/snapshot_date=YYYY-MM-DD/all.parquet
# MAGIC               └── Databricks SDP Pipeline (bronze → silver → gold)
# MAGIC                     └── Lakeview Dashboard (4 pages, 22 datasets)
# MAGIC ```
# MAGIC
# MAGIC ## Responsibilities
# MAGIC | Layer       | Owner                      | Action on failure |
# MAGIC |-------------|----------------------------|--------------------|
# MAGIC | Fargate task| AWS EventBridge + ECS      | Check CloudWatch logs, re-trigger task |
# MAGIC | SDP pipeline| Databricks (serverless)    | Check pipeline event log, re-trigger update |
# MAGIC | Dashboard   | Databricks Lakeview        | Republish if schema changed |
# MAGIC
# MAGIC ## Key Config File
# MAGIC All settings are in `config.py` (same folder as this notebook):
# MAGIC - `S3_BUCKET` / `S3_PATH` — where Fargate writes snapshots
# MAGIC - `CATALOG` / `SCHEMA` — Unity Catalog target
# MAGIC - `DEVELOPMENT_MODE` — **must be False in production**
# MAGIC - `ALERT_EMAILS` — failure notification recipients

# COMMAND ----------
# DBTITLE 1,Cell 1 — Import Config
import sys
sys.path.insert(0, dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get().rsplit("/", 1)[0])
import config as cfg

print("Config loaded:")
print(f"  Catalog : {cfg.CATALOG}.{cfg.SCHEMA}")
print(f"  Pipeline: {cfg.PIPELINE_NAME}")
print(f"  Dev Mode: {cfg.DEVELOPMENT_MODE}  ← should be False in production")

# COMMAND ----------
# DBTITLE 1,Cell 2 — Table Row Count Health Check
layers = {
    "bronze_raw":             f"{cfg.CATALOG}.{cfg.SCHEMA}.bronze_raw",
    "bronze_jobs (active)":   f"{cfg.CATALOG}.{cfg.SCHEMA}.bronze_jobs",
    "silver_enriched":        f"{cfg.CATALOG}.{cfg.SCHEMA}.silver_enriched",
    "gold_job_market_explorer": f"{cfg.CATALOG}.{cfg.SCHEMA}.gold_job_market_explorer",
    "gold_active_summary":    f"{cfg.CATALOG}.{cfg.SCHEMA}.gold_active_summary",
    "gold_daily_movement":    f"{cfg.CATALOG}.{cfg.SCHEMA}.gold_daily_movement",
}

print(f"{'Table':<35} {'Row Count':>12}")
print("-" * 50)
for label, table_ref in layers.items():
    try:
        count = spark.sql(f"SELECT COUNT(*) AS n FROM {table_ref}").first()["n"]
        print(f"{label:<35} {count:>12,}")
    except Exception as e:
        print(f"{label:<35} {'ERROR':>12} — {e}")

# COMMAND ----------
# DBTITLE 1,Cell 3 — Latest Snapshot Date
try:
    latest = spark.sql(f"""
        SELECT MAX(snapshot_date) AS latest_snapshot
        FROM {cfg.CATALOG}.{cfg.SCHEMA}.bronze_raw
    """).first()["latest_snapshot"]
    print(f"Latest snapshot: {latest}")
    if str(latest) < str(__import__('datetime').date.today()):
        print("⚠️  WARNING: Latest snapshot is not today — Fargate may not have run yet.")
    else:
        print("✅ Snapshot is current.")
except Exception as e:
    print(f"⚠️ Could not check snapshot date: {e}")

# COMMAND ----------
# DBTITLE 1,Cell 4 — DQ Expectation Failures (last run)
# MAGIC %sql
# MAGIC -- Check constraint violation counts from the last pipeline update
# MAGIC SELECT
# MAGIC   dataset,
# MAGIC   name,
# MAGIC   failed_records,
# MAGIC   passed_records
# MAGIC FROM event_log('<PIPELINE_ID>')   -- Replace <PIPELINE_ID> after deployment
# MAGIC WHERE event_type = 'flow_progress'
# MAGIC   AND origin.update_id = (
# MAGIC       SELECT MAX(origin.update_id)
# MAGIC       FROM event_log('<PIPELINE_ID>')
# MAGIC       WHERE event_type = 'flow_progress'
# MAGIC   )
# MAGIC   AND details:flow_progress:metrics:numOutputRows IS NOT NULL
# MAGIC ORDER BY dataset;

# COMMAND ----------
# DBTITLE 1,Cell 5 — Cross-Layer Consistency Check
try:
    result = spark.sql(f"""
    SELECT
        (SELECT COUNT(*) FROM {cfg.CATALOG}.{cfg.SCHEMA}.bronze_jobs WHERE __END_AT IS NULL) AS active_bronze,
        (SELECT COUNT(*) FROM {cfg.CATALOG}.{cfg.SCHEMA}.silver_enriched WHERE __END_AT IS NULL) AS active_silver,
        (SELECT COUNT(*) FROM {cfg.CATALOG}.{cfg.SCHEMA}.gold_job_market_explorer WHERE lifecycle_status = 'Active') AS active_gold
    """).first()

    print(f"Active jobs — Bronze: {result.active_bronze:,}  Silver: {result.active_silver:,}  Gold: {result.active_gold:,}")
    if result.active_bronze == result.active_silver == result.active_gold:
        print("✅ Cross-layer counts match.")
    else:
        print("❌ MISMATCH — trigger a full pipeline refresh and re-check.")
except Exception as e:
    print(f"Check failed: {e}")

# COMMAND ----------
# MAGIC %md
# MAGIC ## Common Operations
# MAGIC
# MAGIC ### Re-trigger pipeline manually
# MAGIC ```python
# MAGIC import requests
# MAGIC ctx   = dbutils.notebook.entry_point.getDbutils().notebook().getContext()
# MAGIC HOST  = f"https://{ctx.apiUrl().get()}"
# MAGIC TOKEN = ctx.apiToken().get()
# MAGIC requests.post(
# MAGIC     f"{HOST}/api/2.0/pipelines/<PIPELINE_ID>/updates",
# MAGIC     headers={"Authorization": f"Bearer {TOKEN}"},
# MAGIC     json={"full_refresh": False}
# MAGIC )
# MAGIC ```
# MAGIC
# MAGIC ### Full refresh (re-process all history)
# MAGIC Same as above but `"full_refresh": True`. Use only if Bronze SCD2 history is corrupted.
# MAGIC
# MAGIC ### Change target catalog/schema
# MAGIC Edit `config.py` → `CATALOG` / `SCHEMA`, then re-run `01_deploy.py`.
# MAGIC
# MAGIC ### Add a new ATS source
# MAGIC Add the endpoint to `app.py` → `ATS_SOURCES`, rebuild Docker image, push to ECR, update ECS Task Definition.
