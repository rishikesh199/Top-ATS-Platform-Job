# Phase 2 — Databricks & Cloud Architecture (HLD, LLD & Orchestration)

**Project:** Top ATS Platform Jobs — Stapply Job Market Data Engineering Pipeline  
**Status:** Phase 2 Complete — **AWAITING EXPLICIT USER APPROVAL BEFORE PHASE 3**  
**Primary Archive:** `stapply-deploymentNewacc.zip` (`2026-10-08T09:17:31Z`), contextualized with `stapply-deployment.zip`, `Archive/stapply-pipeline-enterprise.zip`, `Stapply-Export-Dev/`, and `Portfolio/AWS_setup.txt`.  
**Sensitivity Rule:** All S3 bucket names, AWS Account IDs, IAM/VPC/ECS/Subnet/SG IDs, Databricks workspace URLs/IDs, and emails are redacted/anonymized (`<S3_BUCKET>`, `<AWS_ACCOUNT_ID>`, `<ALERT_EMAIL>`).

---

## 1. High-Level Architecture (HLD)

The platform implements a **hybrid cloud lakehouse architecture** separating external data acquisition (AWS serverless containers) from declarative lakehouse processing and BI serving (Databricks Serverless + Unity Catalog + Lakeview):

1. **External Source Feed:** Public ATS aggregator endpoint serving a daily full snapshot (`all.parquet`, ~5.1M rows, ~2.1–2.2 GiB) (`stapply-deploymentNewacc.zip::config.py` / `Portfolio/AWS_setup.txt` lines 50–53; `CloudWatch logs.png`).
2. **AWS Serverless Ingestion (`eu-north-1`):** EventBridge Scheduler triggers an ECS Fargate container daily at `09:00 IST` (`cron(0 9 * * ? *)`, `Asia/Kolkata`), streaming `all.parquet` directly into date-partitioned S3 storage (`snapshot_date=YYYY-MM-DD/all.parquet`) (`Portfolio/AWS_setup.txt` lines 64–70, 881–906; `EventBridge Scheduler.png`).
3. **Databricks Lakeflow SDP & Unity Catalog (`workspace.default` in Gen 3):**
   - **Bronze Layer:** Auto Loader (`STREAM(read_files(...))`) ingests raw S3 Parquet into `bronze_raw`, feeding `AUTO CDC ... FROM SNAPSHOT ... STORED AS SCD TYPE 2` into `bronze_jobs` (`transformations/bronze/bronze.sql` lines 10–52).
   - **Silver Layer:** `silver_enriched` Materialized View applies 9 cleaning/standardization stages, 14 derived columns (including 36-branch V2 role taxonomy), and 4 `CONSTRAINT ... EXPECT` data quality expectations (`transformations/silver/silver.sql` lines 9–164).
   - **Gold Layer:** 6 clustered Materialized Views (`gold_country_market_summary`, `gold_country_role_summary`, `gold_country_role_company_summary`, `gold_country_role_location_summary`, `gold_job_market_explorer`, `gold_daily_movement`) (`transformations/gold/gold.sql` lines 10–148).
4. **BI & Serving Layer:** 3-page, 22-dataset Databricks Lakeview dashboard (`Top ATS Platform Job Market`) covering `Current Snapshot`, `Daily Job Movement`, and `Job Lifecycle` (`Top ATS Platform Job Market.lvdash.json` lines 663, 1966, 2711; `Dash (1).png`, `Dash (3)–(9).png`, `dASHBOARD SECOND PAGE.png`, `3rd page.png`).

---

## 2. Cloud Infrastructure (AWS LLD)

Verified from `Portfolio/AWS_setup.txt` (lines 4–907), `Archive/Dockerfile` (lines 1–13), and screenshots (`ECR.png`, `ECS cluster.png`, `ECS task definition.png`, `EventBridge Scheduler.png`, `Networking&VPC.png`, `CloudWatch logs.png`, `IAM.png`):

