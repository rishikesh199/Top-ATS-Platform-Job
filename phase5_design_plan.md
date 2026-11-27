# Phase 5 — Portfolio Design Plan

**Project:** Top ATS Platform Jobs — Stapply Job Market Data Engineering Pipeline  
**Author Attribution:** Rishikesh  
**Status:** Phase 5 Complete — **AWAITING EXPLICIT USER APPROVAL BEFORE PHASE 6 (BUILD)**  
**Output Directory:** `portfolio_site/` (original `Portfolio/` and all source files remain untouched)

---

## 1. Deliverable File Structure (`portfolio_site/`)

```text
portfolio_site/
├── index.html                        # Responsive, accessible single-page engineering portfolio
├── README.md                         # Local viewing instructions & project overview
├── github_safety_checklist.md        # Pre-publication safety checklist & private-content exclusions
├── assets/
│   ├── css/
│   │   └── styles.css                # Self-contained design system (system fonts, zero external CDNs)
│   ├── js/
│   │   └── app.js                    # Diagram switcher, code tabs, gallery filter, accessible lightbox
│   └── images/                       # 35 approved screenshots (26 clean copies + 9 opaque-redacted copies)
└── [Phase 0–4 Markdown Docs]         # phase0..phase4_*.md, evidence_register.md, portfolio_outline_and_plan.md
```

---

## 2. Navigation & Page Sections (`index.html`)

- **Sticky Header Navigation:**
  1. `Overview` (`#overview`)
  2. `Architecture` (`#architecture`)
  3. `Code & SQL` (`#code`)
  4. `DQ & Ops` (`#operations`)
  5. `Screenshots` (`#gallery`)
  6. `Evidence & Safety` (`#evidence`)
- **Section Breakdown:**
  1. **Hero & Executive Summary (`#overview`):** Project title (*Top ATS Platform Jobs*), attribution (*Rishikesh*), problem statement, and verified KPI cards (`~5.1M` daily rows, `~2.12 GiB` Parquet, `9` SDP objects from `3` SQL files, `~8 min` Gen 3 runtime, `3` dashboard pages / `22` datasets).
  2. **Business Context & 3-Generation Evolution (`#evolution`):** Side-by-side timeline of **Gen 1** (4-task Job, 7 Gold tables) → **Gen 2** (AWS ECS Fargate + 7-task Medallion, 30 Delta tables, `~14–15m`) → **Gen 3** (Lakeflow SDP, 9 objects, `~8m`), explicitly distinguishing `[Runtime-Observed]` Oct 2–5 runs from `[Implemented / Unverified Runtime]` items in `stapply-deploymentNewacc.zip`.
  3. **HLD, LLD & Self-Contained Diagrams (`#architecture`):** Interactive diagram switcher rendering 4 local inline SVG / HTML+CSS diagrams (zero external CDN or diagram services) with source file citations and explicit `[Unverified]` labels.
  4. **File-by-File Code & Dependency Explorer (`#code`):** Tabbed breakdown (*Gen 3 SDP (`Newacc`)*, *AWS Fargate (`app.py` / `Dockerfile`)*, *Gen 2 & Gen 1 Reference*) summarizing purpose, inputs/outputs, dependencies, and execution flow with line/file citations.
  5. **Engineering, Data Quality, Security & Operations (`#operations`):** 4 SDP `CONSTRAINT` expectations vs. 21 SQL DQ checks, honest testing boundary (no `pytest` suite), IAM/VPC (`0` NAT Gateways)/cost optimization, documented issues & fixes, and limitations/recommendations.
  6. **Sanitized Screenshot Gallery (`#gallery`):** Category filter tabs (*All (35)*, *AWS Ingestion (9)*, *Medallion & SDP (13)*, *Lakeview Dashboard (13)*) displaying original filenames, verified captions, and an accessible click-to-zoom lightbox modal.
  7. **Evidence Register & GitHub-Readiness (`#evidence`):** Summary table of `[Runtime-Observed]`, `[Implemented]`, `[Unverified]`, and `[Proposed]` boundaries, plus links to local Markdown documentation and the GitHub safety checklist.

---

## 3. Local Diagram List (Zero External Rendering Services)

1. **Diagram 1 (Inline SVG) — End-to-End Cloud & Lakehouse HLD:**
   - Stapply API (`all.parquet`) → EventBridge (`09:00 IST`) → ECS Fargate (`1 vCPU / 2 GB`, `64 MiB` multipart) → Partitioned AWS S3 → Unity Catalog External Location → Lakeflow SDP (`Serverless + Photon`) → 3-Page Lakeview Dashboard.
   - *Citations:* `AWS_setup.txt`, `Dockerfile`, `config.py`, `bronze.sql`, `silver.sql`, `gold.sql`, `CloudWatch logs.png`, `SDP pipeline (2).png`.
2. **Diagram 2 (Inline SVG) — Lakeflow SDP Medallion & SCD Type 2 Data Flow:**
   - `bronze_raw` (Auto Loader + `valid_url` drop) → `bronze_jobs` (`AUTO CDC FROM SNAPSHOT`, `KEYS (url)`, `STORED AS SCD TYPE 2`, `__START_AT`/`__END_AT`) → `silver_enriched` MV (4 `CONSTRAINT` expectations, 14 derived columns) → 6 Gold MVs → 3 Dashboard tabs.
   - *Citations:* `bronze.sql`, `silver.sql`, `gold.sql`, `SDP Pipeline.png`, `SDP pipeline (1).png`, `SDP pipeline (3).png`.
