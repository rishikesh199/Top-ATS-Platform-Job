# Evidence Register — Stapply Databricks & AWS Pipeline Project

**Purpose:** Strict separation of verified facts (implemented, runtime-observed, or documented/planned), unverified details, open questions blocking Phase 1, and unimplemented recommendations for Phases 1–7.  
**Rule:** Zero raw secrets, emails, personal names, AWS Account IDs, IAM/ECS/VPC IDs, Databricks workspace URLs/IDs, or S3 storage URIs are reproduced in this register.

---

## 1. Verified Facts

### 1.1 `[Implemented]` Facts (Directly Observed in Source Code, SQL, Configs, and Package Structure)

1. **Workspace Baseline & Non-Existence of `portfolio_site\`**  
   - **Evidence:** `baseline_manifest.csv` enumerates `87` original files across `.`, `Archive\`, `Portfolio\`, and `Stapply-Export-Dev\`; `portfolio_site\` was absent prior to Phase 0.
2. **Gen 1 Data Acquisition & UC Volume Staging (`Stapply-Export-Dev`)**  
   - **Evidence:** `Stapply-Export-Dev\Stapply-Export-Dev\src\pipelines\01_snapshot_acquisition` (lines `59–114`) streams the upstream `all.parquet` feed in `10 MB` chunks (`requests.get(..., stream=True, timeout=600)`) into a Unity Catalog Volume (`/Volumes/...`), copies via `dbutils.fs.cp` to dated S3 storage, and enforces `assert row_count > 0`, `assert null_urls == 0`, and `assert duplicate_urls == 0`.
   - **Evidence:** `Stapply-Export-Dev\Stapply-Export-Dev\src\pipelines\00_config` (lines `1–96`), `infra\jobs\00_job_creator` (lines `1–188`), and `sql\ddl\00_setup_tables` (lines `1–223`) were added on `2026-09-30` to centralize configuration for the Gen 1 4-task job (`snapshot_acquisition` → `dq_gate` → `lifecycle_processing` → `monitoring`, `stapply_daily_pipeline.json`).
3. **Gen 1 Data Quality Gate & Lifecycle Processing (`Stapply-Export-Dev`)**  
   - **Evidence:** `Stapply-Export-Dev\Stapply-Export-Dev\manifest.json` (lines `25–39`) and `README.md` (lines `19–21`, `71–73`) implement `21` DQ checks (`9 CRITICAL`, `9 WARNING`, `3 INFO` in `02_data_quality_validation`), incremental enrichment (~3% new URLs), 2-day removal confirmation, 5-day rolling S3 retention, and `7` Delta Gold tables (`sql\ddl\gold_tables.sql`, lines `6–278`).
4. **Gen 2 Containerized AWS ECS Fargate Ingestion**  
   - **Evidence:** `Archive\Dockerfile` (lines `1–13`) builds a `python:3.12-slim` image with `boto3` and `requests` running `app.py`. `Portfolio\AWS_setup.txt` (907 lines total) authors `app.py` + `Dockerfile` (lines `40–198`) and provisions ECR repository `stapply-fargate-ingestion` (lines `4–31`), Docker build/push to ECR (lines `201–262`), IAM execution role (lines `269–359`), ECS cluster `stapply-fargate-cluster` (lines `360–395`), VPC/subnet/route-table discovery and security group creation (lines `396–461`), CloudWatch log group (lines `462–470`), Fargate task definitions v1/v2 (lines `471–622`), EventBridge Scheduler IAM role/policy (lines `695–880`), and EventBridge Scheduler `stapply-daily-fargate-ingestion` (`cron(0 9 * * ? *)`, `Asia/Kolkata`, `ENABLED`, lines `881–906`) streaming multipart chunks to dated S3 snapshot folders.
5. **Gen 2 7-Task Enterprise Medallion Redesign**  
   - **Evidence:** `Archive\stapply-pipeline-enterprise.zip` (`manifest.json` keys `dag`, `tables`, `dashboard`; `pipeline\01..07`; `config\00_config.py`; `setup\00_*.py`) implements a 7-task pipeline (`01_snapshot_acquisition` → `02_bronze_ingestion` → `04_data_quality_validation` → `03_silver_processing` → `05_lifecycle_processing` → `06_gold_analytics` → `07_monitoring_alerting`) across `30` Delta tables (`1` bronze, `9` silver, `7` gold core, `13` gold analytical).
6. **Gen 3/4 Lakeflow Spark Declarative Pipeline (SDP) SQL & Automation**  
   - **Evidence:** `stapply-deployment.zip` and `stapply-deploymentNewacc.zip` implement 3 declarative SQL files:
     - `transformations\bronze\bronze.sql` (52 lines): `CREATE OR REFRESH STREAMING TABLE bronze_raw` via Auto Loader `STREAM(read_files(...))` (lines `10–19`) and `bronze_jobs` via `AUTO CDC INTO bronze_jobs FROM SNAPSHOT (...) STORED AS SCD TYPE 2` (lines `21–52`).
     - `transformations\silver\silver.sql` (164 lines): `CREATE OR REFRESH MATERIALIZED VIEW silver_enriched` with 4 `CONSTRAINT ... EXPECT (...)` quality expectations (`url_not_null` with `ON VIOLATION DROP ROW`, `title_not_empty`, `company_not_empty`, `valid_country_iso`, lines `9–14`).
     - `transformations\gold\gold.sql` (148 lines): 6 materialized views (`gold_country_market_summary` L10, `gold_country_role_summary` L40, `gold_country_role_company_summary` L59, `gold_country_role_location_summary` L85, `gold_job_market_explorer` L108, `gold_daily_movement` L132).
   - **Evidence:** `stapply-deployment.zip::stapply-deployment/01_deploy.py` (466 lines) deploys directly from `DEPLOY_DIR_CLEAN/transformations/...` (lines `105–107`) and configures a unified 2-task scheduled job (`Step 8`, lines `319–466`).
   - **Evidence:** `stapply-deploymentNewacc.zip::stapply-deployment/01_deploy.py` (335 lines) reverts to the `Archive\stapply-deployment.zip` 7-step `/Users/{current_user}/stapply_sdp_{hash_suffix}` copy model (line `107`), adds `# /// script` header (lines `2–5`), `,importlib` (line `29`), and `embed_credentials: False` (line `282`, request block lines `278–283`), offloads scheduling to `03_setup_schedules.py` (162 lines; 09:30 IST pipeline job + 10:00 IST `WorkspaceClient().lakeview` refresh schedule), and hardcodes a concrete S3 path in `bronze.sql` (lines `7, 16`).
