# Bronze Layer — Code Flow

## What This Does
Ingests daily Parquet snapshots from S3 into Delta Lake using **Auto Loader**,  
then tracks every job's full history using **Auto CDC FROM SNAPSHOT (SCD Type 2)**.

> **Key insight:** A job posting that disappears from the ATS feed is NOT deleted.  
> It gets `__END_AT` stamped. History is preserved forever.

---

## `bronze.sql` Flow Diagram

```mermaid
flowchart TD
    A["☁️ S3\nraw/stapply/snapshots/\nsnapshot_date=YYYY-MM-DD/\nall.parquet"] -->|"Auto Loader\nread_files parquet\ncheckpoint-based"| B

    subgraph BRONZE_RAW ["🥉 bronze_raw — Streaming Table"]
        B["CONSTRAINT: valid_url\nurl IS NOT NULL\nON VIOLATION DROP ROW"]
        B --> C["Append-only audit trail\nEvery snapshot preserved\nSchema evolution auto-detected"]
    end

    C --> D["AUTO CDC FROM SNAPSHOT\nbronze_snapshot_cdc FLOW"]

    subgraph CDC_LOGIC ["🔄 CDC Version Selection Logic"]
        D --> E{"last_snapshot_version\nexists?"}
        E -->|"First run"| F["Take lowest snapshot_date\nfrom bronze_raw"]
        E -->|"Subsequent runs"| G["Take snapshot_date\n> last version\nORDER BY date LIMIT 1"]
        F --> H["Process one snapshot\nper pipeline update"]
        G --> H
    end

    H -->|"KEYS url\nSTORED AS SCD TYPE 2"| I

    subgraph BRONZE_JOBS ["🥉 bronze_jobs — SCD Type 2 Table"]
        I["__START_AT = when first seen\n__END_AT = when removed\n__END_AT IS NULL = Active NOW\n__END_AT IS NOT NULL = Historical"]
        I --> J["TRACK HISTORY ON:\ntitle · company · location\ncountry_iso · is_remote\nsalary_min · salary_max\nsalary_currency · salary_period\ncommitment · employment_type\ndepartment · team"]
    end

    I --> K["CLUSTER BY url\nFast lookups by job URL"]
```

---

## SCD Type 2 State Machine

```mermaid
stateDiagram-v2
    [*] --> Active : Job appears in snapshot\n__START_AT = today\n__END_AT = NULL

    Active --> Active : Job retained in next snapshot\nNo change — row unchanged

    Active --> Removed : Job missing from snapshot\n__END_AT = today stamped\nNew row NOT created

    Removed --> Active : Job reappears\nNew row: __START_AT = today\n__END_AT = NULL\nOld row stays with __END_AT

    Active --> [*] : Query time\n__END_AT IS NULL
    Removed --> [*] : Query time\n__END_AT IS NOT NULL
```

---

## Key Design Decisions

| Decision | Why |
|----------|-----|
| Auto Loader (not COPY INTO) | Checkpoint-based — exactly-once, no duplicate ingestion |
| SCD Type 2 (not OVERWRITE) | Full history preserved — can query any point in time |
| `LIMIT 1` per pipeline update | Processes one snapshot at a time — prevents version skips |
| `CONSTRAINT valid_url DROP ROW` | Rejects malformed rows at ingest — doesn't fail the pipeline |
| `CLUSTER BY (url)` | Optimizes SCD2 lookup performance on the primary key |
