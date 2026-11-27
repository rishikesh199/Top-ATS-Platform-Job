# Phase 1 — Evidence-Backed Project Understanding

**Project Title:** Top ATS Platform Jobs — Stapply Job Market Data Engineering Pipeline  
**Portfolio Attribution:** Rishikesh  
**Status:** Phase 1 Complete — **AWAITING EXPLICIT USER APPROVAL BEFORE PHASE 2**  
**Primary Archive Selected by User:** `stapply-deploymentNewacc.zip` (`2026-10-08T09:17:31Z`), contextualized within the full 3-generation evolution (Gen 1 → Gen 2 AWS Fargate + Medallion → Gen 3 Lakeflow SDP)  
**Sensitivity Rule:** Zero raw secrets, emails, AWS Account IDs, IAM/VPC/ECS IDs, Databricks workspace URLs/IDs, or S3 bucket/path URIs are reproduced in this document.

---

## 1. Locked Phase 0 Decisions

Per user confirmation following Phase 0:
1. **Canonical Archive & Scope:** `stapply-deploymentNewacc.zip` is treated as the primary target deployment package, while the portfolio documents the full end-to-end project across all three architectural generations (including HLD, LLD, documentation, and verified screenshots). Unverified differences in `stapply-deploymentNewacc.zip` (such as `03_setup_schedules.py` execution and the hardcoded S3 URI in `bronze.sql`) remain explicitly labeled `[Unverified]`.
2. **Sensitive-Data & Screenshot Sanitization:** All sensitive identifiers (S3 bucket names, AWS Account IDs, Databricks workspace URLs/IDs, emails, and personal GitHub links) will be anonymized across `portfolio_site/`. Sanitized (cropped/opaque-redacted) copies of the 9 flagged screenshots will be created inside `portfolio_site/assets/images/` during the asset build, leaving `Portfolio/` untouched.
3. **Chat Export:** No raw chat export will be supplied for `2026-09-30`–`2026-10-08`; all claims rely strictly on inspected code, documentation, `Portfolio/AWS_setup.txt`, screenshots, and `complete_conversation_log.py` (`2026-09-18`–`2026-09-29`).
4. **Persona & Attribution:** Display name **Rishikesh**, project title **Top ATS Platform Jobs** (Stapply Job Market Data Engineering Pipeline).
5. **Duplicate `Dash (2).png`:** Excluded from the portfolio gallery (`Bronze table.png` retained for the Unity Catalog view).

---

## 2. Business Problem & Context

- **Core Problem:** Public Applicant Tracking System (ATS) aggregators publish daily point-in-time job-posting snapshots (`all.parquet`, ~5.1 million active listings, ~2.1–2.2 GB per daily file), which answer only what is live *today* (`Archive/stapply-documentation.zip::short_documentation.md` lines 10–18, 22–28; `Portfolio/AWS_setup.txt` / `CloudWatch logs.png`). Without historical state tracking, analysts cannot determine when a job first appeared, when it disappeared from active feeds, whether it reappeared, or how hiring velocity changes day over day (`short_documentation.md` lines 16–18).
- **Engineering Challenge:**
  1. **Compute & Egress Constraints:** Early Gen 1 runs attempted to stream the ~2–3 GB Parquet feed directly from Databricks Serverless compute into a Unity Catalog Volume and S3 (`Stapply-Export-Dev/src/pipelines/01_snapshot_acquisition`), encountering `file:` prefix restrictions in `dbutils.fs.cp()`, memory pressure, API timeouts, and Serverless external egress/DNS limitations (`Stapply-Export-Dev/docs/project_architecture_challenges_learnings.py` lines 87–105; `short_documentation.md` lines 55).
  2. **Scale & Cost:** Enriching all ~5.1M rows daily with regex/role classification and company normalization is expensive when ~97% of listings carry over from the prior day (`Stapply-Export-Dev/README.md` line 72).
  3. **Operational Simplicity:** The 7-task Medallion job (30 Delta tables) in Gen 2 required ~14–15 minutes and complex imperative orchestration (`Archive/stapply_master_guide.md` lines 34–54; `Run_log.png`), motivating consolidation into declarative Databricks Lakeflow Spark Declarative Pipelines (SDP) (`Archive/03_before_after_comparison.py`).

---

## 3. Project Scope & 3-Generation Evolution