| AWS Service | Component / Spec | Configuration & Evidence | Verification Status |
|---|---|---|---|
| **Amazon ECR** | Private container registry (`stapply-fargate-ingestion`, `eu-north-1`) | Tag mutability `Mutable`, `AES-256` encryption (`AWS_setup.txt` L4–31; `ECR.png`). Base image `python:3.12-slim` with `tzdata`, `boto3`, `requests` (`Archive/Dockerfile` L1–13). | `[Runtime-Observed]` |
| **Amazon ECS (Fargate)** | Cluster `stapply-fargate-cluster`, Task `stapply-fargate-ingestion` | `awsvpc` network mode, `FARGATE` compatibility, `1024` CPU units (1 vCPU), `2048` MiB memory (`AWS_setup.txt` L473–479; `ECS cluster.png`, `ECS task definition.png`). | `[Runtime-Observed]` |
| **Streaming Uploader (`app.py`)** | Multipart S3 streaming | `requests.get(stream=True, timeout=(60, 1800))`, `8 MiB` read chunks buffered to `64 MiB` S3 multipart parts (`AWS_setup.txt` L61–130). Writes to `s3://<S3_BUCKET>/raw/stapply/snapshots/snapshot_date=YYYY-MM-DD/all.parquet`. | `[Runtime-Observed]` (`ExitCode: 0`, ~2.12 GiB in `CloudWatch logs.png`) |
| **Networking (VPC)** | Default VPC in `eu-north-1` | 1 VPC, 3 Subnets, 1 Route Table, 1 Internet Gateway, 2 Security Groups, **0 NAT Gateways** (`Networking&VPC.png`; `AWS_setup.txt` L396–461). Avoids NAT Gateway data-processing cost by using public IP + IGW. | `[Runtime-Observed]` |
| **EventBridge Scheduler** | `stapply-daily-fargate-ingestion` | `default` schedule group, `cron(0 9 * * ? *)`, timezone `Asia/Kolkata`, state `ENABLED`, target `ECS_RunTask` (`AWS_setup.txt` L881–906; `EventBridge Scheduler.png`). | `[Runtime-Observed]` |
| **Amazon S3 & IAM** | Snapshot store + cross-account access | `DatabricksStapplyS3Role`, `stapply-fargate-execution-role`, `stapply-fargate-ingestion-task-role`, `stapply-fargate-scheduler-role` (`IAM.png`; `AWS_setup.txt` L269–359, 695–880). | `[Runtime-Observed]` |
| **CloudWatch Logs** | `/ecs/stapply-fargate-ingestion` | `awslogs` driver in `eu-north-1` (`AWS_setup.txt` L501–508; `CloudWatch logs.png`). | `[Runtime-Observed]` |

---

## 3. Databricks Configuration & Lakeflow SDP (LLD)

### 3.1 Central Configuration (`stapply-deploymentNewacc.zip::config.py`)
Verified from `config.py` (lines 12–52):
- **Storage & Catalog:** `S3_BUCKET` → `S3_PATH` (`s3://<S3_BUCKET>/raw/stapply/snapshots/`), `CATALOG = "workspace"`, `SCHEMA = "default"`.
- **Compute & Engine:** `SERVERLESS = True`, `PHOTON = True`, `CHANNEL = "CURRENT"`, `DEVELOPMENT_MODE = True` (note: line 24 comment states *"Set False for production (enables retries)"*).
- **Scheduling (`Newacc`):** `PIPELINE_SCHEDULE_CRON = "0 30 9 * * ? *"` (09:30 IST), `DASHBOARD_REFRESH_CRON = "0 0 10 * * ? *"` (10:00 IST), `SCHEDULE_TIMEZONE = "Asia/Kolkata"`.

### 3.2 Declarative Data Flow (9 Objects Across 3 SQL Files)

