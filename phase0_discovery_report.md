# Phase 0 Discovery Report — Stapply Databricks & AWS Pipeline Portfolio

**Status:** Phase 0 (Discovery & Safety) Complete — **STOPPED FOR USER APPROVAL BEFORE PHASE 1**  
**Workspace Inspected:** `c:\New folder\Gemini\Databricks Job project`  
**Output Directory:** `c:\New folder\Gemini\Databricks Job project\portfolio_site\`  
**Evidence Standard:** Every technical claim below distinguishes **[Implemented]**, **[Runtime-Observed]**, **[Documented/Planned]**, and **[Unverified]**, with concrete source citations. Zero files outside `portfolio_site\` were modified, extracted, renamed, or deleted.

---

## 1. Inspected Locations & Scope

A full read-only inventory of `c:\New folder\Gemini\Databricks Job project` was conducted prior to generating Phase 0 deliverables:

- **Baseline File Count & Integrity:** `87` files enumerated across all subdirectories and root archives (`baseline_manifest.csv` in the Teamwork survey folder records relative path, byte size, `LastWriteTimeUtc`, and SHA-256 hash for all 87 files).
- **Target Output Directory State:** `portfolio_site\` did **not** exist prior to Phase 0 (`os.path.exists` returned `False`). Only the three Phase 0 Markdown deliverables are created inside `portfolio_site\`.
- **Inspected Root & Subdirectories:**
  1. **Root directory (`.`)**: 4 deployment/export archives (`Stapply-Export-Dev.zip`, `stapply-deployment.dbc`, `stapply-deployment.zip`, `stapply-deploymentNewacc.zip`).
  2. **`Archive\`** (11 files + 1 unpacked subfolder): 6 historical/reference `.zip` archives (`ats-scrapers-main.zip`, `stapply-main.zip`, `stapply-book.zip`, `stapply-documentation.zip`, `stapply-pipeline-enterprise.zip`, `stapply-deployment.zip`), 5 loose files (`01_snapshot_acquisition`, `03_before_after_comparison.py`, `Dockerfile`, `stapply_master_guide.md`, `stapply_portal.html`), and 1 unpacked folder `Archive\stapply-deployment\` (9 files total: 8 files inside `stapply-deployment\` plus `manifest.mf`).
  3. **`Portfolio\`** (42 files + 6 empty scaffold directories): generic starter template (`index.html`, `README.md`, `assets/css/style.css`, `assets/css/animations.css`, `assets/js/main.js`), raw AWS CloudShell setup log (`AWS_setup.txt`), and **36** `.png` screenshots in `Portfolio\assets\images\projects\`. Empty scaffold directories: `Portfolio\docs\`, `Portfolio\sections\`, `Portfolio\assets\fonts\`, `Portfolio\assets\images\backgrounds\`, `Portfolio\assets\images\icons\`, `Portfolio\assets\images\profile\`.
  4. **`Stapply-Export-Dev\Stapply-Export-Dev\`** (21 files): expanded Databricks workspace export containing `README.md`, `manifest.json`, `chat_history\complete_conversation_log.py`, `config\pipeline_config.md`, `docs\` (3 files), `infra\` (3 files across `dashboards\` and `jobs\`), `ops\` (2 files), `sql\ddl\` (2 files), and `src\` (2 exploratory notebooks + 5 pipeline notebooks).
- **In-Memory Archive Inspection:** All **10** archives (`9` `.zip` + `1` `.dbc`) were inspected read-only via Python `zipfile` without extracting into the workspace.
- **Read-Only Scope Guarantee:** Neither `Portfolio\`, `Archive\`, `Stapply-Export-Dev\`, nor any root `.zip`/`.dbc` file was altered. No Phase 1–7 artifacts (`index.html`, CSS/JS builds, SVG diagrams, copied screenshots) were created.

---

## 2. Candidate ZIP & Archive Comparison

### 2.1 Inventory of All 10 Workspace Archives & Loose Counterparts

| Archive / Loose Folder | Size (Bytes) | Filesystem `LastWriteTimeUtc` | Entries (Files / Dirs) | Internal ZIP Timestamp Range | Role / Generation |
|---|---:|---|---:|---|---|
| `Stapply-Export-Dev.zip` | 118,907 | `2026-09-29T12:23:28Z` | 18 (18 / 0) | `2026-09-29T12:23:22` .. `12:23:26` | Gen 1 baseline export (4-task Databricks job, 7 Gold tables) |
| `Stapply-Export-Dev\Stapply-Export-Dev\` *(loose)* | — | `2026-09-29` .. `2026-09-30T04:37:58Z` | 21 files | — | Evolved Gen 1 export (+3 files: `00_config`, `00_job_creator`, `00_setup_tables`; `01..04` updated) |
| `Archive\ats-scrapers-main.zip` | 3,366,481 | `2026-09-30T13:37:57Z` | 275 (259 / 16) | `2026-09-02T13:51:04` | Upstream OSS scraper repo producing the public dataset (`README.md`) |
| `Archive\stapply-main.zip` | 4,601,604 | `2026-09-30T13:38:50Z` | 207 (144 / 63) | `2026-05-13T02:42:02` | Upstream OSS Stapply web/API repo (`README.md`, `SETUP.md`) |
| `Archive\stapply-book.zip` | 128,391 | `2026-09-30T18:13:52Z` | 8 (8 / 0) | `2026-09-30T18:13:48` | Documentation book (`part1..5.md`, `medallion_redesign_sep30_2026.md`, HTML + combined `.md`) |
| `Archive\stapply-documentation.zip` | 66,989 | `2026-09-30T18:13:52Z` | 7 (7 / 0) | `2026-09-30T18:13:48` | Gen 2 documentation (`long_detailed_documentation.md`, `short_documentation.md`, `timeline.md`, `screenshot_checklist.md`, `code_index.md`, `diagrams/README.md`, `stapply_portal.html`) |
| `Archive\stapply-pipeline-enterprise.zip` | 69,248 | `2026-09-30T18:21:34Z` | 20 (20 / 0) | `2026-09-30T18:21:30` .. `18:21:32` | Gen 2 Enterprise Medallion package (7-task DAG, 30 Delta tables, AWS Fargate docs, setup scripts) |
| `Archive\stapply-deployment.zip` | 22,524 | `2026-10-01T09:23:34Z` | 15 (9 / 6) | `2026-10-01T09:23:30` | Gen 3 initial Lakeflow SDP deployment package |
| `Archive\stapply-deployment\` *(loose)* | — | `2026-10-08T07:31:57Z` | 9 files | — | Exact byte-for-byte extracted copy of `Archive\stapply-deployment.zip` (`9/9` SHA-256 identical) |
| `stapply-deployment.dbc` | 22,617 | `2026-10-08T09:16:08Z` | 10 (4 / 6) | `2026-10-08T09:10:26` | Incomplete Databricks `.dbc` export (`manifest.mf` + 3 `.python` notebooks only; `0` saved cell outputs) |
| `stapply-deployment.zip` *(root)* | 32,892 | `2026-10-08T09:16:11Z` | 9 (9 / 0) | `2026-10-08T09:11:12` .. `09:11:14` | Gen 3 SDP self-contained package (`01_deploy.py` 8-step + `03_before_after_comparison.py` + `{{S3_PATH}}` template) |
| `stapply-deploymentNewacc.zip` *(root)* | 30,291 | `2026-10-08T09:17:31Z` | 10 (10 / 0) | `2026-10-08T09:13:24` | Gen 3/4 variant (`03_setup_schedules.py` + `.lvdash.json` + hardcoded S3 path in `bronze.sql`) |

### 2.2 Explicit Structural & Code Divergence Across Deployment Candidates

1. **`Archive\stapply-deployment.zip` (`2026-10-01`) vs. loose `Archive\stapply-deployment\` (`2026-10-08T07:31Z`):**
   - **9/9 files are SHA-256 identical.** The unpacked directory is an unmodified extraction of the `2026-10-01` archive.
2. **Root `stapply-deployment.zip` (`2026-10-08T09:16:11Z`) vs. `Archive\stapply-deployment.zip` (`2026-10-01`):**
   - **6 identical files:** `02_handover_guide.py`, `README.md`, `dashboard/dashboard_config.json`, `transformations/bronze/bronze.sql`, `silver.sql`, `gold.sql`.
   - **2 upgraded files:** `01_deploy.py` expands from 331 lines (13,942 B) to 466 lines (21,362 B), pointing pipeline libraries directly to `DEPLOY_DIR_CLEAN/transformations/...` (lines 105–107) and adding `Step 8: Setup Automation (Job + Dashboard Schedule)` inline (lines 319–466) to create a unified 2-task job (`run_sdp_pipeline` → `refresh_dashboard`). `config.py` expands from 43 lines (2,565 B) to 49 lines (2,906 B), adding `WAREHOUSE_ID`.
   - **1 added file:** `03_before_after_comparison.py` (37,127 B, 651 lines; byte-identical to loose `Archive\03_before_after_comparison.py`). `manifest.mf` is removed.
3. **`stapply-deploymentNewacc.zip` (`2026-10-08T09:17:31Z`) vs. Root `stapply-deployment.zip` (`2026-10-08T09:16:11Z`):**
   - **4 identical files:** `02_handover_guide.py`, `dashboard/dashboard_config.json`, `silver.sql`, `gold.sql`.
   - **Diverged `01_deploy.py`:** `stapply-deploymentNewacc.zip` reverts `01_deploy.py` to the `Archive\stapply-deployment.zip` 7-step lineage (335 lines, 14,049 B) using `/Users/{current_user}/stapply_sdp_{hash_suffix}` (line 107), adding only a 4-line `# /// script` Databricks environment header (lines 2–5), `,importlib` (line 29), and `embed_credentials: False` on publish (line 282 within the `requests.post` block on lines 278–283). It omits Step 8 automation.
   - **Diverged `config.py`:** `stapply-deploymentNewacc.zip` (52 lines, 3,147 B) omits `WAREHOUSE_ID` and adds `PIPELINE_SCHEDULE_CRON`, `DASHBOARD_REFRESH_CRON`, `SCHEDULE_TIMEZONE`, `PIPELINE_JOB_NAME`, and `DASHBOARD_REFRESH_NAME`.
   - **Diverged `bronze.sql`:** Root `stapply-deployment.zip` retains `'{{S3_PATH}}'` template substitution (`bronze.sql` lines 7 and 16), whereas `stapply-deploymentNewacc.zip` hardcodes a concrete S3 URI on lines 7 and 16 (1,933 B vs 1,855 B), bypassing `01_deploy.py` Step 2 rendering.
   - **Exclusive files:** Root `stapply-deployment.zip` uniquely contains `03_before_after_comparison.py` (SDP metrics/audit notebook). `stapply-deploymentNewacc.zip` uniquely contains `03_setup_schedules.py` (162 lines; configures separate pipeline job and Lakeview refresh schedules), `Top ATS Platform Job Market.lvdash.json` (differs from `dashboard/dashboard_config.json` only in literal em-dash `—` vs `\u2014` on lines 663, 1966, 2711), and an expanded `README.md` (99 lines vs 79 lines, documenting `03_setup_schedules`).
