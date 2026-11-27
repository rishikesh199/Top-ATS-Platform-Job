# Phase 4 — Engineering & Operations

**Project:** Top ATS Platform Jobs — Stapply Job Market Data Engineering Pipeline  
**Status:** Phase 4 Complete — **AWAITING EXPLICIT USER APPROVAL BEFORE PHASE 5**  
**Evidence Standard:** Strictly separates `[Implemented]` / `[Runtime-Observed]` practices from `[Unverified]` items and `[Proposed Recommendation]` improvements. Zero raw secrets, emails, IDs, or concrete S3 URIs are reproduced.

---

## 1. Environments, Lifecycle & Deployment

| Lifecycle Stage | Verified Implementation (`[Implemented]`) | Gaps / `[Proposed Recommendation]` |
|---|---|---|
| **Development** | `stapply-deploymentNewacc.zip::config.py` (line 24) sets `DEVELOPMENT_MODE = True` (`CHANNEL = "CURRENT"`). Gen 1 notebooks live under a user/draft workspace path (`Stapply-Export-Dev/README.md` line 59). | Restore `'{{S3_PATH}}'` in `Newacc`'s `bronze.sql` (lines 7, 16) so `01_deploy.py` Step 2 templating works across accounts without manual SQL edits. |
| **Staging / QA** | No dedicated staging catalog, branch-based CI/CD pipeline, or automated GitHub Actions deployment workflow exists in any archive. | Add a parameterized `env` (`dev`/`prod`) catalog/schema toggle + GitHub Actions validation workflow before deploying to production. |
| **Production** | **AWS:** EventBridge Scheduler `ENABLED` at `09:00 IST` (`AWS_setup.txt` L881–906). **Databricks:** Gen 3 unified 2-task job verified running `09:30 IST` Oct 2–5 (`SDP pipeline (2).png`). `Newacc` defines `03_setup_schedules.py` (`09:30` job + `10:00` Lakeview refresh) `[Implemented / Unverified Runtime]`. | Toggle `DEVELOPMENT_MODE = False` in `config.py` (line 24) for production runs so Databricks SDP automatic retries are enabled. |
| **Deployment Mechanism** | Notebook-driven REST/SDK automation: `01_deploy.py` (creates/updates SDP pipeline, uploads SQL, polls update, publishes Lakeview dashboard with `embed_credentials: False`, runs 7-point Spark SQL check) + `03_setup_schedules.py` (creates job + dashboard refresh schedule). AWS provisioned via CloudShell CLI (`AWS_setup.txt`). | Package AWS resources (ECR, ECS Fargate, IAM, EventBridge, S3) as Terraform/CDK IaC instead of imperative CloudShell commands. |

---

## 2. Testing & Data Quality Validation

### 2.1 Actual Implemented Validation (`[Implemented]` / `[Runtime-Observed]`)
- **Gen 1/2 Python Assertions & SQL DQ Gate:** `01_snapshot_acquisition` enforces `assert row_count > 0`, `assert null_urls == 0`, `assert duplicate_urls == 0`. `02_data_quality_validation` runs `21` SQL checks (`9 CRITICAL`, `9 WARNING`, `3 INFO`), logging to `job_data_quality_results` and failing the job on `CRITICAL` violations (`Stapply-Export-Dev/manifest.json` L25–39).
- **Gen 3 Lakeflow SDP Expectations:** `bronze.sql` (line 11) enforces `CONSTRAINT valid_url EXPECT (url IS NOT NULL) ON VIOLATION DROP ROW`. `silver.sql` (lines 11–14) enforces 4 constraints (`url_not_null` `ON VIOLATION DROP ROW`, `title_not_empty`, `company_not_empty`, `valid_country_iso`). `SDP pipeline (3).png` observes `2 met | 2 unmet` (`414K` warnings) on `silver_enriched` during live Oct 5 execution.
- **Post-Deploy Health Check:** `01_deploy.py` Step 7 (lines 291–335) executes a 7-point Spark SQL verification across deployed Bronze/Silver/Gold objects.