| Layer | Object Name & Type | Clustering / Keys | Key Logic & Quality Rules | Evidence |
|---|---|---|---|---|
| **Bronze** | `bronze_raw` (Streaming Table) | — | Auto Loader `STREAM(read_files(..., format => 'parquet'))` + `CONSTRAINT valid_url EXPECT (url IS NOT NULL) ON VIOLATION DROP ROW`. *(Note: `Newacc` hardcodes concrete S3 URI on L7, L16 instead of `{{S3_PATH}}`.)* | `bronze.sql` L10–18; `SDP pipeline (3).png` (`5.1M` rows, `55s`) |
| **Bronze** | `bronze_jobs` (Streaming Table) | `CLUSTER BY (url)` | `CREATE FLOW bronze_snapshot_cdc AS AUTO CDC INTO bronze_jobs FROM SNAPSHOT (...) WITH VERSION (SELECT snapshot_date ... ORDER BY snapshot_date LIMIT 1) KEYS (url) STORED AS SCD TYPE 2 TRACK HISTORY ON` 13 tracked attributes. Preserves active (`__END_AT IS NULL`) and removed (`__END_AT IS NOT NULL`) rows. | `bronze.sql` L21–52; `SDP pipeline (1).png` |
| **Silver** | `silver_enriched` (Materialized View) | `CLUSTER BY (country_iso_clean)` | Consolidates 9 legacy Silver stages into 1 MV with 14 derived columns + 4 expectations (`url_not_null` `ON VIOLATION DROP ROW`, `title_not_empty`, `company_not_empty`, `valid_country_iso`). | `silver.sql` L9–164; `SDP pipeline (3).png` (`6.9M` rows, `2m 0s`, `2 met \| 2 unmet`, `414K` warnings) |
| **Gold** | `gold_country_market_summary` (MV) | `CLUSTER BY (country_iso)` | Active jobs (`__END_AT IS NULL`) aggregated by country. | `gold.sql` L10–35 |
| **Gold** | `gold_country_role_summary` (MV) | `CLUSTER BY (country_iso, role_family)` | Active jobs by country + V2 role family. | `gold.sql` L40–55 |
| **Gold** | `gold_country_role_company_summary` (MV) | `CLUSTER BY (country_iso, role_family)` | Per-company metrics + job age buckets (`Fresh`, `Recent`, `Ageing`, `Older`). | `gold.sql` L59–81 |
| **Gold** | `gold_country_role_location_summary` (MV) | `CLUSTER BY (country_iso, role_family)` | Per-location breakdown (non-empty locations). | `gold.sql` L85–104 |
| **Gold** | `gold_job_market_explorer` (MV) | `CLUSTER BY (country_iso_clean, role_family)` | Full active + historical explorer with `__START_AT AS first_seen_at`, `__END_AT AS removed_at`, `lifecycle_status` (`Active`/`Removed`). | `gold.sql` L108–128; `SDP pipeline (3).png` (`6.9M`, `27s`) |
| **Gold** | `gold_daily_movement` (MV) | — | `UNION ALL` of `New` (`DATE(__START_AT)`) and `Removed` (`DATE(__END_AT)`) counts from `bronze_jobs`. | `gold.sql` L132–148; `SDP pipeline (3).png` (`4s`, `17` rows) |

---

## 4. Orchestration & 3-Generation Architectural Comparison

| Dimension | Gen 1 (`Stapply-Export-Dev/`) | Gen 2 (`stapply-pipeline-enterprise.zip`) | Gen 3 (`stapply-deployment.zip` / `Newacc`) |
|---|---|---|---|
| **Ingestion** | Databricks Serverless (`01_snapshot_acquisition` → UC Volume → S3) | AWS ECS Fargate (`09:00 IST`) → S3 | AWS ECS Fargate (`09:00 IST`) → S3 |
| **Databricks Tasks** | 4-task Job (`snapshot_acquisition` → `dq_gate` → `lifecycle_processing` → `monitoring`) | 7-task Job (`01`→`02`→`04`→`03`→`05`→`06`→`07`) | Declarative SDP Pipeline (`01_deploy.py`) + Job/Refresh Automation |
| **Scheduling Variant** | `0 0 9 ? * *` (`PAUSED` in JSON) | `0 30 9 * * ?` (`UNPAUSED` per `stapply_master_guide.md` L119–120) | **`stapply-deployment.zip`:** Unified 2-task job (`run_sdp_pipeline` → `refresh_dashboard`, `[Runtime-Observed]` Oct 2–5, `7m 50s–8m 09s`).<br>**`Newacc`:** Separate `03_setup_schedules.py` (`09:30` job + `10:00` Lakeview refresh) `[Implemented / Unverified Runtime]`. |
| **Storage Objects** | 7 Delta Gold tables | 30 Delta tables (`1` Bronze, `9` Silver, `7` Gold Core, `13` Gold Analytical) | 9 Lakeflow SDP objects (`2` Streaming Tables, `7` MVs) |
| **Observed Runtime** | Mixed (`3 FAILED`, `2 SUCCESS` in `recent_runs.json`) | `~14–15m` green (`Task run log.png`, `Run_log.png`) | `~8m` green (`SDP pipeline (2).png`–`(3).png`) |

