# Phase 3 — Code, Notebooks, Scripts & Dependencies Inventory

**Project:** Top ATS Platform Jobs — Stapply Job Market Data Engineering Pipeline  
**Status:** Phase 3 Complete — **AWAITING EXPLICIT USER APPROVAL BEFORE PHASE 4**  
**Primary Package:** `stapply-deploymentNewacc.zip` (`2026-10-08T09:17:31Z`), with full-project coverage of AWS Fargate ingestion, Gen 2 (`stapply-pipeline-enterprise.zip`), and Gen 1 (`Stapply-Export-Dev/`).  
**Sensitivity Rule:** Zero raw secrets, emails, AWS Account IDs, Databricks workspace URLs/IDs, or concrete S3 URIs are reproduced.

---

## 1. Primary Package (`stapply-deploymentNewacc.zip`) — File-by-File Inventory

### 1.1 `config.py` (52 lines)
- **Purpose & Role:** Single central configuration module for the Gen 3 Lakeflow SDP deployment (`S3_BUCKET`, `S3_PATH`, `CATALOG`, `SCHEMA`, `PIPELINE_NAME`, `SERVERLESS`, `PHOTON`, `DEVELOPMENT_MODE`, `CHANNEL`, `ALERT_EMAILS`, `DASHBOARD_NAME`, schedule cron expressions, `DEPLOY_BASE_PATH`).
- **Inputs / Outputs:** No external inputs; exposes Python constants imported dynamically via `importlib.util` by `01_deploy.py` (line 41) and `03_setup_schedules.py` (line 15).
- **Dependencies:** Pure Python (`config.py` lines 1–52).
- **Execution & Questions:** Not executed standalone; imported by `01_deploy.py` and `03_setup_schedules.py`. *Question:* `DEVELOPMENT_MODE = True` (line 24) disables production retries per inline comment—was this intended for dev/new-account onboarding only?

### 1.2 `01_deploy.py` (335 lines)
- **Purpose & Role:** End-to-end automated deployer for the Lakeflow SDP pipeline and Lakeview dashboard (`stapply-deploymentNewacc.zip::README.md` lines 52–60).
- **Inputs:** `config.py` constants, SQL templates (`transformations/{bronze,silver,gold}/*.sql`), `dashboard/dashboard_config.json`, and Databricks notebook context (`apiUrl()`, `apiToken()`, `userName()`, `notebookPath()` on lines 33, 47–48, 106).
- **Outputs:** Creates/reuses SDP pipeline via `POST /api/2.0/pipelines` (line 124), deploys SQL files to `/Users/{current_user}/stapply_sdp_{hash_suffix}` (line 107), triggers and polls pipeline update (lines 179–194), creates/updates & publishes Lakeview dashboard (`embed_credentials: False`, lines 269–283), and runs a 7-point Spark SQL health check (lines 291–335).
- **Dependencies:** `sys`, `os`, `json`, `time`, `requests`, `re`, `importlib`, `hashlib`, `base64`, `dbutils`, `spark`. *Why used:* `requests` + REST APIs allow zero-CLI notebook-driven provisioning; `importlib.util` loads `config.py` regardless of Databricks workspace relative path; `embed_credentials: False` avoids HTTP 400 when `warehouse_id` is omitted (line 278).
- **Execution Flow:**
  ```text
  [Step 1: Load config.py + API token]
     → [Step 2: Render {{S3_PATH}} in SQL templates]
     → [Step 3: GET/POST /api/2.0/pipelines]
     → [Step 4: Upload SQL to /Users/<user>/stapply_sdp_<hash>]
     → [Step 5: Start update & poll until COMPLETED]
     → [Step 6: Create/patch & publish Lakeview dashboard]
     → [Step 7: 7-point Spark SQL health check]
  ```
- **Unclear/Flagged Items:**
  1. Line 29 imports `importlib` alongside `import importlib.util` on line 41 (redundant import).
  2. Unlike `stapply-deployment.zip::01_deploy.py` (466 lines, Step 8 inline job creation), `Newacc`'s `01_deploy.py` defers scheduling to `03_setup_schedules.py` and has `[Unverified Runtime]`.

### 1.3 `02_handover_guide.py` (6 lines)
- **Purpose & Role:** Wrapper notebook intended to invoke an external handover guide notebook (`dbutils.notebook.run(..., 600)`, line 6).
- **Flagged Dependency / Question:** Line 6 references an external user-scoped path containing a corporate email rather than a relative `./` path inside the deployment bundle. On a fresh Databricks account without that user folder, this call will fail—is this wrapper deprecated or meant to point to a local `README.md` / bundled notebook?

