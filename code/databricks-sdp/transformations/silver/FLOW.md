# Silver Layer — Code Flow

## What This Does
One **Materialized View** that replaces 9 separate OVERWRITE tables from Gen2.  
Applies 9 cleaning transforms + 36-branch role taxonomy + built-in DQ expectations.  
Auto-refreshes when `bronze_jobs` updates — zero manual triggers.

---

## `silver.sql` Flow Diagram

```mermaid
flowchart TD
    A["🥉 bronze_jobs\nSCD Type 2\nAll jobs ever seen"] --> B

    subgraph DQ ["🛡️ Built-in DQ Expectations"]
        B["CONSTRAINT url_not_null\nDROP ROW if url IS NULL"]
        C["CONSTRAINT title_not_empty\nWARN if title_clean IS NULL"]
        D["CONSTRAINT company_not_empty\nWARN if company_clean IS NULL"]
        E["CONSTRAINT valid_country_iso\nWARN if length != 2"]
    end

    B & C & D & E --> F

    subgraph TRANSFORMS ["🔧 9 Cleaning Transforms"]
        F["Stage 1: posted_at_utc\nMulti-format timestamp parsing\nNULLs '1900-' dates\nHandles ISO 8601 with TZ offset"]
        F --> G["Stage 2: commitment_normalized\n15+ raw variants → 5 canonical:\nFull-time · Part-time · Contract\nInternship · Other\nCovers EN/DE/FR/PT variants"]
        G --> H["Stage 3: Salary typed columns\nsalary_min/max → DOUBLE\ncurrency/period → UPPER TRIM"]
        H --> I["Stage 4: is_remote_bool\nstring 'true'/'false' → BOOLEAN\n+ remote_data_quality_flag\nMISMATCH if commitment=remote AND is_remote=false"]
        I --> J["Stage 5: country_iso_clean\nLength check: must be 2 chars\nInvalid codes CE·SF → NULL\nQuality flag: VALID/INVALID/MISSING"]
        J --> K["Stage 6: location_clean\nStrip whitespace\nPlaceholders TBA·TBD·N/A → NULL\nQuality flag: VALID/PLACEHOLDER/MISSING"]
        K --> L["Stage 7: title_clean\nNumeric-only → NULL\nnull/none/tbd strings → NULL"]
        L --> M["Stage 8: company_clean\ntest·demo placeholders → NULL"]
        M --> N["Stage 9: role_family\n36-branch V2 taxonomy\nKeyword RLIKE matching\non title field\n+ role_classification_version = V2"]
    end

    N --> O["Age Calculation\njob_age_days = DATEDIFF today\njob_age_bucket:\nFresh 0-7d / Recent 8-30d\nAgeing 31-90d / Older >90d\nDate Unknown"]

    O --> P["🥈 silver_enriched\nMaterialized View\nAuto-refresh on bronze update\nCLUSTER BY country_iso_clean"]
```

---

## Role Family Taxonomy (36-branch V2)

```mermaid
flowchart LR
    T["title field\noriginal ATS value"] --> RLIKE["RLIKE pattern matching\ncase-insensitive"]

    RLIKE --> DE["Data Engineering\ndata engineer · etl · pipeline\nlakehouse · spark · airflow\ndbt · databricks · kafka · flink"]
    RLIKE --> ML["ML / AI\ndata scien · ml engineer\nmachine learn · nlp · llm\nmlops · ai engineer"]
    RLIKE --> BI["Analytics / BI\ndata anal · bi developer\nbusiness intel · power bi\ntableau · looker · report"]
    RLIKE --> SWE["Software Engineering\nsoftware engineer · backend\nfrontend · full-stack · sde"]
    RLIKE --> DO["DevOps / Platform\ndevops · sre · platform engineer\nkubernetes · terraform · cloud"]
    RLIKE --> OTHER["14 more families...\nProduct · Design/UX · Sales\nMarketing · Finance · Legal\nHR · Customer Success · Security\n+ Other"]
```

---

## Gen2 vs Gen3 Comparison

| | Gen2 (9 OVERWRITE tables) | Gen3 (1 Materialized View) ✅ |
|--|--------------------------|-------------------------------|
| **Code lines** | ~400 (9 separate CREATE TABLE) | ~180 (1 MV query) |
| **Refresh** | Manual trigger per stage | Auto-refresh |
| **DQ** | Separate notebook | Built-in CONSTRAINT |
| **Consistency** | Risk of partial failure | Atomic MV refresh |
| **Runtime** | ~8 min Silver stage | Merged into pipeline |