4. **`stapply-deployment.dbc` (`2026-10-08T09:16:08Z`):**
   - Contains only `manifest.mf` and 3 Databricks notebook JSONs (`01_deploy.python`, `02_handover_guide.python`, `03_before_after_comparison.python`), mirroring the root `stapply-deployment.zip` feature set without `config.py`, `*.sql`, or `dashboard_config.json`. All 3 notebooks have `commands_with_results = 0`.
5. **Earlier Gen 1 / Gen 2 Lineage (`Stapply-Export-Dev*` and `Archive\stapply-pipeline-enterprise.zip`):**
   - `Stapply-Export-Dev\` (`2026-09-30`) is a strict superset of `Stapply-Export-Dev.zip` (`2026-09-29`), adding `00_config`, `00_job_creator`, and `00_setup_tables` and updating `01..04` to `%run ./00_config`.
   - `Archive\stapply-pipeline-enterprise.zip` (`2026-09-30T18:21:34Z`) represents the Gen 2 7-task Medallion architecture (`01..07`, 30 Delta tables) paired with AWS Fargate ingestion (`infra/aws/fargate_setup.md`).

### 2.3 Selection Verdict & User Question

No single deployment ZIP can be declared unambiguously authoritative from verifiable evidence alone: `stapply-deploymentNewacc.zip` has the latest timestamp (`2026-10-08T09:17:31Z`) and modular scheduling (`03_setup_schedules.py`), **but** regresses `01_deploy.py` to the older 7-step `/Users/...` deployment flow, hardcodes an S3 URI in `bronze.sql`, and lacks `03_before_after_comparison.py` as well as any runtime verification proof. Meanwhile, `stapply-deployment.zip` (`2026-10-08T09:16:11Z`) contains the clean parameterized `01_deploy.py` (Steps 1–8), `{{S3_PATH}}` templating, and `03_before_after_comparison.py`, matching the `SDP pipeline (2).png` 2-task job screenshot (`Oct 2–5, 2026`).

**Question for the User:** Between `stapply-deployment.zip` and `stapply-deploymentNewacc.zip`, which archive should be treated as the canonical current deployment package (or should both be documented as main-account vs. new-account variants alongside Gen 1/Gen 2 evolution)?

---

## 3. High-Level Project File Inventory

### 3.1 Categorized Inventory

| Category | Location(s) | Key Contents | Purpose / Generation |
|---|---|---|---|
| **Gen 3/4 Lakeflow SDP Deployment Packages** | Root: `stapply-deployment.zip`, `stapply-deploymentNewacc.zip`, `stapply-deployment.dbc`; `Archive\stapply-deployment.zip`, `Archive\stapply-deployment\`, `Archive\03_before_after_comparison.py` | `01_deploy.py`, `02_handover_guide.py`, `03_setup_schedules.py` / `03_before_after_comparison.py`, `config.py`, `README.md`, `transformations/{bronze,silver,gold}/*.sql`, `dashboard/dashboard_config.json`, `.lvdash.json` | Declarative Lakeflow SDP pipeline (3 SQL files → 9 objects), automated deployment/scheduling, Lakeview dashboard, before/after comparison |
| **Gen 2 Enterprise Medallion Package & Docs** | `Archive\stapply-pipeline-enterprise.zip`, `Archive\stapply_master_guide.md`, `Archive\stapply_portal.html`, `Archive\stapply-book.zip`, `Archive\stapply-documentation.zip` | `config/00_config.py`, `pipeline/01..07`, `setup/00_*.py`, `env.template`, `manifest.json`, `infra/aws/fargate_setup.md`, `infra/databricks/*`, `docs/*`, `part1..5.md`, `timeline.md`, `screenshot_checklist.md` | 7-task Medallion redesign (30 Delta tables: 1 Bronze, 9 Silver, 7 Gold Core, 13 Gold Analytical) + architectural documentation |
| **Gen 1 Workspace Exports** | `Stapply-Export-Dev.zip`, `Stapply-Export-Dev\Stapply-Export-Dev\`, `Archive\01_snapshot_acquisition` | `src/pipelines/00..04`, `src/notebooks/*`, `sql/ddl/{00_setup_tables,gold_tables.sql}`, `infra/jobs/*`, `infra/dashboards/job_market_dashboard.json`, `ops/{recent_runs.json,run_summary.md}`, `docs/*`, `chat_history/complete_conversation_log.py` | Initial 4-task Databricks job (`snapshot_acquisition` → `dq_gate` → `lifecycle_processing` → `monitoring`), 7 Gold tables, run telemetry, narrative chat log |
| **AWS Fargate Ingestion & Setup** | `Portfolio\AWS_setup.txt`, `Archive\Dockerfile`, `Archive\stapply-pipeline-enterprise.zip::infra/aws/fargate_setup.md` | CloudShell provisioning transcript (S3, ECR, IAM, VPC, ECS Fargate task, EventBridge Scheduler, CloudWatch logs) and `python:3.12-slim` container definition (`boto3`, `requests`) | Daily serverless container downloading external `all.parquet` (~2.1–2.2 GB) to S3 via 64 MiB multipart streaming |
| **Starter Portfolio Template & Visual Evidence** | `Portfolio\index.html`, `Portfolio\README.md`, `Portfolio\assets\css\{style,animations}.css`, `Portfolio\assets\js\main.js`, `Portfolio\assets\images\projects\*.png` (36 files) | Generic starter HTML/CSS/JS skeleton (`"Your Name"`, `project1..3.png`) plus 36 AWS & Databricks screenshots | Existing template (to remain untouched) and raw visual evidence inventory |
| **Upstream External Source Repositories** | `Archive\ats-scrapers-main.zip` (259 files), `Archive\stapply-main.zip` (144 files) | External open-source scraper suite (`src/`, `ats-companies/`, `pipeline/`, `tests/`) and Next.js/Drizzle web app (`src/`, `server/`, `docker/`) | Upstream origin of the public `all.parquet` dataset; not authored Databricks pipeline code |

### 3.2 Exclusion of Irrelevant Generated / Vendor / Cache / Build Artifacts

- **Loose workspace (`c:\New folder\Gemini\Databricks Job project`):** Verified `0` directories or files matching `node_modules`, `.git`, `__pycache__`, `.venv`, `venv`, `dist`, `build`, `.next`, `.pytest_cache`, or `.mypy_cache`.
- **Inside archives:** `Archive\ats-scrapers-main.zip` contains upstream CI/dependency/test files (`.github/` [4 files], `.gitignore`, `uv.lock`, `tests/` [102 files]) and `Archive\stapply-main.zip` contains upstream frontend/tooling configs (`.gitignore`, `package-lock.json`, `eslint.config.mjs`, `next.config.ts`, `tsconfig.json`), with **zero** compiled `node_modules/`, `.next/`, `__pycache__/`, or `.venv/` artifacts. All upstream repo internals are excluded from authored pipeline scope.

---

## 4. Screenshot Filenames & Verifiable Observations

All **36** `.png` files in `Portfolio\assets\images\projects\` were inspected. Dimensions, byte sizes, and UTC timestamps were verified directly from file headers and filesystem metadata.

| # | Exact Filename | Dimensions | Size (B) | `LastWriteTimeUtc` | Strictly Verifiable Visual Observations | Redaction / Disposition Flag |
|---:|---|---:|---:|---|---|---|
| 1 | `00_config.png` | 1062×921 | 156,457 | `2026-09-30T12:27:55Z` | Databricks notebook `00_config` showing auto-derived `TBL_*` variables, `SNAPSHOT_RETENTION_DAYS = 5`, `REMOVAL_CONFIRMATION_DAYS = 2`. | Clean (cropped; no sensitive values visible). |
| 2 | `3rd page.png` | 1669×877 | 171,292 | `2026-10-05T06:59:05Z` | Lakeview dashboard `Job Lifecycle` tab: KPIs `Active Jobs 5M`, `Removal Candidates 0`, `Confirmed Removed 2M`, `Reappeared Jobs 0`, `Total Tracked Jobs 7M`, `Avg Times Seen (Active) 1`; `Lifecycle Status` (`5.1M` Active, `1.77M` Removed) and `First Seen Distribution` (`Sep 26`–`Oct 05, 2026`) charts. | Clean. |
| 3 | `Bronze table.png` | 575×678 | 58,945 | `2026-09-30T12:40:27Z` | Databricks Catalog sidebar showing `bronze` (`Tables (1)` → `stapply_jobs`) and `silver` (`Tables (9)` → `stapply_jobs`..`stapply_jobs_text_checked`). | Clean (duplicate SHA-256 of `Dash (2).png`). |
| 4 | `Bucket + rawstapplysnapshots + snapshot-date folders..png` | 1849×789 | 120,594 | `2026-09-30T11:50:33Z` | AWS S3 Console listing 5 partition folders (`snapshot_date=2026-09-25/` through `2026-09-28/` and `2026-09-30/`). | Image interior cropped (bucket name not visible inside PNG), though disk filename references bucket/folder naming. |
| 5 | `CloudWatch logs.png` | 1439×511 | 56,378 | `2026-09-30T12:16:35Z` | CloudWatch log events (`2026-09-30T06:02:39Z`): source URL, target S3 location, `Snapshot date: 2026-09-30`, `Source Content-Length`: ~2.12 GiB (2,273,690,124 bytes), multipart parts 1–4 (`0.06`–`0.25 GiB`). | **FLAGGED (`Message` column row 2):** Full S3 URI and bucket prefix visible. |
| 6 | `Dash (1).png` | 1897×941 | 93,106 | `2026-09-30T12:46:19Z` | Lakeview `Job Lifecycle` tab on Sep 30 baseline: `Active Jobs 5M`, `Total Tracked Jobs 5M`, `0` Removed; `5.14M` bar (`Sep 30, 2026`). | Clean. |
| 7 | `Dash (2).png` | 575×678 | 58,945 | `2026-09-30T12:40:27Z` | **Exact byte-for-byte duplicate** of `Bronze table.png` (SHA-256 `79450176...`; Unity Catalog sidebar, not a dashboard view). | **DUPLICATE:** Omit from dashboard gallery. |
| 8 | `Dash (3).png` | 1595×880 | 107,231 | `2026-09-30T12:43:36Z` | Lakeview `Current Job Market` (`Current Snapshot`) tab: 6 filters (`Country`, `Role Family`, `Company`, `Remote Status`, `Age Bucket`, `ATS Type`); KPIs `Active Jobs 5.1M`, `Companies 479.6K`, `Countries 87`, `Fresh Jobs 436.4K`, `Remote Jobs 142.1K`, `With Salary 236.7K`. | Clean. |
| 9 | `Dash (4).png` | 1598×879 | 187,086 | `2026-09-30T12:43:52Z` | `Current Job Market`: `Avg Salary Range by Country` (`IN 731.19K`, `CA 112.61K`, `IE 110.28K`, `GB 106.15K`) and `Top Hiring Trends` table (public job-board employers). | Clean. |
| 10 | `Dash (5).png` | 1609×881 | 207,124 | `2026-09-30T12:44:12Z` | `Current Job Market` (with `Edit draft` bar): `Top 15 Countries` (`DE 1.04M`, `US 914.14K`, `FR 436.7K`) and `Top 15 Role Families` (`Other 2.62M`, `Healthcare/Medical 372.1K`, `Retail/Hospitality 315.44K`). | Clean. |
| 11 | `Dash (6).png` | 1909×856 | 166,587 | `2026-09-30T12:44:48Z` | Same two charts (`Top 15 Countries`, `Top 15 Role Families`) scrolled lower without the `Edit draft` bar. | Clean. |
| 12 | `Dash (7).png` | 1895×848 | 138,017 | `2026-09-30T12:45:10Z` | `Current Job Market`: `Top 15 Companies` (`Accenture 34.11K`, `dominos 24.83K`) and `Job Age Distribution` (`Date Unknown 1.33M`, `Older 1.18M`, `Recent 1.17M`, `Ageing 1.02M`, `Fresh 436.36K`). | Clean. |
| 13 | `Dash (8).png` | 1883×829 | 180,115 | `2026-09-30T12:45:21Z` | `Current Job Market`: `Remote vs Non-Remote` donut (`82.43%` Unknown, `14.81%` Not Remote), `Salary by Currency` (`USD 151.749K`, `EUR 88.394K`, `CAD 68.775K`), `ATS Platform` (`eures 1.401661M`, `workday 847.478K`, `bundesagentur 473.365K`). | Clean. |
| 14 | `Dash (9).png` | 1872×904 | 83,701 | `2026-09-30T12:46:05Z` | `Daily Job Movement` tab on Sep 30 baseline: `New Jobs 5M`, `Removed 0`, `Reappeared 0`, `Net Active Change 5M`; `Daily Movement Trend` (`5.14M`, `Sep 30, 2026`). | Clean. |
| 15 | `ECR.png` | 1878×526 | 118,779 | `2026-09-30T11:54:09Z` | Amazon ECR private repository `stapply-fargate-ingestion`, `eu-north-1`, created `Sep 30, 2026 11:02:03 (UTC+05:30)`, `Mutable`, `AES-256`. | **FLAGGED (Center `URI` column):** Attempted black marker redaction over 12-digit AWS Account ID is partially legible underneath. |
| 16 | `ECS cluster.png` | 1851×413 | 115,117 | `2026-09-30T12:03:27Z` | Amazon ECS Clusters list showing `stapply-fargate-cluster` (`0` services, `No tasks running`, `0 EC2`). | Clean. |
| 17 | `ECS task definition.png` | 1328×376 | 64,425 | `2026-09-30T12:08:54Z` | ECS Task definitions list showing `stapply-fargate-ingestion`, `Active`, updated `Sep 30, 2026 17:38 (UTC+5:30)`. | Clean. |
| 18 | `EventBridge Scheduler.png` | 1395×442 | 72,445 | `2026-09-30T12:12:14Z` | EventBridge Schedule `stapply-daily-fargate-ingestion` (`default` group, `Enabled`, target `stapply-fargate-cluster`, `ECS_RunTask`, modified `Sep 30, 2026 06:14:30 UTC`). | Clean. |
| 19 | `Fargate source code.png` | 1847×602 | 45,243 | `2026-09-30T13:16:26Z` | AWS CloudShell (`eu-north-1`) showing top of `~/stapply-fargate/app.py` (`SOURCE_URL`, `BUCKET` env vars). | **FLAGGED (Bottom line):** Concrete S3 bucket name visible in `BUCKET` default. |
| 20 | `Gold tables.png` | 407×389 | 27,439 | `2026-09-30T12:33:31Z` | Unity Catalog `gold` schema listing 7 tables (`company_identity_mapping_v1` through `job_snapshot_run_log`). | Clean. |
| 21 | `IAM.png` | 1878×751 | 209,083 | `2026-09-30T13:01:09Z` | AWS IAM Roles list showing `DatabricksStapplyS3Role`, `stapply-fargate-execution-role`, `stapply-fargate-ingestion-task-role`, `stapply-fargate-scheduler-role`. | **FLAGGED (Center `Trusted entities` column, row 5):** 12-digit external AWS Account ID exposed in plain text. |
| 22 | `Job DAG.png` | 1474×421 | 89,657 | `2026-09-30T12:31:23Z` | Databricks Job `stapply_daily_snapshot_pipeline` 4-task DAG (`snapshot_acquisition` → `dq_gate` → `lifecycle_processing` → `monitoring` [If all done], Serverless). | **FLAGGED (Task cards `snapshot_acquisition`, `dq_gate`):** Partial email/domain suffixes visible in truncated notebook paths. |
| 23 | `Lifecycle table.png` | 1602×917 | 146,366 | `2026-09-30T12:34:46Z` | Unity Catalog `gold.job_lifecycle` schema viewer (`url`, `title_clean`, `company_clean`, etc.) and `Volumes (2)` (`code_infra`, `exports`). | Clean. |
| 24 | `Networking&VPC.png` | 1459×774 | 160,143 | `2026-09-30T12:23:43Z` | AWS VPC dashboard (`Stockholm`): 1 VPC, 3 Subnets, 1 Route Table, 1 Internet Gateway, 2 Security Groups, 0 NAT Gateways. | Clean. |
| 25 | `Run_log.png` | 1278×948 | 163,705 | `2026-09-30T15:38:55Z` | Databricks Job `Runs` view (`Sep 30, 2026`): 7-task Medallion matrix (`lifecycle_processing`, `gold_analytics`, `monitoring`) and run table (`15m 6s` Succeeded, `15m 7s` Succeeded, `9m 4s` Succeeded, `25m 4s` Failed `RunExecutionError`, 2 cancelled). | **FLAGGED (`Run ID` column):** Truncated Databricks numeric Run IDs visible. |
| 26 | `SDP Pipeline.png` | 760×506 | 81,718 | `2026-10-01T08:37:37Z` | Databricks SDP UI header (`Stapply Enterprise SDP Pipeline`) + full lineage graph (`bronze_raw` → `bronze_jobs` → `silver_enriched` → 6 Gold MVs). | **FLAGGED (Leftmost source node):** S3 bucket URI and prefix visible. |
| 27 | `SDP pipeline (1).png` | 1012×476 | 99,221 | `2026-10-05T07:01:01Z` | Databricks SDP lineage graph (`bronze_raw` → `bronze_jobs` → `gold_daily_m...` & `silver_enriched` → 5 Gold MVs). | **FLAGGED (Leftmost source node):** S3 bucket URI and prefix visible. |
| 28 | `SDP pipeline (2).png` | 1087×868 | 62,566 | `2026-10-05T07:14:54Z` | Databricks Job `Stapply SDP Daily Pipeline + Dashboard`: 4 consecutive scheduled runs `Oct 02`–`Oct 05, 2026` at `09:30` (`7m 50s`–`8m 09s`, all `Succeeded`, `run_sdp_pipeline` + `refresh_dashboard`). | **FLAGGED (`Run ID` column):** Truncated numeric Run IDs visible. |
| 29 | `SDP pipeline (3).png` | 1663×537 | 67,875 | `2026-10-05T07:01:34Z` | SDP run metrics: `bronze_raw` (`55s`, `5.1M`, `1 met`), `bronze_jobs` (`1m 55s`), `silver_enriched` (`2m 0s`, `6.9M`, `2 met \| 2 unmet` / `414K`), `gold_job_market_explorer` (`27s`, `6.9M`), 4 summary MVs (`9s` each), `gold_daily_movement` (`4s`, `17`). | Clean. |
| 30 | `Successful Fargate task.png` | 1426×456 | 78,482 | `2026-09-30T12:11:13Z` | ECS Task definition `stapply-fargate-ingestion (2)` revisions `:2` and `:1` both `Active`. | Clean. |
| 31 | `Successful job run-1.png` | 1481×663 | 62,798 | `2026-09-30T12:30:06Z` | `stapply_daily_snapshot_pipeline` `Sep 27` run matrix (4 tasks: 3 failed, 2 green). | Clean. |
| 32 | `Successful snapshot.png` | 1852×559 | 106,061 | `2026-09-30T11:52:02Z` | AWS S3 Console inside `snapshot_date=2026-09-25/` showing `all.parquet` (`2.2 GB`, `Sep 26, 2026 16:20:16 UTC+05:30`, `Standard`). | Clean. |
| 33 | `Task run log.png` | 1011×683 | 70,284 | `2026-09-30T15:39:58Z` | Timeline view of 7-task Medallion run (`Sep 30, 08:51 PM`–`08:59 PM`): all 7 tasks green (`snapshot_acquisition 20.1s`, `bronze_ingestion 1m 13s`, `dq_gate 1m 13s`, `silver_processing 5m 16s`, `lifecycle_processing 2m 51s`, `gold_analytics 3m 25s`, `monitoring 44.6s`). | Clean. |
| 34 | `Updated Run log.png` | 1107×885 | 78,706 | `2026-09-30T15:39:10Z` | Medallion 7-task run matrix showing `12m 31s` scale and latest run green across all 7 tasks. | Clean. |
| 35 | `Workspace project tree.png` | 1098×713 | 86,720 | `2026-09-30T12:25:12Z` | Databricks Workspace `/Workspace/Shared/stapply-pipeline` listing 8 notebooks (`00_config`, `00_dashboard_creator`, `00_job_creator`, `00_setup_tables`, `01..04`) + `Top ATS Platform Job Market` dashboard. | Clean. |
| 36 | `dASHBOARD SECOND PAGE.png` | 1671×891 | 150,217 | `2026-10-05T06:57:48Z` | Lakeview `Daily Job Movement` tab on Oct 5 multi-day data: `Movement by Country` (18 pages), `Movement by Role Family` (12 pages), `Country + Role Drill-Down` (281 pages) with `2026-09-26` to `2026-10-05` rows. | Clean. |

---

## 5. Chat-Export Status

- **Raw Verbatim Chat Export Status:** **MISSING.** A recursive search across all 87 workspace files and all entries inside all 10 archives found **zero** raw/verbatim exported conversation files (e.g., `.json`, `.md`, `.txt`, or `.html` platform exports).
- **Existing Narrative Summary Artifact:** `Stapply-Export-Dev\Stapply-Export-Dev\chat_history\complete_conversation_log.py` (684 lines, 40,032 B; identical copy inside `Stapply-Export-Dev.zip`):
  - Header lines 1–16 describe it as a curated `#`-commented **narrative summary** generated on `2026-09-29`, covering 6 sessions across `2026-09-18` to `2026-09-29` (`SESSION 1` through `SESSION 6`).
  - **Session 2 is incomplete:** Lines 57–58 explicitly state that Session 2's full thread content could not be bulk-exported due to internal format restrictions and was reconstructed from metadata and cross-references.
  - **Post-Sep-29 gap:** No conversation log of any kind exists for `2026-09-30` through `2026-10-08` (covering AWS Fargate deployment, the 7-task Medallion redesign, Lakeflow SDP migration, `stapply-deployment.zip`, and `stapply-deploymentNewacc.zip`).
- **Format & Location Needed If Supplied by User:** If you wish to incorporate verbatim chat context (especially for `2026-09-30`–`2026-10-08`), please export a pre-screened/redacted raw transcript in **`.json`**, **`.md`**, **`.txt`**, or **`.html`** format and place it inside a dedicated folder at:  
  `c:\New folder\Gemini\Databricks Job project\chat_export\` (e.g., `conversation_export.json` or `.md`/`.txt`/`.html`).

---

## 6. Potential Sensitive-Data Locations (Zero Raw Values Displayed)

An automated pattern scan combined with manual inspection across all 87 workspace files, all 10 archives, and all 36 PNGs identified the following sensitive-data locations. **No raw values are reproduced below.**

| Risk Category | File / Archive / Screenshot Location (with Line / Region) | Risk Explanation |
|---|---|---|
| **AWS Account IDs, IAM ARNs/Role IDs, VPC/Subnet/SG/IGW/RTB IDs, ECR URI, ECS & Scheduler ARNs** | `Portfolio\AWS_setup.txt` (lines `9–12, 31, 202, 231–268, 290–347, 365–440, 480–622, 662–690, 717–905`) | Exposes 31+ AWS resource ARNs, 12-digit AWS Account IDs, IAM Role IDs, VPC/Subnet/Route Table/Internet Gateway/Security Group IDs, private ECR URI, ECS task definition ARN, and EventBridge Schedule ARN. Must never be included in `portfolio_site\`. |
| **AWS Account IDs in Screenshots** | `Portfolio\assets\images\projects\ECR.png` (center `URI` column); `IAM.png` (center `Trusted entities` column, row 5) | `ECR.png` has an incomplete black marker redaction over a 12-digit AWS Account ID; `IAM.png` exposes an external 12-digit AWS Account ID in plain text. |
| **Personal & Corporate Email Addresses / Personal Identifiers / GitHub URL** | **Gen 3/4 unmasked corporate email:** `02_handover_guide.py` (lines 4, 6) across `Archive\stapply-deployment\`, `Archive\stapply-deployment.zip`, `stapply-deployment.zip`, `stapply-deploymentNewacc.zip`, and `stapply-deployment.dbc`; `03_before_after_comparison.py` (lines 6, 331, 367) in `Archive\`, `stapply-deployment.zip`, and `stapply-deployment.dbc`.<br>**Personal Gmail:** `config.py` (line 29) & `README.md` (`Archive`/`stapply-deployment.zip` line 37; `stapply-deploymentNewacc.zip` line 39) across `stapply-deployment*` packages; `Archive\stapply-pipeline-enterprise.zip` (`config/00_config.py` L35, `env.template` L14, `infra/databricks/dashboard_backup.json` L4/11, `job_config.json` L13, `docs/master_guide.md` L9/73/136/425); `Archive\stapply_master_guide.md`; `Archive\stapply_portal.html` (L1846, 1968); `Archive\stapply-documentation.zip` (`long_detailed_documentation.md` L886/932, `stapply_portal.html` L1858/1980); `Archive\stapply-book.zip` (`part4.md`, `stapply_book.html`, `stapply_complete_book.md`).<br>**Author full name / masked email local-part / GitHub profile URL:** `Stapply-Export-Dev\` (`README.md`, `manifest.json`, `docs/project_architecture_challenges_learnings.py` L4, `chat_history/complete_conversation_log.py` L4, etc.); `Archive\stapply-deployment.zip` / `stapply-deployment.zip` `README.md` (L77–78) & `stapply-deploymentNewacc.zip::README.md` (L97–98); `Archive\stapply-pipeline-enterprise.zip::README.md` (L6).<br>**Screenshot:** `Job DAG.png` (task cards `snapshot_acquisition`, `dq_gate` show truncated email domain suffixes). | Exposes personal Gmail, corporate email domain, author full name, and personal GitHub profile link. Requires anonymization or explicit user approval for portfolio attribution. |
| **Databricks Workspace URL, Org ID, Job IDs, Run IDs, Pipeline/Dashboard/Warehouse/Git Folder IDs & API Pagination Tokens** | `Stapply-Export-Dev\ops\recent_runs.json` & `.zip` (lines 4–177); `Stapply-Export-Dev\manifest.json` (L9, 15); `infra\jobs\stapply_daily_pipeline.json` (L2); `src\pipelines\00_config` (L38); `04_monitoring_alerting` (L10); `ops\run_summary.md` (L6–10); `docs\production_documentation` (L449, 599, 720–735); `chat_history\complete_conversation_log.py`; `03_before_after_comparison.py` (L321, 357, 387, 590–616); `Archive\stapply-pipeline-enterprise.zip::manifest.json` (L8–10) & `job_config.json`; `Archive\stapply-documentation.zip` (`documentation_assets/timeline.md` L13, 16, 18, 21; `short_documentation.md` L222; `long_detailed_documentation.md` L887, 1004; `stapply_portal.html` L1862, 1954, 2052, 2480, 2483, 2511, 2529); `Archive\stapply_master_guide.md`; `Archive\stapply_portal.html`; `Archive\stapply-book.zip`.<br>**Screenshots:** `Run_log.png` & `SDP pipeline (2).png` (`Run ID` column shows truncated numeric Run IDs). | Exposes live Databricks workspace hostnames, org/job/run/dashboard/pipeline/warehouse/git IDs, and API pagination tokens. Must be stripped or redacted before publication. |
| **S3 Bucket Name & Storage Paths** | `Portfolio\AWS_setup.txt` (L34, 55, 264, 494, 537, 688); `Stapply-Export-Dev\` (`00_config` L21, `pipeline_config.md` L9–10, `production_documentation`, `s3_ingest_bronze_table`, `chat_history`); `Archive\stapply-deployment*\config.py` (L12); `stapply-deploymentNewacc.zip::transformations/bronze/bronze.sql` (L7, 16); `Archive\stapply-pipeline-enterprise.zip`; `Archive\stapply-documentation.zip`; `Archive\stapply-book.zip`.<br>**Screenshots:** `CloudWatch logs.png`, `Fargate source code.png`, `SDP pipeline (1).png`, `SDP Pipeline.png` (S3 URI/bucket visible). Also note disk filename `Bucket + rawstapplysnapshots + snapshot-date folders..png` encodes bucket/folder naming (though the bucket name is cropped inside the image itself). | Exposes concrete S3 storage paths and embeds a personal first name inside the bucket identifier. |
| **Verified False Positives / No Hardcoded Secrets Found** | `Archive\stapply-documentation.zip::long_detailed_documentation.md` (L950), `Archive\stapply_portal.html` (L1995), `Archive\stapply-documentation.zip::stapply_portal.html` (L2007); `Archive\ats-scrapers-main.zip` & `Archive\stapply-main.zip`. | `Bearer` regex hits are generic `Bearer {token}` templates; upstream OSS zips contain only public test fixtures and `env.example` placeholder Postgres URL. **Zero** Databricks PATs (`dapi...`), AWS access keys (`AKIA...`/`ASIA...`/`AROA...`), or PEM private keys exist anywhere in the workspace. |

---

## 7. Conflicts, Missing Evidence, and Open Questions

### 7.1 Conflicts & Discrepancies
1. **Deployment Package Divergence (`stapply-deploymentNewacc.zip` vs. `stapply-deployment.zip`):**
   - `stapply-deploymentNewacc.zip` (`09:17:31Z`) introduces `03_setup_schedules.py` (separate 09:30 pipeline + 10:00 dashboard schedules), `Top ATS Platform Job Market.lvdash.json`, and updated `README.md`, **but** regresses `01_deploy.py` to the 7-step `/Users/{current_user}/stapply_sdp_{hash}` copy model, drops `03_before_after_comparison.py`, and hardcodes the S3 URI in `bronze.sql` lines 7 and 16 (breaking `{{S3_PATH}}` template rendering).
   - `stapply-deployment.zip` (`09:16:11Z`) has the unified 8-step `01_deploy.py`, `WAREHOUSE_ID`, intact `{{S3_PATH}}` placeholder, and `03_before_after_comparison.py` (which matches the 2-task scheduled job visible in `SDP pipeline (2).png`).
2. **Dashboard Page Count Discrepancy (3 Pages vs. 4 Pages):**
   - `Stapply-Export-Dev\README.md` (line 74), `Stapply-Export-Dev\manifest.json` (line 16), and `Archive\stapply-pipeline-enterprise.zip::manifest.json` report **4 pages, 22 datasets**.
   - `stapply-deployment.zip::README.md` (lines 22, 66), `stapply-deploymentNewacc.zip::README.md` (lines 24, 85), `03_before_after_comparison.py` (line 405), `dashboard_config.json` / `.lvdash.json` page headings (lines 663, 1966, 2711: `Current Snapshot`, `Daily Job Movement`, `Job Lifecycle`), and all dashboard screenshots (`Dash (1)..(9).png`, `dASHBOARD SECOND PAGE.png`, `3rd page.png`) confirm **3 pages, 22 datasets**.
3. **Duplicate Screenshot Mislabeling:**
   - `Dash (2).png` is SHA-256 identical to `Bronze table.png` (`58,945` B) and shows the Unity Catalog `bronze`/`silver` sidebar, not a dashboard view.

### 7.2 Missing Evidence & Unverified Items
1. **No Unit or Integration Test Suite:** Zero `pytest`/`unittest` files exist for any authored Databricks notebook, SQL pipeline, or AWS Fargate container (`tests/` inside `Archive\ats-scrapers-main.zip` tests only the external upstream scraper library). Validation relies on runtime notebook assertions, SQL DQ rules (`02_data_quality_validation`), SDP `CONSTRAINT` expectations (`silver.sql` lines 11–14), and post-deploy health queries (`01_deploy.py`).
2. **Unverified `Newacc` Deployment Execution:** No screenshot or run log proves `stapply-deploymentNewacc.zip` (`03_setup_schedules.py` + `01_deploy.py` with `embed_credentials: False`) was executed end-to-end on a secondary Databricks account.
3. **Zero Saved Cell Outputs in `.dbc`:** All 3 notebooks in `stapply-deployment.dbc` have `commands_with_results = 0`, and the `.dbc` omits `config.py`, SQL files, and dashboard JSON.
4. **Missing Raw / Post-Sep-29 Chat Logs:** No raw chat export exists; Session 2 of `complete_conversation_log.py` is incomplete, and `2026-09-30`–`2026-10-08` has no conversation transcript.
5. **No Live Cloud/Databricks Access:** Runtime evidence is strictly static (`ops/recent_runs.json`, `Portfolio/AWS_setup.txt`, and screenshots dated `2026-09-25` to `2026-10-05`).

### 7.3 Open Questions Requiring User Confirmation Before Phase 1
1. **Canonical Package & Narrative Scope:** Between `stapply-deployment.zip` and `stapply-deploymentNewacc.zip`, which is the authoritative current deployment package (or should both be documented as variants)? Should the portfolio present the full 3-generation evolution (Gen 1 4-task Job → Gen 2 AWS Fargate + 7-task Medallion → Gen 3 Lakeflow SDP) or focus primarily on the final Lakeflow SDP + AWS Fargate architecture?
2. **Sensitive-Data & Screenshot Redaction Policy:** Should all S3 bucket names, AWS Account IDs, Databricks IDs, corporate/personal emails, and personal GitHub URLs be anonymized/redacted across `portfolio_site\`? For the 9 flagged screenshots (`CloudWatch logs.png`, `ECR.png`, `Fargate source code.png`, `IAM.png`, `Job DAG.png`, `Run_log.png`, `SDP Pipeline.png`, `SDP pipeline (1).png`, `SDP pipeline (2).png`), should we exclude them, create sanitized cropped/blurred copies inside `portfolio_site\assets\`, or wait for clean replacements from you?
3. **Missing Chat History (`2026-09-30`–`2026-10-08`):** Will you provide a sanitized raw chat export (`.json`, `.md`, `.txt`, or `.html`) at `c:\New folder\Gemini\Databricks Job project\chat_export\`, or should Phase 1+ rely strictly on the verified code, documentation, `AWS_setup.txt`, screenshots, and `complete_conversation_log.py` (`2026-09-18`–`2026-09-29`)?
4. **Portfolio Persona & Attribution:** `Portfolio\index.html` uses `"Your Name"` placeholders. What display name, professional title, and safe public links (e.g., GitHub/LinkedIn, if desired) should appear in `portfolio_site\`?
5. **Duplicate `Dash (2).png`:** Confirm that `Dash (2).png` (duplicate of `Bronze table.png`) should be excluded from the dashboard visual gallery.

---

## 8. Proposed Portfolio Outline & Phase 1–7 Plan (Summary)

Full specifications are detailed in `portfolio_site\portfolio_outline_and_plan.md`. Key design commitments:

- **Target Deliverable Location:** A clean, GitHub-ready static portfolio inside `portfolio_site\` (leaving `Portfolio\` and all original files completely untouched).
- **Narrative Arc (Strictly Evidence-Backed):** Trace the verified engineering progression—from serverless egress limitations in Gen 1 (`01_snapshot_acquisition`) to containerized AWS ECS Fargate ingestion (`AWS_setup.txt`, `Dockerfile`), through the 30-table 7-task Medallion job (`stapply-pipeline-enterprise.zip`), to the declarative Lakeflow SDP + SCD Type 2 + Lakeview 3-page dashboard architecture (`stapply-deployment*.zip`, verified Oct 2–5 runs).
- **Local Self-Contained Diagrams (No External Rendering Services):** All architecture, ingestion, SCD Type 2, Medallion/SDP lineage, and before/after comparison diagrams will be authored as **local inline SVGs** (and/or local HTML+CSS diagrams) inside `portfolio_site\`—with **zero** dependency on Mermaid CDN, Kroki, PlantUML server, or `mermaid.ink`.
- **Professional English Standard:** All portfolio prose, code commentary, and architecture captions will be written in crisp, consistent **professional English** (normalizing any Hinglish comments present in `Portfolio\README.md`, `Portfolio\index.html`, `00_config`, `00_job_creator`, and `00_setup_tables`).
- **Phase 1–7 Execution Gate:** Execution **stops here at Phase 0**. Phase 1 (Scope Lock & Asset Sanitization) begins **only after explicit user approval** of the open questions in Section 7.3.
