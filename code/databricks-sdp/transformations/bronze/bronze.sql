-- ============================================================
-- BRONZE LAYER — Stapply Job Market Enterprise Pipeline
-- ============================================================
-- Auto Loader ingestion + Auto CDC FROM SNAPSHOT (SCD Type 2)
-- Data NEVER lost. Removed jobs preserved with __END_AT.
--
-- NOTE: {{S3_PATH}} is a template placeholder replaced at deploy
--       time by 01_deploy.py reading config.py. Never hard-code
--       your S3 bucket path here.
-- ============================================================

-- ── Table 1: Raw snapshot ingest (Auto Loader checkpoint-based) ──────────────
CREATE OR REFRESH STREAMING TABLE bronze_raw (
  CONSTRAINT valid_url EXPECT (url IS NOT NULL) ON VIOLATION DROP ROW
)
COMMENT 'Raw S3 snapshots — audit trail. Auto Loader checkpoint-based ingestion.'
AS SELECT *
FROM STREAM(read_files(
  '{{S3_PATH}}',          -- injected by 01_deploy.py from config.py
  format => 'parquet'
));


-- ── Table 2: SCD Type 2 job history (Auto CDC FROM SNAPSHOT) ─────────────────
-- __END_AT IS NULL  → job is currently active in ATS feed
-- __END_AT IS NOT NULL → job was removed (preserved forever)
CREATE OR REFRESH STREAMING TABLE bronze_jobs
CLUSTER BY (url)
COMMENT 'All job URLs ever seen. SCD Type 2: __END_AT IS NULL = active, IS NOT NULL = removed/historical.';

CREATE FLOW bronze_snapshot_cdc
AS AUTO CDC INTO bronze_jobs
FROM SNAPSHOT (
  SELECT
    url, title, company, ats_type, ats_id, location, country_iso,
    region, language, lat, lon, is_remote, salary_min, salary_max,
    salary_currency, salary_period, salary_summary, employment_type,
    department, team, description, posted_at, requisition_id,
    apply_url, commitment
  FROM bronze_raw
  WHERE snapshot_date = (SELECT version FROM current_snapshot_version())
)
WITH VERSION (
  SELECT snapshot_date AS version
  FROM (SELECT DISTINCT snapshot_date FROM bronze_raw)
  WHERE (
    NOT EXISTS (SELECT 1 FROM last_snapshot_version())
    OR snapshot_date > (SELECT version FROM last_snapshot_version())
  )
  ORDER BY snapshot_date
  LIMIT 1
)
KEYS (url)
STORED AS SCD TYPE 2
TRACK HISTORY ON
  title, company, location, country_iso, is_remote,
  salary_min, salary_max, salary_currency, salary_period,
  commitment, employment_type, department, team;
