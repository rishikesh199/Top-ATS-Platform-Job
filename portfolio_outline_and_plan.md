# Proposed Portfolio Outline & Phase 1–7 Execution Plan

**Target Output Directory:** `c:\New folder\Gemini\Databricks Job project\portfolio_site\`  
**Original Workspace Preservation:** `Portfolio\`, `Archive\`, `Stapply-Export-Dev\`, and all root `.zip`/`.dbc` files remain strictly read-only and unmodified.  
**Current Gate:** **PHASE 0 COMPLETE — STOPPED FOR EXPLICIT USER APPROVAL BEFORE PHASE 1.**

---

## 1. Proposed GitHub-Ready Portfolio Outline (`portfolio_site\`)

### 1.1 Target Directory Structure (Planned for Phases 1–7)

```text
portfolio_site/
├── README.md                          # GitHub repository overview (professional English, verified metrics)
├── index.html                         # Self-contained engineering showcase page (replaces generic Portfolio/ skeleton)
├── phase0_discovery_report.md         # [Created in Phase 0]
├── evidence_register.md               # [Created in Phase 0]
├── portfolio_outline_and_plan.md      # [Created in Phase 0]
├── assets/
│   ├── css/
│   │   └── styles.css                 # Clean, responsive dark/light technical design system
│   ├── js/
│   │   └── app.js                     # Lightweight local interactivity (diagram tabs, gallery modal, architecture toggle)
│   └── images/                        # Sanitized, approved screenshots copied/redacted from Portfolio/ (no raw secrets, no Dash (2).png duplicate)
└── docs/
    ├── architecture_evolution.md      # Verified Gen 1 -> Gen 2 -> Gen 3 technical case study
    └── data_quality_and_scd2.md       # DQ expectations, SCD Type 2 lifecycle, and validation boundary notes