### 2.2 Testing Gaps (`[Unverified]` & `[Proposed Recommendation]`)
- **Zero Automated Unit/Integration Tests:** No `pytest`, `unittest`, or SQL unit test suite exists for authored Databricks notebooks, SQL transformations, or AWS Fargate `app.py` (`Archive/ats-scrapers-main.zip::tests/` tests only the external upstream scraper).
- **Recommended Tests:** Add `pytest` unit tests for `app.py` multipart chunking/date partitioning (mocking `boto3`/`requests`), SQL/PySpark schema & expectation tests on small Parquet fixtures, and an automated `Newacc` smoke-test run on a clean Databricks workspace.

---

## 3. Security, Access Control & Governance

| Control Area | Verified Implementation (`[Implemented]`) | Observed Risks & `[Proposed Recommendation]` |
|---|---|---|
| **Cloud IAM & Cross-Account Access** | Dedicated least-privilege-intent roles: `DatabricksStapplyS3Role`, `stapply-fargate-execution-role`, `stapply-fargate-ingestion-task-role`, `stapply-fargate-scheduler-role` (`IAM.png`; `AWS_setup.txt` L269–359, 695–880). | Ensure S3 bucket policy restricts `DatabricksStapplyS3Role` to read-only on `raw/stapply/snapshots/*` in Gen 3 (since Fargate handles writes). |
| **Databricks Auth & Credentials** | `01_deploy.py` (lines 47–48) reads ephemeral `apiToken()` from Databricks notebook context rather than storing static PATs in code. `Newacc` sets `embed_credentials: False` when publishing Lakeview dashboards (line 282). | Avoid committing `ops/recent_runs.json`, personal/corporate emails (`config.py`, `02_handover_guide.py`), or concrete S3 URIs (`Newacc::bronze.sql`) into public Git repositories. |
| **Data Governance** | Unity Catalog (`workspace` catalog) governs Bronze/Silver/Gold tables, Volumes (`tmp_upload`, `code_infra`, `exports`), and external S3 locations (`Lifecycle table.png`; `Gold tables.png`). | Enable row/column-level masking or explicit schema separation (`bronze`/`silver`/`gold` instead of `default`) for multi-team production governance. |
| **Screenshot & Repo Hygiene** | `screenshot_checklist.md` defines masking rules for Account IDs, ARNs, URLs, and emails. | Replace semi-transparent marker redactions (seen in `ECR.png`) with solid opaque redactions inside `portfolio_site/assets/images/` (already approved for Phase 5/6). |

---

## 4. Monitoring, Reliability & Cost Considerations

### 4.1 Monitoring & Alerting (`[Implemented]` / `[Runtime-Observed]`)
- **AWS:** Fargate task streams container logs (`awslogs`) to CloudWatch `/ecs/stapply-fargate-ingestion` (`AWS_setup.txt` L501–508; `CloudWatch logs.png`).
- **Databricks:** Gen 1/2 `04_monitoring_alerting` / `07_monitoring_alerting` checks 7–9 health dimensions via Databricks Jobs API + Delta queries; Gen 3 configures `ALERT_EMAILS` in `config.py` (line 29) and `03_setup_schedules.py` job failure notifications.

### 4.2 Reliability (`[Implemented]` / `[Runtime-Observed]`)
- **Timeouts & Retries:** `app.py` uses `timeout=(60, 1800)` and multipart S3 uploads (`64 MiB` parts) to survive slow upstream transfers (`AWS_setup.txt` L61–84). Databricks Jobs configure `max_retries: 2` with `300,000 ms` (5-min) retry intervals (`stapply_daily_pipeline.json` / `03_setup_schedules.py`).
- **Historical Data Protection:** `bronze_jobs` uses `AUTO CDC ... STORED AS SCD TYPE 2` (`bronze.sql` L48), preserving removed listings with `__END_AT` rather than overwriting history.

