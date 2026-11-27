-- ============================================================
-- Gen2 Reference — Gold Layer Table DDL
-- ============================================================
-- This is the Gen2 architecture (Databricks Classic Jobs, 4 tasks,
-- 7 tables). Kept for reference — superseded by Gen3 SDP (3 SQL files,
-- 9 SDP objects, serverless).
--
-- Gen2 → Gen3 key changes:
--   - OVERWRITE tables → Materialized Views (auto-refresh)
--   - 9 Silver OVERWRITE stages → 1 Silver MV (single query)
--   - Manual MERGE lifecycle → Auto CDC FROM SNAPSHOT (SCD Type 2)
--   - ~14-15 min runtime → ~8 min (Photon + serverless)
-- ============================================================

-- ── Core lifecycle tracking table ────────────────────────────────────────────
CREATE TABLE workspace.gold.job_lifecycle (
  url                         STRING        COMMENT 'Primary key. Original job posting URL.',
  title_clean                 STRING        COMMENT 'Cleaned job title. NULL if raw was empty/numeric/null-string.',
  company_clean               STRING        COMMENT 'Cleaned company name. NULL if raw was placeholder/numeric.',
  company_analytics_name      STRING        COMMENT 'Canonical name from company_identity_mapping_v1. Falls back to company_clean.',
  country_iso_clean           STRING        COMMENT 'ISO country code. Invalid codes (CE, SF) mapped to NULL.',
  role_family                 STRING        COMMENT '36-branch V2 role taxonomy derived from title_clean.',
  role_classification_version STRING        COMMENT 'Version of role taxonomy (currently V2).',
  ats_type                    STRING        COMMENT 'Applicant Tracking System type (Greenhouse, Lever, Ashby, etc.).',
  ats_id                      STRING        COMMENT 'ATS-specific job identifier.',
  location                    STRING        COMMENT 'Raw location string from the listing.',
  employment_type             STRING        COMMENT 'Employment type (Full-time, Part-time, Contract, etc.).',
  department                  STRING        COMMENT 'Department or business unit.',
  team                        STRING        COMMENT 'Team within department.',
  language                    STRING        COMMENT 'Language of the listing.',
  region                      STRING        COMMENT 'Geographic region.',
  commitment_normalized       STRING        COMMENT 'Normalized commitment level.',
  description_clean           STRING        COMMENT 'Cleaned description. NULL if empty/null-string.',
  posted_at_utc               TIMESTAMP     COMMENT 'UTC timestamp when job was posted. Parsed from multiple formats.',
  job_age_days                INT           COMMENT 'Days since posted_at_utc. Recomputed daily.',
  job_age_bucket              STRING        COMMENT 'Fresh (0-7d) / Recent (8-30d) / Ageing (31-90d) / Older (>90d) / Date Unknown.',
  is_remote_bool              BOOLEAN       COMMENT 'Whether job is remote. True/False/NULL.',
  salary_min_numeric          DOUBLE        COMMENT 'Minimum salary as DOUBLE.',
  salary_max_numeric          DOUBLE        COMMENT 'Maximum salary as DOUBLE.',
  salary_currency_normalized  STRING        COMMENT 'Normalized salary currency (uppercase).',
  salary_period_normalized    STRING        COMMENT 'Normalized salary period (uppercase).',
  requisition_id              STRING        COMMENT 'Internal requisition ID from ATS.',
  apply_url                   STRING        COMMENT 'Application URL.',
  first_seen_date             DATE          COMMENT 'Date URL first observed. Never overwritten.',
  last_seen_date              DATE          COMMENT 'Most recent snapshot date URL was present.',
  last_snapshot_date          DATE          COMMENT 'Snapshot date of last pipeline run.',
  missing_since_date          DATE          COMMENT 'Date URL first noticed missing from feed.',
  removal_confirmed_date      DATE          COMMENT 'Date removal confirmed after grace period.',
  lifecycle_status            STRING        COMMENT 'Active / Removal Candidate / Removed from Active Feed.',
  times_seen                  BIGINT        COMMENT 'Count of distinct snapshot dates URL appeared.',
  times_missing               BIGINT        COMMENT 'Cumulative count of missing events (not reset on reappearance).',
  latest_event_type           STRING        COMMENT 'New / Retained / Reappeared / Removal Candidate / Confirmed Removed.',
  lifecycle_version           STRING        COMMENT 'Lifecycle logic version (V1).',
  updated_at_utc              TIMESTAMP     COMMENT 'UTC timestamp of last MERGE update.',
  latest_event_date           DATE          COMMENT 'Date of most recent lifecycle event.'
)
USING delta
COMMENT 'Gen2: Core lifecycle tracking (39 cols). Superseded by Gen3 bronze_jobs (SCD Type 2) + gold_job_market_explorer.'
TBLPROPERTIES (
  'delta.enableDeletionVectors' = 'true',
  'delta.enableRowTracking'     = 'true',
  'delta.minReaderVersion'      = '3',
  'delta.minWriterVersion'      = '7'
);


-- ── Job change events (audit trail) ──────────────────────────────────────────
CREATE TABLE workspace.gold.job_change_events (
  event_id          STRING    COMMENT 'Unique event identifier (UUID).',
  url               STRING    COMMENT 'Job URL — FK to job_lifecycle.',
  event_type        STRING    COMMENT 'New / Retained / Reappeared / Removal Candidate / Confirmed Removed.',
  event_date        DATE      COMMENT 'Date the event was recorded.',
  snapshot_date     DATE      COMMENT 'Snapshot that triggered the event.',
  previous_status   STRING    COMMENT 'lifecycle_status before this event.',
  new_status        STRING    COMMENT 'lifecycle_status after this event.',
  times_seen        BIGINT    COMMENT 'times_seen at time of event.',
  times_missing     BIGINT    COMMENT 'times_missing at time of event.',
  title_clean       STRING,
  company_clean     STRING,
  country_iso_clean STRING,
  role_family       STRING,
  is_remote_bool    BOOLEAN,
  salary_min_numeric DOUBLE,
  salary_max_numeric DOUBLE,
  salary_currency_normalized STRING,
  employment_type   STRING,
  job_age_days      INT,
  job_age_bucket    STRING,
  posted_at_utc     TIMESTAMP,
  created_at_utc    TIMESTAMP COMMENT 'Row insertion timestamp.',
  pipeline_run_id   STRING    COMMENT 'Databricks job run_id that created this event.',
  lifecycle_version STRING    COMMENT 'V1.'
)
USING delta
COMMENT 'Gen2: Full audit trail of lifecycle state changes (25 cols). Append-only.'
TBLPROPERTIES (
  'delta.enableDeletionVectors' = 'true',
  'delta.enableRowTracking'     = 'true'
);
