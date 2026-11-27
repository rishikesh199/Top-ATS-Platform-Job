# Gold Layer — Code Flow

## What This Does
Six **Materialized Views** built on `silver_enriched`.  
Dashboard-ready. Auto-refresh on every Silver update. Zero ETL jobs needed.

---

## `gold.sql` — All 6 Views Flow

```mermaid
flowchart TD
    S["🥈 silver_enriched\nAll jobs: active + historical\nFull enrichment applied"] --> G1 & G2 & G3 & G4 & G5 & G6

    subgraph GOLD ["🥇 Gold Materialized Views"]
        G1["gold_active_summary\nDaily KPI snapshot\nOne row per pipeline run:\ntotal_active_jobs\ndistinct_companies / countries\nremote_pct · fresh_pct\njobs_with_salary"]

        G2["gold_role_family_summary\nPer-role bar charts:\nrole_family\ntotal_jobs · distinct_companies\nremote_jobs\navg_min/max_salary\nfresh/recent jobs count"]

        G3["gold_job_market_explorer\nMain dashboard table:\nAll columns from silver\nlifecycle_status Active/Removed\nfirst_seen_at · removed_at\nexplorer_version = V1\nCLUSTER BY country + role"]

        G4["gold_country_role_company_summary\nCountry × Role × Company:\ntotal_jobs · remote_jobs\navg/max salary\nage bucket breakdown\nFresh/Recent/Ageing/Older"]

        G5["gold_country_role_location_summary\nCountry × Role × Location:\ntotal_jobs · distinct_companies\nremote_jobs · fresh/recent jobs\nearliset/latest posted_at"]

        G6["gold_daily_movement\nNew vs Removed trend:\nUNION ALL of\n__START_AT = New events\n__END_AT = Removed events\nOne row per day per event_type"]
    end

    G1 & G2 & G3 & G4 & G5 & G6 --> D["📊 Lakeview Dashboard\n4 Pages · 22 Datasets\nAuto-refresh on pipeline run"]
```

---

## Dashboard Mapping

```mermaid
flowchart LR
    subgraph PAGE1 ["📊 Page 1 — Market Overview"]
        P1A["Total active jobs KPI"] --- G1
        P1B["ATS type distribution"] --- G2
        P1C["Remote % gauge"] --- G1
        P1D["Fresh jobs %"] --- G1
    end

    subgraph PAGE2 ["📊 Page 2 — Salary Analysis"]
        P2A["Avg salary by role"] --- G2
        P2B["Salary by country"] --- G4
        P2C["Salary range scatter"] --- G3
    end

    subgraph PAGE3 ["📊 Page 3 — Job Age"]
        P3A["Fresh/Recent/Ageing/Older bars"] --- G2
        P3B["Age by country heatmap"] --- G4
    end

    subgraph PAGE4 ["📊 Page 4 — Explorer"]
        P4A["Full row-level table\nFilter: country · role · company\nATS · remote · age bucket"] --- G3
        P4B["Daily new vs removed trend"] --- G6
    end
```

---

## `gold_daily_movement` — SCD2 Lifecycle Analytics

```mermaid
flowchart LR
    B["🥉 bronze_jobs\n__START_AT and __END_AT"] --> UNION

    subgraph UNION ["UNION ALL"]
        NEW["SELECT DATE of __START_AT\nevent_type = New\nCOUNT per day"]
        REM["SELECT DATE of __END_AT\nWHERE __END_AT IS NOT NULL\nevent_type = Removed\nCOUNT per day"]
    end

    UNION --> RESULT["event_date · event_type · job_count\nOne row per day per type\nShows market velocity:\nHow many jobs added/removed daily"]
```

---

## Key Design Decisions

| Decision | Why |
|----------|-----|
| Materialized Views (not tables) | Auto-refresh — no CRON job needed to rebuild Gold |
| All views filter `__END_AT IS NULL` where relevant | Active-only metrics for KPI views |
| `gold_job_market_explorer` keeps full history | Explorer lets analysts filter Active vs Removed |
| `CLUSTER BY (country_iso_clean, role_family)` | Optimizes dashboard geo + role filter queries |
| `gold_daily_movement` uses UNION ALL | Avoids complex window functions — readable and fast |