### 4.3 Cost Optimization (`[Implemented]` / `[Runtime-Observed]`)
- **No NAT Gateway:** Fargate runs in default VPC with public IP + Internet Gateway (`0` NAT Gateways in `Networking&VPC.png`), avoiding hourly NAT Gateway + per-GB processing charges.
- **Ephemeral Compute:** Fargate runs as a one-shot scheduled task (`ExitCode: 0`, `0` idle tasks in `ECS cluster.png`), and Databricks uses Serverless + Photon (`config.py` L22–23), cutting Gen 3 pipeline duration to `~8 min` (`SDP pipeline (2).png`) vs. `~14–15 min` in Gen 2 (`Task run log.png`).
- **Incremental Enrichment:** Gen 1/2 enriched only ~3% new URLs per day (`Stapply-Export-Dev/README.md` L72); Gen 3 replaces 30 tables with 9 declarative SDP objects (`03_before_after_comparison.py`).

---

## 5. Documented Issues & Fixes (`[Implemented]` / `[Runtime-Observed]`)

1. **Serverless `file:` Prefix & Egress Failure (`Stapply-Export-Dev/docs/project_architecture_challenges_learnings.py` L87–95; `short_documentation.md` L55):** Early Gen 1 runs failed downloading `all.parquet` directly on Databricks Serverless; resolved initially via UC Volume staging (`/Volumes/.../tmp_upload`) and permanently by offloading ingestion to AWS ECS Fargate.
2. **2–3 GB Memory Pressure (`project_architecture_challenges_learnings.py` L93–95; `AWS_setup.txt` L61–130):** Solved by 10 MB chunked streaming (Gen 1) and 8 MiB read / 64 MiB S3 multipart streaming in Fargate `app.py`.
3. **Lakeview Publish HTTP 400 (`stapply-deploymentNewacc.zip::01_deploy.py` L278–282):** Inline comment documents that `embed_credentials: False` avoids HTTP 400 errors when `warehouse_id` is omitted.
4. **Gen 1 Failures → Gen 2/3 Stabilization:** `ops/recent_runs.json` records 3 failed runs on Sep 27 (`Workload fail`) followed by 2 successes on Sep 27–28; `Run_log.png` shows Gen 2 failures before Sep 30 green runs; `SDP pipeline (2).png` shows 4 consecutive green runs Oct 2–5.

---

## 6. Limitations, Risks & Future Improvements

- **Known Limitations:**
  1. No automated unit/integration test suite (`pytest`) for pipeline code or Fargate `app.py`.
  2. `stapply-deploymentNewacc.zip` execution is `[Unverified]`, has `DEVELOPMENT_MODE = True`, hardcodes S3 URI in `bronze.sql` (L7, L16), and `02_handover_guide.py` (L6) points to an external user path.
  3. Imperative AWS CLI setup (`AWS_setup.txt`) without Terraform/IaC.
  4. `414K` Silver expectation warnings observed in `SDP pipeline (3).png` (rows kept with warnings rather than quarantined).
- **Recommended Improvements (`[Proposed Recommendation]`):**
  1. Fix `bronze.sql` `{{S3_PATH}}` templating and `02_handover_guide.py` path in `Newacc`.
  2. Set `DEVELOPMENT_MODE = False` for production deployments.
  3. Add a quarantine table/view for `silver_enriched` rows failing non-drop expectations (`title_not_empty`, `company_not_empty`, `valid_country_iso`).
  4. Add Terraform for AWS resources + GitHub Actions CI (`sqlfluff`, `ruff`, `pytest`).

**Please reply with `"Approve Phase 5"` to proceed to Phase 5 — Portfolio design plan (navigation, sections, diagram list, screenshot mapping, and visual design).**