7. **Lakeview Dashboard Definition (3 Pages, 22 Datasets)**  
   - **Evidence:** `stapply-deployment.zip::stapply-deployment/dashboard/dashboard_config.json` (3,584 lines) and `stapply-deploymentNewacc.zip::stapply-deployment/Top ATS Platform Job Market.lvdash.json` (identical except literal `—` vs `\u2014` on lines `663`, `1966`, `2711`) define 3 pages (`Current Snapshot`, `Daily Job Movement`, `Job Lifecycle`).
8. **Starter Portfolio Template State (`Portfolio\`)**  
   - **Evidence:** `Portfolio\index.html` (122 lines) is an uncustomized starter template (`"Your Name"`, `project1.png..project3.png`, `docs/resume.pdf`); `Portfolio\README.md` (lines `11–54`) and `Portfolio\index.html` (line `33`) contain Hinglish instructional text/comments.
9. **Upstream External Repositories**  
   - **Evidence:** `Archive\ats-scrapers-main.zip` (259 files) and `Archive\stapply-main.zip` (144 files) are external upstream open-source repositories that publish the `all.parquet` dataset; `tests/` (102 files) inside `ats-scrapers-main.zip` tests only those upstream scrapers.

### 1.2 `[Runtime-Observed]` Facts (Backed by Static Run Logs, CloudShell Output, and Timestamped Screenshots)

1. **AWS ECS Fargate Execution & S3 Snapshot Delivery**  
   - **Evidence:** `Portfolio\AWS_setup.txt` records successful ECR push (lines `201–262`), ECS task execution (`ExitCode: 0`, `EssentialContainerExited`, lines `623–694`), `2.1 GiB` Parquet object written to S3 for `2026-09-30`, and `ENABLED` EventBridge schedule (`09:00` `Asia/Kolkata`, lines `881–906`).
   - **Evidence:** Screenshots `Successful snapshot.png` (`2.2 GB` on `2026-09-25`), `Successful Fargate task.png` (revisions `:2` and `:1` `Active`), `CloudWatch logs.png` (`2026-09-30T06:02:39Z`, `Source Content-Length`: ~2.12 GiB / 2,273,690,124 bytes, multipart parts 1–4), `ECR.png`, `ECS cluster.png`, `ECS task definition.png`, `EventBridge Scheduler.png`, and `Networking&VPC.png` corroborate the AWS deployment.
2. **Gen 1 Job Execution History (Mixed Failures & Successes)**  
   - **Evidence:** `Stapply-Export-Dev\Stapply-Export-Dev\ops\recent_runs.json` records 5 runs across `2026-09-27`–`2026-09-28` (`3 FAILED`, `2 SUCCESS`), corroborated by `Job DAG.png` and `Successful job run-1.png`.
   - **Evidence:** Unity Catalog table creation is visible in `Gold tables.png` (7 tables) and `Lifecycle table.png` (`gold.job_lifecycle` schema + 2 Volumes).
3. **Gen 2 7-Task Medallion Execution (`2026-09-30`)**  
   - **Evidence:** `Bronze table.png` shows `bronze.stapply_jobs` (`1` table) and `silver` (`9` tables). `Run_log.png`, `Updated Run log.png`, and `Task run log.png` show all 7 tasks (`snapshot_acquisition` `20.1s`, `bronze_ingestion` `1m 13s`, `dq_gate` `1m 13s`, `silver_processing` `5m 16s`, `lifecycle_processing` `2m 51s`, `gold_analytics` `3m 25s`, `monitoring` `44.6s`) succeeding on `2026-09-30` after earlier failed/cancelled runs.
4. **Gen 3 Lakeflow SDP Production Runs (`2026-10-02` to `2026-10-05`) & Dashboard Output**  
   - **Evidence:** `SDP pipeline (2).png` shows `Stapply SDP Daily Pipeline + Dashboard` completing 4 consecutive scheduled daily runs (`Oct 02`–`Oct 05, 2026` at `09:30`, `7m 50s`–`8m 09s`, all `Succeeded` across `run_sdp_pipeline` → `refresh_dashboard`).
   - **Evidence:** `SDP pipeline (3).png` shows all 9 SDP objects populated (`bronze_raw` `5.1M` rows / `55s`, `silver_enriched` `6.9M` rows / `2m 0s` with `2 met | 2 unmet` and `414K` warnings, `gold_job_market_explorer` `6.9M` / `27s`, 4 summary MVs `9s` each, `gold_daily_movement` `4s`).
   - **Evidence:** Dashboard screenshots `Dash (1).png`, `Dash (3).png`–`Dash (9).png` (`2026-09-30` baseline) and `dASHBOARD SECOND PAGE.png` + `3rd page.png` (`2026-10-05` multi-day view showing `5M` Active, `2M` Confirmed Removed, `7M` Total Tracked across `Sep 26`–`Oct 05, 2026`) verify rendered dashboard metrics across 3 pages.

### 1.3 `[Documented/Planned]` Facts (Stated in Documentation, Guides, or Narrative Logs)

1. **Databricks Serverless Egress Limitation Motivating AWS Fargate**  
   - **Evidence:** `Archive\stapply-documentation.zip::stapply-documentation/documentation_assets/timeline.md` (line `8`, table row 2) and `Stapply-Export-Dev\docs\project_architecture_challenges_learnings.py` (lines `87–112`) document Databricks Serverless compute constraints (`file:` prefix failure in `dbutils.fs.cp`, egress/DNS constraints, and chunked streaming), explaining the architectural shift to AWS ECS Fargate.
2. **Gen 1–Gen 2 Architectural Narrative (`2026-09-18`–`2026-09-29`)**  
   - **Evidence:** `Stapply-Export-Dev\chat_history\complete_conversation_log.py` (lines `1–684`) documents 6 narrative sessions explaining why DataFrame APIs replaced RDDs on Serverless (Session 1, lines `30–45`), notebook cell-scoping fixes (Session 2, lines `53–77`), and Gen 1 design choices.
3. **SDP Before/After Comparison Metrics**  
   - **Evidence:** `Archive\03_before_after_comparison.py` (651 lines, also in `stapply-deployment.zip` and `stapply-deployment.dbc`) documents the migration comparison from the 7-task Medallion job (30 tables) to Lakeflow SDP (9 objects, 3 SQL files), noting `3 pages, 22 datasets` on line `405`.
4. **Screenshot Redaction Guidelines**  
   - **Evidence:** `Archive\stapply-documentation.zip::stapply-documentation/documentation_assets/screenshot_checklist.md` (71 lines total; masking rules on lines `7, 15, 41–52`) documents intended screenshot masking rules for Account IDs, Role ARNs, Subnet/SG IDs, Workspace URL/ID, Job IDs, emails, and tokens, while lines `54–55` mark the S3 bucket name as "Safe to show" (overridden by Phase 0 Rule R4).

---

## 2. Unverified Details

1. **No Independent Execution Proof for `stapply-deploymentNewacc.zip`:** Neither logs nor screenshots confirm that `stapply-deploymentNewacc.zip` (`01_deploy.py` with `embed_credentials: False` + `03_setup_schedules.py`) was deployed or executed end-to-end on a secondary Databricks account (`stapply-deploymentNewacc.zip` also bypasses `{{S3_PATH}}` template rendering in `bronze.sql` lines `7, 16`).
2. **No Automated Unit or Integration Tests for Authored Pipelines:** Zero `pytest`, `unittest`, or SQL test suites exist in `Stapply-Export-Dev\`, `Archive\stapply-pipeline-enterprise.zip`, `stapply-deployment*.zip`, or AWS Fargate code. Pipeline correctness is inferred only from runtime `assert` statements, SQL DQ rules, SDP `CONSTRAINT` expectations, and observed run logs/screenshots.
3. **Zero Saved Notebook Outputs in `stapply-deployment.dbc`:** All 3 notebooks inside `stapply-deployment.dbc` (`01_deploy.python`, `02_handover_guide.python`, `03_before_after_comparison.python`) have `commands_with_results = 0`, and the archive omits `config.py`, SQL files, and dashboard JSON.
4. **Unlogged Post-Sep-29 Conversation Decisions (`2026-09-30`–`2026-10-08`):** No verbatim chat export or narrative log exists covering the design conversations behind AWS Fargate setup, the 7-task Medallion redesign, Lakeflow SDP migration, or the `Newacc` fork. Session 2 in `complete_conversation_log.py` (lines `57–58`) is also reconstructed from metadata rather than verbatim transcript.
5. **No Live Cloud or Databricks Workspace Verification:** All runtime claims are bounded to static exports (`ops\recent_runs.json`, `Portfolio\AWS_setup.txt`) and screenshots captured between `2026-09-25` and `2026-10-05`. Live S3 contents, current scheduled job status, and external GitHub repository contents were not queried.
6. **Dashboard Page Count Conflict:** `Stapply-Export-Dev\README.md` (line `74`), `manifest.json` (line `16`), and `Archive\stapply-pipeline-enterprise.zip::manifest.json` claim `4` pages, whereas `dashboard_config.json`, `Top ATS Platform Job Market.lvdash.json`, `03_before_after_comparison.py` (line `405`), and all dashboard screenshots show `3` pages (`Current Snapshot`, `Daily Job Movement`, `Job Lifecycle`). Whether a 4th page ever existed before `2026-09-30` is unverified.
7. **Duplicate `Dash (2).png` Intent:** `Dash (2).png` is byte-identical to `Bronze table.png` (`58,945` B, Catalog sidebar); the intended second dashboard screenshot from `2026-09-30` (if one existed) is missing from `Portfolio\assets\images\projects\`.

---

## 3. Questions for the User (Resolved in Phase 0→1 Handoff)

1. **Canonical Archive & Portfolio Scope — RESOLVED:** User selected `stapply-deploymentNewacc.zip` as the primary archive to consider, while requesting full-project coverage (all Markdown docs, screenshots, HLD, and LLD across the project). Execution of `stapply-deploymentNewacc.zip`-specific scripts (`03_setup_schedules.py`, `embed_credentials: False` publish) remains `[Unverified]`.
2. **Sensitive-Data & Screenshot Redaction Policy — RESOLVED:** User directed creating sanitized (cropped/opaque-redacted) copies of the 9 flagged screenshots inside `portfolio_site/assets/` and anonymizing sensitive identifiers across `portfolio_site/`.
3. **Missing Chat Export (`2026-09-30`–`2026-10-08`) — RESOLVED:** User confirmed not to supply or rely on a missing raw chat export; Phases 1–7 proceed strictly from inspected code, docs, `AWS_setup.txt`, screenshots, and `complete_conversation_log.py`.
4. **Persona, Attribution & Public Links — RESOLVED:** Display name **Rishikesh**, project theme **Top ATS Platform Jobs**.
5. **Duplicate `Dash (2).png` — RESOLVED:** User confirmed omitting `Dash (2).png` from the portfolio gallery (keeping original `Portfolio/` untouched and retaining `Bronze table.png` for the catalog view).

### Remaining Optional Phase 1 Questions
1. Confirm whether any safe public GitHub/LinkedIn link should be displayed for **Rishikesh**, or omit profile links.
2. Confirm labeling `stapply-deploymentNewacc.zip` runtime execution as `[Implemented / Unverified Runtime]` alongside `[Runtime-Observed]` Oct 2–5 SDP screenshots.

---

## 4. Unimplemented Recommendations (For Phases 1–7, Pending User Approval)

1. **Fix `stapply-deploymentNewacc.zip` Template & Packaging Regression (Optional Engineering Note):** If `Newacc` is showcased or maintained as a reusable repo template, restore `'{{S3_PATH}}'` in `bronze.sql` (lines `7, 16`) and reconcile `01_deploy.py` direct library paths (`DEPLOY_DIR_CLEAN`) with `03_setup_schedules.py` and `03_before_after_comparison.py`.
2. **Build Local Self-Contained SVG/HTML Diagrams in `portfolio_site\`:** Author custom inline SVG diagrams (end-to-end AWS Fargate + Databricks SDP architecture, SCD Type 2 lifecycle state machine, and Gen 1→Gen 2→Gen 3 evolution comparison) with zero external rendering calls (no Mermaid CDN, Kroki, PlantUML, or `mermaid.ink`).
3. **Normalize All Copy to Professional English:** Replace any Hinglish comments/labels inherited from `Portfolio\README.md`, `Portfolio\index.html`, `00_config`, `00_job_creator`, and `00_setup_tables` with clean technical English throughout `portfolio_site\`.
4. **Sanitize Visual Assets into `portfolio_site\assets\images\`:** Copy only approved screenshots into `portfolio_site\`, exclude duplicate `Dash (2).png`, and apply opaque solid-fill redaction boxes (never semi-transparent markers) over any retained screenshot regions containing S3 URIs, AWS Account IDs, Run IDs, or email fragments.
5. **Add Lightweight Automated Regression & Secret-Scan Checks for `portfolio_site\`:** In Phases 1–7, maintain an automated link/image-path checker and a regex secret-leakage gate covering all HTML, CSS, JS, SVG, and Markdown files before any GitHub-ready sign-off.
6. **Document Testing Boundaries Explicitly in the Portfolio:** Clearly state that pipeline validation is backed by runtime SQL DQ rules, Lakeflow SDP `CONSTRAINT` expectations, and observed execution screenshots rather than a standalone `pytest` unit test suite.