### 1.4 `03_setup_schedules.py` (162 lines)
- **Purpose & Role:** Post-deployment automation script that attaches daily schedules to the SDP pipeline and Lakeview dashboard (`stapply-deploymentNewacc.zip::README.md` lines 62–67).
- **Inputs:** `config.py` (`PIPELINE_NAME`, `DASHBOARD_NAME`, `PIPELINE_SCHEDULE_CRON`, `DASHBOARD_REFRESH_CRON`, `SCHEDULE_TIMEZONE`, `PIPELINE_JOB_NAME`, `DASHBOARD_REFRESH_NAME`).
- **Outputs:** Creates/updates a Databricks Lakeflow Job (`POST /api/2.1/jobs/create`, line 106) running the SDP pipeline at `09:30 IST`, and creates/updates a Lakeview dashboard refresh schedule (`WorkspaceClient().lakeview`, lines 114–117) at `10:00 IST` using the discovered SQL Warehouse (`/api/2.0/sql/warehouses`, line 65).
- **Dependencies:** `os`, `json`, `requests`, `importlib.util`, `databricks.sdk.WorkspaceClient`, `databricks.sdk.service.dashboards.{Schedule, CronSchedule}`.
- **Execution & Status:** Run after `01_deploy.py`; `[Implemented / Unverified Runtime]`.

### 1.5 Declarative SQL Files (`transformations/`)
1. **`transformations/bronze/bronze.sql` (52 lines):**
   - **What it does:** Defines `bronze_raw` (Auto Loader `STREAM(read_files(..., format => 'parquet'))` with `CONSTRAINT valid_url EXPECT (url IS NOT NULL) ON VIOLATION DROP ROW`, lines 10–18) and `bronze_jobs` (clustered by `url`, populated by `AUTO CDC INTO bronze_jobs FROM SNAPSHOT (...) WITH VERSION (...) KEYS (url) STORED AS SCD TYPE 2 TRACK HISTORY ON` 13 columns, lines 21–52).
   - **Flagged Issue:** Lines 7 and 16 hardcode a concrete S3 URI instead of `'{{S3_PATH}}'` (present in `stapply-deployment.zip`), bypassing `01_deploy.py` Step 2 template substitution.
2. **`transformations/silver/silver.sql` (164 lines):**
   - **What it does:** Defines `silver_enriched` Materialized View (`CLUSTER BY (country_iso_clean)`), enforcing 4 quality expectations (`url_not_null` `ON VIOLATION DROP ROW`, `title_not_empty`, `company_not_empty`, `valid_country_iso`, lines 9–15) and computing 14 derived columns (timestamp parsing, commitment normalization, numeric salary parsing, 36-branch V2 role taxonomy, job age buckets, and data-quality flags).
3. **`transformations/gold/gold.sql` (148 lines):**
   - **What it does:** Defines 6 Gold Materialized Views (`gold_country_market_summary`, `gold_country_role_summary`, `gold_country_role_company_summary`, `gold_country_role_location_summary`, `gold_job_market_explorer`, `gold_daily_movement`) consumed by Lakeview and SQL analysts.

### 1.6 Dashboards & Docs in `stapply-deploymentNewacc.zip`
- **`dashboard/dashboard_config.json` (3,584 lines) & `Top ATS Platform Job Market.lvdash.json`:** Identical 3-page, 22-dataset Lakeview dashboard definition (`Current Snapshot`, `Daily Job Movement`, `Job Lifecycle`), differing only in literal `—` vs `\u2014` on lines 663, 1966, 2711 (`phase0_discovery_report.md` line 58).
- **`README.md` (99 lines):** Quick-start and architecture reference for `01_deploy` + `03_setup_schedules`.
- **Related (`stapply-deployment.zip`):** `03_before_after_comparison.py` (651 lines) — post-migration audit notebook comparing Gen 2 (7 tasks, 30 tables) vs. Gen 3 (3 SQL files, 9 SDP objects).

---

## 2. AWS Fargate Ingestion (`Archive/Dockerfile` & `Portfolio/AWS_setup.txt`)