3. **Diagram 3 (Inline SVG) — Job Orchestration & Scheduling Comparison:**
   - Compares the `[Runtime-Observed]` unified 2-task job (`run_sdp_pipeline` → `refresh_dashboard` in `stapply-deployment.zip` / `SDP pipeline (2).png`) with the `[Implemented / Unverified Runtime]` separate schedule flow (`09:30 IST` job + `10:00 IST` Lakeview refresh in `stapply-deploymentNewacc.zip::03_setup_schedules.py`).
4. **Diagram 4 (Local HTML+CSS) — 3-Generation Complexity & Runtime Matrix:**
   - Visualizes Gen 1 (4 tasks / 7 tables) vs. Gen 2 (7 tasks / 30 tables, `~14–15m`) vs. Gen 3 (3 SQL files / 9 SDP objects, `~8m`).

---

## 4. Screenshot Mapping & Redaction Plan (35 Retained, 1 Omitted)

- **Excluded Duplicate (1):** `Dash (2).png` (byte-identical to `Bronze table.png`).
- **Clean Copies (26 files copied as-is to `portfolio_site/assets/images/`):**
  - *AWS Ingestion (5):* `Bucket + rawstapplysnapshots + snapshot-date folders..png`, `ECS cluster.png`, `ECS task definition.png`, `EventBridge Scheduler.png`, `Networking&VPC.png`, `Successful Fargate task.png`, `Successful snapshot.png` *(7 clean AWS screenshots — wait: let's count exact categories below)*.
  - Let's verify exact counts:
    - **AWS Ingestion (11 total: 7 clean + 4 redacted):** Clean: `Bucket + rawstapplysnapshots + snapshot-date folders..png`, `ECS cluster.png`, `ECS task definition.png`, `EventBridge Scheduler.png`, `Networking&VPC.png`, `Successful Fargate task.png`, `Successful snapshot.png`. Redacted: `CloudWatch logs.png`, `ECR.png`, `Fargate source code.png`, `IAM.png`.
    - **Medallion & SDP (11 total: 6 clean + 5 redacted):** Clean: `00_config.png`, `Bronze table.png`, `Gold tables.png`, `Lifecycle table.png`, `SDP pipeline (3).png`, `Successful job run-1.png`, `Task run log.png`, `Updated Run log.png`, `Workspace project tree.png` *(9 clean)* + Redacted: `Job DAG.png`, `Run_log.png`, `SDP Pipeline.png`, `SDP pipeline (1).png`, `SDP pipeline (2).png` *(5 redacted)* = 14 Medallion/SDP screenshots.
    - **Lakeview Dashboard (10 total: all 10 clean):** `Dash (1).png`, `Dash (3).png`, `Dash (4).png`, `Dash (5).png`, `Dash (6).png`, `Dash (7).png`, `Dash (8).png`, `Dash (9).png`, `dASHBOARD SECOND PAGE.png`, `3rd page.png`.
    - *(Check sum: 11 + 14 + 10 = **35** screenshots! Exact match.)*
- **Opaque Solid-Fill Redaction Plan for the 9 Flagged Screenshots (`portfolio_site/assets/images/` only):**
  - `CloudWatch logs.png`: Solid opaque mask over S3 URI/bucket prefix in `Message` row 2.
  - `ECR.png`: Solid opaque mask over the center `URI` column (replacing semi-transparent marker over the 12-digit AWS Account ID).
  - `Fargate source code.png`: Solid opaque mask over the `BUCKET` default line at the bottom.
  - `IAM.png`: Solid opaque mask over the external 12-digit AWS Account ID in `Trusted entities` row 5.
  - `Job DAG.png`: Solid opaque mask over truncated email domain suffixes in `snapshot_acquisition` and `dq_gate` task cards.
  - `Run_log.png`: Solid opaque mask over numeric `Run ID` column values.
  - `SDP Pipeline.png` & `SDP pipeline (1).png`: Solid opaque mask over the S3 bucket URI/prefix in the leftmost source node.
  - `SDP pipeline (2).png`: Solid opaque mask over numeric `Run ID` column values.

---

## 5. Visual Design & Accessibility

- **Palette & Typography:** Dark engineering theme (`#0b1120` background, `#111827` cards, `#1e293b` borders, `#f8fafc` primary text, `#94a3b8` muted text, `#ff5a1f` Databricks accent, `#38bdf8` AWS/cloud accent, semantic badges for `[Runtime-Observed]`, `[Implemented]`, `[Unverified]`). Uses system UI + monospace font stacks—zero external font/CDN requests.
- **Accessibility & Responsiveness:** Semantic HTML5 (`<header>`, `<nav>`, `<main>`, `<section>`, `<footer>`), skip-to-content link, `aria-label` on SVG diagrams and modal controls, `Escape`-key lightbox close, WCAG AA contrast, responsive CSS Grid/Flexbox down to 360px mobile viewports.

**Please reply with `"Approve Phase 6"` to proceed to Phase 6 — Build the portfolio (sanitize screenshots and create the complete `portfolio_site/` deliverable).**