---

## 5. Planned Local Diagrams (Evidence-Backed Specifications)

All diagrams will be built locally as **inline SVG / HTML+CSS** in Phase 6 (zero external CDN or rendering services):

1. **Diagram 1 — Overall Cloud & Lakehouse HLD (SVG):**
   - Nodes: `Stapply API (all.parquet)` → `EventBridge (09:00 IST)` → `ECS Fargate (1 vCPU / 2 GB, 64 MiB Multipart)` → `AWS S3 (Dated Parquet)` → `Unity Catalog External Location` → `Databricks Lakeflow SDP (Serverless + Photon)` → `Lakeview Dashboard (3 Pages, 22 Datasets)`.
   - Sources: `AWS_setup.txt`, `Dockerfile`, `config.py`, `bronze.sql`, `silver.sql`, `gold.sql`, `CloudWatch logs.png`, `SDP pipeline (2).png`.
   - Unknowns labeled: `Newacc` separate `10:00 IST` refresh schedule marked `[Unverified Runtime]`.
2. **Diagram 2 — Lakeflow SDP Medallion & SCD Type 2 Data Flow (SVG):**
   - Shows `bronze_raw` (Auto Loader + `valid_url` drop) → `bronze_jobs` (`AUTO CDC FROM SNAPSHOT` SCD2 `__START_AT`/`__END_AT`) → `silver_enriched` (4 `CONSTRAINT` expectations, 14 derived columns) → 6 Gold MVs → 3 Dashboard tabs.
   - Sources: `bronze.sql`, `silver.sql`, `gold.sql`, `SDP Pipeline.png`, `SDP pipeline (1).png`, `SDP pipeline (3).png`.
3. **Diagram 3 — 3-Generation Architecture Evolution & Orchestration (HTML+CSS / SVG):**
   - Compares Gen 1 (4 tasks / 7 tables) → Gen 2 (AWS Fargate + 7 tasks / 30 tables, `~14–15m`) → Gen 3 (AWS Fargate + 3 SQL files / 9 SDP objects, `~8m`).
   - Sources: `stapply_daily_pipeline.json`, `stapply-pipeline-enterprise.zip::manifest.json`, `03_before_after_comparison.py`, `Task run log.png`, `SDP pipeline (2).png`.

---

## 6. Flagged Unknowns & Architectural Observations

1. **`DEVELOPMENT_MODE = True` in `config.py` (Line 24):** Both `stapply-deployment.zip` and `stapply-deploymentNewacc.zip` ship with `DEVELOPMENT_MODE = True` (which disables production retries per line 24's own comment). Whether the live Oct 2–5 workspace pipeline was toggled to `False` in UI is `[Unverified]`.
2. **`stapply-deploymentNewacc.zip` Execution & Template Regression:** `03_setup_schedules.py` and `01_deploy.py` (`embed_credentials: False`) have no runtime screenshot/log proof, and `bronze.sql` lines 7, 16 hardcode the S3 URI rather than `{{S3_PATH}}`.
3. **No AWS Infrastructure-as-Code (Terraform/CDK/CloudFormation):** AWS resources were provisioned imperatively via AWS CLI in CloudShell (`Portfolio/AWS_setup.txt`).

**Please reply with `"Approve Phase 3"` to proceed to Phase 3 — Code, notebooks, scripts, and dependencies (file-by-file inventory).**
