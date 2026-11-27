-- ============================================================
-- GOLD LAYER — Stapply Job Market Enterprise Pipeline
-- ============================================================
-- 6 Materialized Views, all built from silver_enriched.
-- Dashboard-ready. No joins to external tables needed.
-- All views auto-refresh when silver_enriched updates.
-- ============================================================

-- ── 1. Active Job Market Summary (top-level KPIs) ────────────────────────────
CREATE OR REFRESH MATERIALIZED VIEW gold_active_summary
CLUSTER BY (snapshot_date)
COMMENT 'Daily KPI snapshot: total active jobs, companies, remote %, fresh %. One row per pipeline run.'
AS
SELECT
  CURRENT_DATE()                                              AS snapshot_date,
  COUNT(*)                                                    AS total_active_jobs,
  COUNT(DISTINCT company_clean)                               AS distinct_companies,
  COUNT(DISTINCT country_iso_clean)                           AS distinct_countries,
  ROUND(100.0 * SUM(CASE WHEN is_remote_bool THEN 1 ELSE 0 END) / COUNT(*), 2) AS remote_pct,
  ROUND(100.0 * SUM(CASE WHEN job_age_bucket = 'Fresh'  THEN 1 ELSE 0 END) / COUNT(*), 2) AS fresh_pct,
  ROUND(100.0 * SUM(CASE WHEN job_age_bucket = 'Recent' THEN 1 ELSE 0 END) / COUNT(*), 2) AS recent_pct,
  SUM(CASE WHEN salary_min_numeric IS NOT NULL THEN 1 ELSE 0 END) AS jobs_with_salary
FROM silver_enriched
WHERE __END_AT IS NULL;    -- active jobs only


-- ── 2. Role Family Breakdown ──────────────────────────────────────────────────
CREATE OR REFRESH MATERIALIZED VIEW gold_role_family_summary
CLUSTER BY (role_family)
COMMENT 'Per-role-family KPIs for dashboard bar/donut charts. Active jobs only.'
AS
SELECT
  role_family,
  COUNT(*)                                                    AS total_jobs,
  COUNT(DISTINCT company_clean)                               AS distinct_companies,
  COUNT(DISTINCT country_iso_clean)                           AS distinct_countries,
  SUM(CASE WHEN is_remote_bool THEN 1 ELSE 0 END)            AS remote_jobs,
  ROUND(AVG(salary_min_numeric), 2)                          AS avg_min_salary,
  ROUND(AVG(salary_max_numeric), 2)                          AS avg_max_salary,
  SUM(CASE WHEN job_age_bucket = 'Fresh'  THEN 1 ELSE 0 END) AS fresh_jobs,
  SUM(CASE WHEN job_age_bucket = 'Recent' THEN 1 ELSE 0 END) AS recent_jobs
FROM silver_enriched
WHERE __END_AT IS NULL
GROUP BY role_family;


-- ── 3. Country × Role × Company Summary ──────────────────────────────────────
CREATE OR REFRESH MATERIALIZED VIEW gold_country_role_company_summary
CLUSTER BY (country_iso, role_family)
COMMENT 'Per-country, per-role, per-company breakdown. Supports geo + filter slicing in dashboard.'
AS
SELECT
  country_iso_clean                                          AS country_iso,
  role_family,
  company_clean,
  COUNT(*)                                                   AS total_jobs,
  SUM(CASE WHEN is_remote_bool THEN 1 ELSE 0 END)           AS remote_jobs,
  ROUND(AVG(salary_min_numeric), 2)                         AS avg_min_salary,
  ROUND(AVG(salary_max_numeric), 2)                         AS avg_max_salary,
  MAX(salary_max_numeric)                                   AS max_salary,
  SUM(CASE WHEN job_age_bucket = 'Fresh'  THEN 1 ELSE 0 END) AS fresh_jobs,
  SUM(CASE WHEN job_age_bucket = 'Recent' THEN 1 ELSE 0 END) AS recent_jobs,
  SUM(CASE WHEN job_age_bucket = 'Ageing' THEN 1 ELSE 0 END) AS ageing_jobs,
  SUM(CASE WHEN job_age_bucket = 'Older'  THEN 1 ELSE 0 END) AS older_jobs,
  MIN(posted_at_utc)                                        AS earliest_posted_at,
  MAX(posted_at_utc)                                        AS latest_posted_at
FROM silver_enriched
WHERE __END_AT IS NULL
  AND country_iso_clean IS NOT NULL
GROUP BY country_iso_clean, role_family, company_clean;


-- ── 4. Country × Role × Location Summary ─────────────────────────────────────
CREATE OR REFRESH MATERIALIZED VIEW gold_country_role_location_summary
CLUSTER BY (country_iso, role_family)
COMMENT 'Per-location breakdown by country + role — active jobs only.'
AS
SELECT
  country_iso_clean                                          AS country_iso,
  role_family,
  location,
  COUNT(*)                                                   AS total_jobs,
  COUNT(DISTINCT company_clean)                              AS distinct_companies,
  SUM(CASE WHEN is_remote_bool THEN 1 ELSE 0 END)           AS remote_jobs,
  SUM(CASE WHEN job_age_bucket = 'Fresh'  THEN 1 ELSE 0 END) AS fresh_jobs,
  SUM(CASE WHEN job_age_bucket = 'Recent' THEN 1 ELSE 0 END) AS recent_jobs,
  MIN(posted_at_utc)                                        AS earliest_posted_at,
  MAX(posted_at_utc)                                        AS latest_posted_at
FROM silver_enriched
WHERE __END_AT IS NULL
  AND country_iso_clean IS NOT NULL
  AND location IS NOT NULL AND TRIM(location) != ''
GROUP BY country_iso_clean, role_family, location;


-- ── 5. Job Market Explorer (Dashboard main table) ─────────────────────────────
CREATE OR REFRESH MATERIALIZED VIEW gold_job_market_explorer
CLUSTER BY (country_iso_clean, role_family)
COMMENT 'Dashboard-ready explorer table. Active + historical jobs with full enrichment.'
AS
SELECT
  url, title_clean, role_family, company_clean,
  country_iso_clean, location, ats_type,
  employment_type, commitment_normalized,
  is_remote_bool, remote_data_quality_flag,
  job_age_days, job_age_bucket,
  salary_min_numeric, salary_max_numeric,
  salary_currency_normalized, salary_period_normalized,
  posted_at_utc, description_clean,
  requisition_id, apply_url, department, team,
  language, region,
  country_data_quality_flag, location_data_quality_flag,
  __START_AT AS first_seen_at,
  __END_AT   AS removed_at,
  CASE WHEN __END_AT IS NULL THEN 'Active' ELSE 'Removed' END AS lifecycle_status,
  'V1' AS explorer_version
FROM silver_enriched;


-- ── 6. Daily Movement (lifecycle analytics — new vs removed per day) ──────────
CREATE OR REFRESH MATERIALIZED VIEW gold_daily_movement
COMMENT 'Daily new/removed job counts derived from SCD Type 2 __START_AT / __END_AT.'
AS
SELECT
  DATE(__START_AT)  AS event_date,
  'New'             AS event_type,
  COUNT(*)          AS job_count
FROM bronze_jobs
GROUP BY DATE(__START_AT)

UNION ALL

SELECT
  DATE(__END_AT)    AS event_date,
  'Removed'         AS event_type,
  COUNT(*)          AS job_count
FROM bronze_jobs
WHERE __END_AT IS NOT NULL
GROUP BY DATE(__END_AT);