```

### 1.2 Proposed Narrative Arc & Page Information Architecture (`index.html`)

1. **Hero & Executive Summary**
   - Concise framing of the **Stapply Job Market Data Engineering Pipeline**: daily ingestion of ~5.1M job-posting records (~2.1–2.2 GB Parquet) from an external feed into S3, processed on Databricks Serverless into a Lakeflow Spark Declarative Pipeline (SDP) and 3-page Lakeview analytics dashboard.
   - Attribution & contact section populated strictly per user confirmation in Phase 0 Question 4 (no personal Gmail, corporate email, or unapproved identifiers).
2. **Engineering Problem & Architectural Evolution (Verified 3-Generation Timeline)**
   - **Gen 1 (`2026-09-18`–`2026-09-29`, `Stapply-Export-Dev\`):** 4-task Databricks job (`snapshot_acquisition` → `dq_gate` → `lifecycle_processing` → `monitoring`), 21 SQL DQ checks, two-pass Delta `MERGE`, 7 Gold tables. Documents why Databricks Serverless compute restrictions (`file:` prefix errors, egress/timeout constraints) necessitated externalized ingestion.
   - **Gen 2 (`2026-09-30`, `AWS_setup.txt` + `stapply-pipeline-enterprise.zip`):** Containerized **AWS ECS Fargate** (`python:3.12-slim`, 64 MiB multipart S3 upload, EventBridge 09:00 IST schedule) paired with a 7-task Medallion Databricks job (30 Delta tables: 1 Bronze, 9 Silver, 7 Gold Core, 13 Gold Analytical), verified green on `2026-09-30` (~14–15 min runtime).
   - **Gen 3 (`2026-10-01`–`2026-10-08`, `stapply-deployment*.zip`):** Consolidation to **Lakeflow SDP** (3 declarative SQL files producing 9 objects: `bronze_raw`, `bronze_jobs` SCD Type 2 via `AUTO CDC FROM SNAPSHOT`, `silver_enriched` MV with 4 `CONSTRAINT` expectations, and 6 Gold MVs), automated deployment (`01_deploy.py`), and 3-page / 22-dataset Lakeview dashboard, verified across 4 consecutive scheduled runs (`Oct 2–5, 2026`, ~8 min runtime).
3. **Local Self-Contained Diagrams (Zero External Rendering Services)**
   - All diagrams will be rendered natively using **inline SVG** and **local HTML+CSS** bundled inside `portfolio_site\`—never calling Mermaid CDN, Kroki, PlantUML servers, or `mermaid.ink`:
     - **Diagram 1 (Inline SVG):** *End-to-End AWS Fargate + Databricks Lakeflow SDP Architecture* (External Parquet Feed → ECS Fargate + EventBridge → Partitioned S3 → Auto Loader `bronze_raw` → `AUTO CDC` SCD2 `bronze_jobs` → `silver_enriched` Expectations → 6 Gold MVs → 3-Page Lakeview Dashboard).
     - **Diagram 2 (Inline SVG):** *Job Lifecycle SCD Type 2 & 2-Day Removal State Machine* (New / Active → Removal Candidate → Confirmed Removed → Reappeared transitions, using strictly verified pipeline states).
     - **Diagram 3 (Local HTML+CSS Comparison Grid):** *Gen 1 vs. Gen 2 vs. Gen 3 Complexity & Runtime Comparison* (4 tasks / 7 tables → 7 tasks / 30 tables → 3 SQL files / 9 SDP objects, citing observed run durations `~14–15m` vs `~8m`).
4. **Data Quality, Governance & Honest Verification Scope**
   - Side-by-side breakdown of Gen 1/2 21-check SQL DQ gate vs. Gen 3 Lakeflow SDP `CONSTRAINT ... EXPECT` rules (`414K` expectation warnings observed in `SDP pipeline (3).png`).
   - Transparent engineering note: runtime behavior is backed by execution logs, CloudShell outputs, SQL expectations, and timestamped screenshots; automated `pytest`/unit test coverage does not exist for the pipeline notebooks/SQL.
5. **Sanitized Visual Showcase Gallery**
   - Curated tabs (*AWS Ingestion*, *Medallion & SDP Lineage*, *3-Page Lakeview Dashboard*) displaying only user-approved, sanitized screenshots (with duplicate `Dash (2).png` omitted and all 9 flagged screenshots either excluded, replaced, or cleanly redacted with opaque solid overlays).
6. **Language & Style Standard**
   - 100% **professional English** across all HTML copy, captions, diagrams, and documentation, normalizing Hinglish comments/labels found in `Portfolio\README.md`, `Portfolio\index.html`, `00_config`, `00_job_creator`, and `00_setup_tables`.

---

## 2. Phase 1–7 Execution Plan (With Entry/Exit Gates)

| Phase | Name | Planned Activities | Entry Gate | Exit Gate / Verification |
|---|---|---|---|---|
| **Phase 0** *(Current)* | **Discovery & Safety** | Read-only survey of 87 files & 10 archives; screenshot & secret audit; author `phase0_discovery_report.md`, `evidence_register.md`, `portfolio_outline_and_plan.md`. | Initial user request | All 3 Phase 0 docs complete; 87/87 baseline files unmodified; zero secret leaks; **STOP for user approval**. |
| **Phase 1** | **Scope Lock & Asset Sanitization** | Lock canonical archive selection (`stapply-deployment.zip` vs `Newacc`), persona/contact details, and screenshot policy from user answers; copy approved screenshots into `portfolio_site\assets\images\` and apply opaque redactions where approved. | Explicit user approval of Phase 0 Section 7.3 / Register Section 3 questions | Sanitized image inventory verified; zero raw secrets/IDs/emails in copied PNGs; `Dash (2).png` excluded. |
| **Phase 2** | **Information Architecture & Technical Copy** | Draft full English narrative, case-study docs (`docs\architecture_evolution.md`, `docs\data_quality_and_scd2.md`), and `portfolio_site\README.md` strictly from verified Phase 0 citations. | Phase 1 exit gate | Every metric and claim cross-referenced to `evidence_register.md`; zero Hinglish or unverified claims. |
| **Phase 3** | **Local SVG & CSS Diagram Authoring** | Build the 3 self-contained inline SVG / HTML+CSS diagrams (Architecture, SCD Type 2 State Machine, Gen 1–3 Evolution) with accessible labels and responsive viewBoxes. | Phase 2 exit gate | Zero external CDN/Kroki/Mermaid requests; clean rendering at desktop and mobile widths. |
| **Phase 4** | **Frontend Implementation (`index.html`, CSS, JS)** | Implement `portfolio_site\index.html`, `assets\css\styles.css`, and `assets\js\app.js` with responsive layout, keyboard-accessible modal/tabs, and clean typography. | Phase 3 exit gate | Semantic HTML5, zero console errors, zero external asset/CDN dependencies required for core diagrams/UI. |
| **Phase 5** | **Sensitive-Data & Non-Modification Audit** | Run automated regex + visual inspection over every file in `portfolio_site\` (HTML, CSS, JS, MD, PNGs) and re-verify `baseline_manifest.csv` (`87/87` untouched). | Phase 4 exit gate | Zero leaked tokens/emails/IDs/URIs; 0 modifications outside `portfolio_site\`. |
| **Phase 6** | **Local QA & Browser Verification** | Render `portfolio_site\index.html` locally in headless/desktop browser checks across desktop/mobile viewports; verify all image links, SVG scaling, tab switching, and accessibility contrast. | Phase 5 exit gate | Zero broken links/404s, zero layout overflow, all interactive controls verified. |
| **Phase 7** | **GitHub-Ready Packaging & Final Handoff** | Finalize `portfolio_site\README.md`, optional `.gitignore` for `portfolio_site\`, and deliver final verification report to user (**no git push or external upload without explicit command**). | Phase 6 exit gate | Clean standalone `portfolio_site\` folder ready for user review and optional GitHub publishing. |