| Generation | Package / Source Evidence | Orchestration & Compute | Storage & Data Model | Key Scope & Evolution |
|---|---|---|---|---|
| **Gen 1** (`2026-09-18`–`2026-09-30`) | `Stapply-Export-Dev.zip`, `Stapply-Export-Dev/` | 4-task Databricks Job (`snapshot_acquisition` → `dq_gate` → `lifecycle_processing` → `monitoring`) on Serverless | S3 (5-day rolling) + 7 Delta Gold tables (`sql/ddl/gold_tables.sql`) | Proved ~3% incremental enrichment, 21 SQL DQ checks, 2-day removal confirmation, and centralized `00_config` / `00_job_creator` / `00_setup_tables` parameterization. |
| **Gen 2** (`2026-09-30`) | `Portfolio/AWS_setup.txt`, `Archive/Dockerfile`, `Archive/stapply-pipeline-enterprise.zip` | **AWS ECS Fargate** (EventBridge 09:00 IST) + **7-task Databricks Medallion Job** (09:30 IST) | S3 + 30 Delta tables (`1` Bronze, `9` Silver, `7` Gold Core, `13` Gold Analytical) | Offloaded ingestion from Databricks Serverless to containerized Fargate streaming multipart uploads; introduced full Bronze→Silver→Gold separation. |
| **Gen 3** (`2026-10-01`–`2026-10-08`) | `stapply-deployment.zip`, `stapply-deploymentNewacc.zip` *(user-selected primary)* | **AWS ECS Fargate** + **Databricks Lakeflow SDP** (`AUTO CDC` SCD Type 2 + MVs) + automated deployment (`01_deploy.py`) & scheduling (`03_setup_schedules.py` in `Newacc`) | S3 + 9 declarative SDP objects (`bronze_raw`, `bronze_jobs` SCD2, `silver_enriched` MV, 6 Gold MVs) | Replaced 7 imperative notebooks / 30 tables with 3 SQL files / 9 declarative objects; cut pipeline runtime to ~8 min; powers a 3-page, 22-dataset Lakeview dashboard. |

---

## 4. Target Users & Consumers

Based on `Archive/stapply-documentation.zip::short_documentation.md` (lines 9–16), `Stapply-Export-Dev/docs/project_architecture_challenges_learnings.py` (lines 72–76), and `stapply-deploymentNewacc.zip::README.md` (lines 62–73):
1. **Job-Market Researchers & Workforce Analysts:** Query country, role-family, company, salary, remote-work, and posting-freshness trends via the 3-page Lakeview dashboard (`Current Snapshot`, `Daily Job Movement`, `Job Lifecycle`).
2. **Recruiters & Talent Intelligence Teams:** Track hiring velocity, net active job changes, confirmed removals, and ATS platform distribution (`eures`, `workday`, `bundesagentur`, Greenhouse, Lever, etc. — observed in `Dash (8).png`, `short_documentation.md` line 22).
3. **Downstream SQL Consumers:** Query curated Unity Catalog Gold tables/materialized views (`gold_job_market_explorer`, `gold_daily_movement`, summary MVs).
4. **Data Engineering & Platform Operators:** Deploy, monitor, and maintain the AWS Fargate ingestion task, Databricks SDP pipeline, DQ expectations, and scheduled Lakeview refreshes (`01_deploy.py`, `02_handover_guide.py`, `03_setup_schedules.py`).

---

## 5. End-to-End Workflow Summary

1. **09:00 IST — Serverless Cloud Ingestion (AWS):** EventBridge Scheduler (`stapply-daily-fargate-ingestion`, `cron(0 9 * * ? *)`, `Asia/Kolkata`) triggers an ECS Fargate task (`1 vCPU`, `2 GB`, `python:3.12-slim`) that streams `all.parquet` (~2.1–2.2 GiB) in 64 MiB multipart chunks into date-partitioned S3 storage (`Portfolio/AWS_setup.txt` lines 40–198, 881–906; `CloudWatch logs.png`; `EventBridge Scheduler.png`).
2. **09:30 IST — Declarative Lakehouse Processing (Databricks SDP):**
   - `bronze_raw` (Streaming Table) ingests new Parquet files from S3 via Auto Loader `STREAM(read_files(...))` (`transformations/bronze/bronze.sql` lines 10–19).
   - `bronze_jobs` tracks historical state per `url` via `AUTO CDC INTO ... FROM SNAPSHOT (...) STORED AS SCD TYPE 2` (`bronze.sql` lines 21–52).
   - `silver_enriched` (Materialized View) cleans fields, applies the 36-branch V2 role taxonomy and 14 derived columns, and enforces 4 `CONSTRAINT ... EXPECT (...)` data-quality rules (`transformations/silver/silver.sql` lines 9–164).
   - `gold.sql` materializes 6 Gold views (`gold_country_market_summary`, `gold_country_role_summary`, `gold_country_role_company_summary`, `gold_country_role_location_summary`, `gold_job_market_explorer`, `gold_daily_movement`) (`transformations/gold/gold.sql` lines 10–148).