- **`Archive/Dockerfile` (13 lines):** Builds `python:3.12-slim` with `tzdata` (needed for `ZoneInfo("Asia/Kolkata")` in `app.py` line 65), `boto3`, and `requests`, running `CMD ["python", "app.py"]`.
- **`app.py` (captured in `Portfolio/AWS_setup.txt` lines 40–198):**
  - **Inputs:** `SOURCE_URL`, `BUCKET`, `SNAPSHOT_ROOT` env vars; streams `all.parquet` via `requests.get(stream=True, timeout=(60, 1800))`.
  - **Logic:** Buffers `8 MiB` HTTP chunks into `64 MiB` S3 multipart upload parts (`s3.create_multipart_upload` → `upload_part` → `complete_multipart_upload`) targeting `snapshot_date=YYYY-MM-DD/all.parquet` in `eu-north-1`.
  - **Execution:** Triggered daily at `09:00 IST` by EventBridge Scheduler `stapply-daily-fargate-ingestion` (`AWS_setup.txt` lines 881–906).

---

## 3. Earlier Generations (Reference Inventory)

### 3.1 Gen 2 Enterprise Medallion (`Archive/stapply-pipeline-enterprise.zip`, 20 files)
- **Config & Setup:** `config/00_config.py`, `env.template`, `setup/00_setup_tables.py` (creates 30 Delta tables: `1` Bronze, `9` Silver, `7` Gold Core, `13` Gold Analytical), `setup/00_job_creator.py`, `setup/00_dashboard_creator.py`.
- **Pipeline Notebooks (`pipeline/`):** `01_snapshot_acquisition.py` → `02_bronze_ingestion.py` → `04_data_quality_validation.py` (21 DQ checks on Bronze) → `03_silver_processing.py` (9 stages) → `05_lifecycle_processing.py` → `06_gold_analytics.py` → `07_monitoring_alerting.py`.
- **Infra & Docs:** `manifest.json`, `infra/databricks/{job_config.json, dashboard_backup.json}`, `infra/aws/fargate_setup.md`, `docs/{architecture.md, master_guide.md, table_reference.md}`.

### 3.2 Gen 1 Workspace Export (`Stapply-Export-Dev/`, 21 files)
- **Centralized Config & Setup (`2026-09-30`):** `src/pipelines/00_config` (96 lines), `infra/jobs/00_job_creator` (188 lines), `sql/ddl/00_setup_tables` (223 lines).
- **4-Task Pipeline (`src/pipelines/01..04`):** `01_snapshot_acquisition` (streams Parquet via UC Volume `/Volumes/.../tmp_upload` → S3, asserts `row_count > 0`, `null_urls == 0`, `duplicate_urls == 0`) → `02_data_quality_validation` (21 checks, raises on `CRITICAL` fail; contains leftover `RUN_ID` debug cell at line 649) → `03_lifecycle_processing` (two-pass Delta `MERGE` into `job_lifecycle`, `job_change_events`, `job_daily_movement`, `job_snapshot_run_log`, 5-day S3 retention) → `04_monitoring_alerting` (Databricks Jobs API + 7-category health report).
- **Exploratory & Ops:** `src/notebooks/{s3_ingest_bronze_table, job_market_sql_analytics.py}`, `ops/{recent_runs.json, run_summary.md}`, `docs/*`, `chat_history/complete_conversation_log.py`.

---

## 4. Dependency & Tooling Rationale (Evidence-Based)

| Tool / Library | Where Used | Why Used (Supported by Project Evidence) |
|---|---|---|
| **AWS ECS Fargate + `boto3` + `requests`** | `app.py`, `Dockerfile` | Bypasses Databricks Serverless external egress/DNS constraints and `file:` prefix limitations in `dbutils.fs.cp()` (`short_documentation.md` L55; `project_architecture_challenges_learnings.py` L87–95). |
| **Lakeflow SDP (`AUTO CDC FROM SNAPSHOT` + MVs)** | `bronze.sql`, `silver.sql`, `gold.sql` | Replaces 7 imperative Python notebooks and 30 Delta tables with 3 declarative SQL files (9 objects), cutting runtime from `~14–15m` to `~8m` (`03_before_after_comparison.py`; `SDP pipeline (2).png`). |
| **Unity Catalog + Photon + Serverless** | `config.py`, `gold_tables.sql` | Zero-cluster-management compute (`SERVERLESS = True`), vectorized SQL execution (`PHOTON = True`), and governed lineage/volumes (`config.py` L22–23; `Lifecycle table.png`). |
| **`databricks.sdk` (`WorkspaceClient`)** | `03_setup_schedules.py`, `02_data_quality_validation` | Programmatic Lakeview dashboard refresh scheduling (`Schedule`, `CronSchedule`) and job run inspection without manual UI clicks (`03_setup_schedules.py` L114–117). |

**Please reply with `"Approve Phase 4"` to proceed to Phase 4 — Engineering and operations (lifecycle, testing, security, governance, monitoring, cost, issues/fixes, and recommendations).**
