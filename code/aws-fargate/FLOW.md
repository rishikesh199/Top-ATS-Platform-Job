# AWS Fargate Scraper — Code Flow

## What This Does
Daily ATS job scraper running as a **serverless ECS Fargate container**.  
Triggered by EventBridge → streams job data from ATS APIs → writes Parquet to S3.

---

## `app.py` Flow Diagram

```mermaid
flowchart TD
    A["🕘 EventBridge Trigger\ncron 09:00 IST daily"] --> B["ECS Fargate Task Starts\npython app.py"]

    B --> C["Read Environment\nS3_BUCKET from ECS Task Definition\nAWS_DEFAULT_REGION = eu-north-1"]

    C --> D["Loop: ATS Sources\nGreenhouse · Lever · Ashby\n+ 5 more ATS types"]

    D --> E["fetch_ats_jobs\nHTTP GET with stream=True\n8 MiB chunk size"]

    E --> F{Request OK?}
    F -->|"✅ 200"| G["normalize_job\nFlatten to canonical schema:\nurl, title, company, ats_type,\nlocation, posted_at, is_remote,\nemployment_type, department..."]
    F -->|"❌ Error"| H["log.warning\nSkip company\nContinue loop"]

    G --> I["Accumulate all_jobs list"]
    H --> D
    I --> D

    D -->|"All companies done"| J{any jobs?}
    J -->|"0 jobs"| K["⚠️ log warning\nSkip upload\nTask exits 0"]
    J -->|">0 jobs"| L["jobs_to_parquet_bytes\npa.Table.from_pylist\npq.write_table snappy compression"]

    L --> M["upload_to_s3"]
    M --> N{Size >= 64 MiB?}

    N -->|"Large"| O["S3 Multipart Upload\ncreate_multipart_upload\nupload_part loop\ncomplete_multipart_upload"]
    N -->|"Small"| P["s3.put_object\nsingle PUT"]

    O --> Q["✅ S3 Key:\nraw/stapply/snapshots/\nsnapshot_date=YYYY-MM-DD/\nall.parquet"]
    P --> Q

    Q --> R["Task exits 0\nFargate container terminates\nNo state left behind"]
```

---

## `Dockerfile` Flow

```mermaid
flowchart LR
    A["FROM python:3.12-slim\nminimal base image"] --> B["apt-get install tzdata\nIST timezone support"]
    B --> C["pip install\nboto3 · requests · pyarrow\nno cache"]
    C --> D["COPY app.py ."]
    D --> E["CMD python app.py\nEntry point"]
    E --> F["Built → ECR push\n→ ECS Task Definition\nimage URI"]
```

---

## Key Design Decisions

| Decision | Why |
|----------|-----|
| `stream=True` with 8 MiB chunks | Avoids OOM on large ATS feeds |
| 64 MiB multipart threshold | S3 best practice for large uploads |
| Hive partition `snapshot_date=YYYY-MM-DD` | Auto Loader picks up only new dates |
| `python:3.12-slim` base | Minimal CVE surface; tzdata only extra dep |
| 0 NAT Gateways | VPC endpoint + public subnet saves ~$32/month |
| Stateless design | No DB, no queue — full S3 state → easy re-runs |
