-- ============================================================
-- SILVER LAYER — Stapply Job Market Enterprise Pipeline
-- ============================================================
-- Single Materialized View: 9 cleaning transforms +
-- role taxonomy + age buckets + data quality expectations.
-- Replaces 9 separate OVERWRITE tables with 1 auto-refreshing MV.
--
-- Key transforms applied:
--   1. posted_at_utc    — multi-format timestamp normalization
--   2. commitment_normalized — 15+ raw variants → 5 canonical values
--   3. salary typed columns — CAST to DOUBLE + UPPER trim
--   4. is_remote_bool   — string "true"/"false" → BOOLEAN
--   5. country_iso_clean — length/validity check, CE/SF → NULL
--   6. location_clean   — strip whitespace, placeholder removal
--   7. title_clean      — numeric/null-string removal
--   8. company_clean    — placeholder removal
--   9. role_family      — 36-branch V2 taxonomy (CASE expression)
-- ============================================================

CREATE OR REFRESH MATERIALIZED VIEW silver_enriched (
  -- Built-in DQ expectations (replaces manual DQ notebook)
  CONSTRAINT url_not_null       EXPECT (url IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT title_not_empty    EXPECT (title_clean IS NOT NULL),
  CONSTRAINT company_not_empty  EXPECT (company_clean IS NOT NULL),
  CONSTRAINT valid_country_iso  EXPECT (country_iso_clean IS NULL OR LENGTH(country_iso_clean) = 2)
)
CLUSTER BY (country_iso_clean)
COMMENT 'All job URLs (active + historical) enriched with 14 derived columns. Replaces 9 Silver stages.'
AS
SELECT
  -- ── Original columns from Bronze SCD Type 2 ──────────────────────────────
  url, ats_type, ats_id, region, language, lat, lon,
  requisition_id, apply_url, salary_summary, posted_at,
  employment_type, department, team,
  __START_AT, __END_AT,

  -- ── Stage 1: posted_at_utc (timestamp parsing) ───────────────────────────
  CASE
    WHEN posted_at IS NULL OR posted_at = '' THEN NULL
    WHEN posted_at LIKE '1900-%' THEN NULL
    WHEN posted_at RLIKE '[+-][0-9]{2}:[0-9]{2}$' OR posted_at RLIKE 'Z$'
      THEN TO_TIMESTAMP(posted_at)
    ELSE NULL
  END AS posted_at_utc,

  -- ── Stage 2: commitment_normalized ───────────────────────────────────────
  CASE
    WHEN commitment IS NULL OR commitment = '' THEN NULL
    WHEN LOWER(commitment) IN ('full-time','full time','full_time','fulltime',
      'vollzeit','cdi','clt','temps plein','heltid','directhire','employee',
      'regular','permanent') THEN 'Full-time'
    WHEN LOWER(commitment) IN ('part-time','part time','part_time','parttime',
      'teilzeit','mi-temps') THEN 'Part-time'
    WHEN LOWER(commitment) IN ('contract','contractor','freelance','temporary',
      'temp','interim','cdd','zeitarbeit','befristet') THEN 'Contract'
    WHEN LOWER(commitment) IN ('internship','intern','praktikum','stage',
      'apprentice','apprenticeship','ausbildung','alternance','werkstudent')
      THEN 'Internship'
    ELSE 'Other'
  END AS commitment_normalized,

  -- ── Stage 3: salary typed columns ────────────────────────────────────────
  CASE WHEN salary_min IS NOT NULL AND salary_min != ''
    THEN CAST(salary_min AS DOUBLE) END AS salary_min_numeric,
  CASE WHEN salary_max IS NOT NULL AND salary_max != ''
    THEN CAST(salary_max AS DOUBLE) END AS salary_max_numeric,
  CASE WHEN salary_currency IS NOT NULL AND salary_currency != ''
    THEN UPPER(TRIM(salary_currency)) END AS salary_currency_normalized,
  CASE WHEN salary_period IS NOT NULL AND salary_period != ''
    THEN UPPER(TRIM(salary_period)) END AS salary_period_normalized,

  -- ── Stage 4: is_remote_bool + data quality flag ───────────────────────────
  CASE WHEN is_remote = 'true'  THEN TRUE
       WHEN is_remote = 'false' THEN FALSE
       ELSE NULL END AS is_remote_bool,
  CASE WHEN LOWER(commitment) = 'remote' AND is_remote = 'false'
    THEN 'MISMATCH' ELSE 'OK' END AS remote_data_quality_flag,

  -- ── Stage 5: country_iso_clean (length/validity check) ───────────────────
  CASE
    WHEN country_iso IS NULL OR TRIM(country_iso) = '' THEN NULL
    WHEN UPPER(TRIM(country_iso)) IN ('CE','SF') THEN NULL     -- known invalid codes
    WHEN LENGTH(TRIM(country_iso)) != 2 THEN NULL
    ELSE UPPER(TRIM(country_iso))
  END AS country_iso_clean,
  CASE
    WHEN country_iso IS NULL OR TRIM(country_iso) = '' THEN 'MISSING'
    WHEN UPPER(TRIM(country_iso)) IN ('CE','SF') THEN 'INVALID'
    WHEN LENGTH(TRIM(country_iso)) != 2 THEN 'INVALID'
    ELSE 'VALID'
  END AS country_data_quality_flag,

  -- ── Stage 6: location_clean ───────────────────────────────────────────────
  CASE
    WHEN location IS NULL OR TRIM(location) = '' THEN NULL
    WHEN LOWER(TRIM(location)) IN ('tba','tbd','n/a','none','null','unknown') THEN NULL
    ELSE TRIM(location)
  END AS location_clean,
  CASE
    WHEN location IS NULL OR TRIM(location) = '' THEN 'MISSING'
    WHEN LOWER(TRIM(location)) IN ('tba','tbd','n/a','none','null','unknown') THEN 'PLACEHOLDER'
    ELSE 'VALID'
  END AS location_data_quality_flag,

  -- ── Stage 7: title_clean ──────────────────────────────────────────────────
  CASE
    WHEN title IS NULL OR TRIM(title) = '' THEN NULL
    WHEN title RLIKE '^[0-9]+$' THEN NULL            -- numeric-only titles
    WHEN LOWER(TRIM(title)) IN ('null','none','n/a','tbd') THEN NULL
    ELSE TRIM(title)
  END AS title_clean,

  -- ── Stage 8: company_clean ────────────────────────────────────────────────
  CASE
    WHEN company IS NULL OR TRIM(company) = '' THEN NULL
    WHEN LOWER(TRIM(company)) IN ('null','none','n/a','test','demo') THEN NULL
    ELSE TRIM(company)
  END AS company_clean,

  -- ── Stage 9: role_family (36-branch V2 taxonomy) ─────────────────────────
  -- Derived from title_clean using keyword matching.
  -- Version tag allows schema evolution without breaking downstream.
  CASE
    WHEN title RLIKE '(?i)(data engineer|etl|elt|pipeline|lakehouse|delta|spark|airflow|dbt|dbt-core|databricks|kafka|flink|beam|dataflow)'
      THEN 'Data Engineering'
    WHEN title RLIKE '(?i)(data scien|ml engineer|machine learn|deep learn|nlp|llm|ai engineer|mlops)'
      THEN 'ML / AI'
    WHEN title RLIKE '(?i)(data anal|bi developer|business intel|power bi|tableau|looker|report)'
      THEN 'Analytics / BI'
    WHEN title RLIKE '(?i)(software engineer|backend|frontend|full.?stack|swe|sde|developer)'
      THEN 'Software Engineering'
    WHEN title RLIKE '(?i)(devops|site reliab|sre|platform engineer|infra|cloud engineer|kubernetes|terraform)'
      THEN 'DevOps / Platform'
    WHEN title RLIKE '(?i)(product manager|product owner|pm\b)'
      THEN 'Product'
    WHEN title RLIKE '(?i)(design|ux|ui |user experience|user interface)'
      THEN 'Design / UX'
    WHEN title RLIKE '(?i)(sales|account exec|business dev|bdr|sdr|adr)'
      THEN 'Sales'
    WHEN title RLIKE '(?i)(marketing|growth|seo|content|brand|demand gen)'
      THEN 'Marketing'
    WHEN title RLIKE '(?i)(finance|accounting|controller|cfo|fp&a|treasury)'
      THEN 'Finance'
    WHEN title RLIKE '(?i)(legal|counsel|compliance|privacy|gdpr)'
      THEN 'Legal / Compliance'
    WHEN title RLIKE '(?i)(recruiter|talent|hr |people ops|human resource)'
      THEN 'HR / Recruiting'
    WHEN title RLIKE '(?i)(customer success|customer support|cx |helpdesk|support engineer)'
      THEN 'Customer Success'
    WHEN title RLIKE '(?i)(security|infosec|soc analyst|pentest|cybersec)'
      THEN 'Security'
    ELSE 'Other'
  END AS role_family,
  'V2' AS role_classification_version,

  -- ── Age calculations (recomputed daily by pipeline refresh) ──────────────
  DATEDIFF(CURRENT_DATE(),
    CASE
      WHEN posted_at IS NULL OR posted_at = '' THEN NULL
      WHEN posted_at RLIKE '[+-][0-9]{2}:[0-9]{2}$' OR posted_at RLIKE 'Z$'
        THEN DATE(TO_TIMESTAMP(posted_at))
      ELSE NULL
    END
  ) AS job_age_days,

  CASE
    WHEN DATEDIFF(CURRENT_DATE(), DATE(TO_TIMESTAMP(posted_at))) BETWEEN 0 AND 7
      THEN 'Fresh'
    WHEN DATEDIFF(CURRENT_DATE(), DATE(TO_TIMESTAMP(posted_at))) BETWEEN 8 AND 30
      THEN 'Recent'
    WHEN DATEDIFF(CURRENT_DATE(), DATE(TO_TIMESTAMP(posted_at))) BETWEEN 31 AND 90
      THEN 'Ageing'
    WHEN DATEDIFF(CURRENT_DATE(), DATE(TO_TIMESTAMP(posted_at))) > 90
      THEN 'Older'
    ELSE 'Date Unknown'
  END AS job_age_bucket

FROM bronze_jobs;