3. **10:00 IST — Analytics Refresh (`stapply-deploymentNewacc.zip`):** A Lakeview refresh schedule updates the 3-page, 22-dataset `Top ATS Platform Job Market` dashboard (`03_setup_schedules.py`; `Top ATS Platform Job Market.lvdash.json`). *(Note: In `stapply-deployment.zip`, dashboard refresh runs as Task 2 immediately after `run_sdp_pipeline` in a unified 2-task job, as observed in `SDP pipeline (2).png`.)*

---

## 6. Verified Outcomes vs. Unverified / Planned Items

### 6.1 `[Runtime-Observed]` Verified Outcomes
- **AWS Fargate Ingestion:** `Portfolio/AWS_setup.txt` (lines 623–694) and `CloudWatch logs.png` (`2026-09-30`) confirm `ExitCode: 0` and streaming upload of ~2.12 GiB (`2,273,690,124` bytes) to S3; `Successful snapshot.png` confirms `2.2 GB` `all.parquet` for `2026-09-25`.
- **Gen 2 7-Task Medallion Execution (`2026-09-30`):** `Task run log.png`, `Updated Run log.png`, and `Run_log.png` confirm all 7 tasks succeeded (`~14–15m` total across successful runs) after earlier failed/cancelled runs.
- **Gen 3 Lakeflow SDP Production Runs (`2026-10-02`–`2026-10-05`):** `SDP pipeline (2).png` shows 4 consecutive scheduled daily runs at `09:30` completing in `7m 50s`–`8m 09s` (`Succeeded`). `SDP pipeline (3).png` confirms `bronze_raw` (`5.1M` rows, `55s`), `silver_enriched` (`6.9M` rows, `2m 0s`, `2 met | 2 unmet` with `414K` warnings), `gold_job_market_explorer` (`6.9M`, `27s`), 4 summary MVs (`9s` each), and `gold_daily_movement` (`4s`, `17` rows).
- **Dashboard Analytics (`2026-09-30` & `2026-10-05`):** `Dash (1).png`, `Dash (3)..(9).png`, `dASHBOARD SECOND PAGE.png`, and `3rd page.png` verify live metrics: `5.1M` active jobs, `479.6K` companies, `87` countries, `436.4K` fresh jobs, `142.1K` remote jobs, `236.7K` with salary (Sep 30), and `5M` Active / `2M` Confirmed Removed / `7M` Total Tracked across `Sep 26`–`Oct 05, 2026`.

### 6.2 `[Unverified]` Items (Explicitly Flagged)
- **End-to-End Execution of `stapply-deploymentNewacc.zip`:** No runtime log or screenshot verifies execution of `stapply-deploymentNewacc.zip`'s `03_setup_schedules.py` (separate 09:30/10:00 schedules) or `01_deploy.py` (`embed_credentials: False`) on a secondary Databricks account.
- **Automated Unit/Integration Tests:** Zero `pytest`/`unittest` suites exist for the authored Databricks or Fargate code; validation relies on runtime assertions, SQL DQ checks, and SDP expectations.

---

## 7. Phase 1 Open Questions (If Any Need Clarification)

No blocking gaps prevent Phase 2 (Databricks & Cloud Architecture), **except** two optional confirmations:
1. **Optional Public Links:** Should the portfolio footer/header show **Rishikesh** with no external profile links, or do you want a sanitized/placeholder GitHub/LinkedIn link slot?
2. **New-Account (`stapply-deploymentNewacc.zip`) Verification Status:** Confirm that `stapply-deploymentNewacc.zip` should be labeled `[Implemented / Unverified Runtime]` in the portfolio (since runtime screenshots `SDP pipeline (2).png`–`(3).png` correspond to the 2-task job model), while `03_setup_schedules.py` and `bronze.sql` differences are documented transparently.

**Please confirm approval to proceed to Phase 2 — Databricks and cloud architecture.**
