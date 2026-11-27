"""
Stapply ATS Scraper — AWS ECS Fargate Microservice
====================================================
Streams ATS job data (Greenhouse, Lever, Ashby, Workday, etc.)
and writes daily Parquet snapshots to S3.

Architecture:
  EventBridge (09:00 IST daily) → ECS Fargate Task → S3 (Parquet)

Design decisions:
  - Stateless: no DB, no queue. Pure S3 state.
  - Chunk-streamed (8 MiB) → 64 MiB S3 multipart upload
  - Partition: s3://<BUCKET>/raw/stapply/snapshots/snapshot_date=YYYY-MM-DD/all.parquet
  - boto3 S3 client, no SDK abstraction layer

Environment variables required:
  S3_BUCKET        — target bucket name  (injected via ECS Task Definition)
  AWS_DEFAULT_REGION — set to eu-north-1 by default in task definition

Author : Rishikesh Yadav
Version: Gen3 (Oct 2026)
"""

import os
import io
import json
import logging
import datetime
import boto3
import requests
import pyarrow as pa
import pyarrow.parquet as pq

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

# ── Config (from environment) ────────────────────────────────────────────────
S3_BUCKET   = os.environ["S3_BUCKET"]          # injected by ECS task definition
S3_PREFIX   = "raw/stapply/snapshots"
CHUNK_BYTES = 8 * 1024 * 1024                  # 8 MiB streaming chunk
MPU_THRESH  = 64 * 1024 * 1024                 # 64 MiB multipart threshold

# ── ATS Sources ──────────────────────────────────────────────────────────────
ATS_SOURCES = {
    "greenhouse": "https://boards-api.greenhouse.io/v1/boards/{company}/jobs?content=true",
    "lever":      "https://api.lever.co/v0/postings/{company}?mode=json",
    "ashby":      "https://jobs.ashbyhq.com/api/non-user-facing/posting-board/job-board",
    # Add more ATS endpoints here following the same pattern
}

def fetch_ats_jobs(ats_type: str, company: str) -> list[dict]:
    """Fetch jobs from a single ATS endpoint. Returns list of raw job dicts."""
    url = ATS_SOURCES[ats_type].format(company=company)
    log.info("Fetching %s/%s ...", ats_type, company)

    jobs = []
    with requests.get(url, stream=True, timeout=30) as resp:
        resp.raise_for_status()
        buffer = b""
        for chunk in resp.iter_content(chunk_size=CHUNK_BYTES):
            buffer += chunk

        raw = json.loads(buffer)
        # Normalize per ATS schema
        if ats_type == "greenhouse":
            jobs = raw.get("jobs", [])
        elif ats_type == "lever":
            jobs = raw if isinstance(raw, list) else []
        elif ats_type == "ashby":
            jobs = raw.get("jobPostings", [])

    log.info("  → %d jobs from %s/%s", len(jobs), ats_type, company)
    return jobs


def normalize_job(raw: dict, ats_type: str, company: str, snapshot_date: str) -> dict:
    """Flatten raw ATS job dict to canonical schema."""
    return {
        "snapshot_date":    snapshot_date,
        "ats_type":         ats_type,
        "company":          company,
        "url":              raw.get("absolute_url") or raw.get("hostedUrl") or "",
        "title":            raw.get("title", ""),
        "location":         (raw.get("location") or {}).get("name", ""),
        "posted_at":        raw.get("updated_at") or raw.get("createdAt") or "",
        "is_remote":        str(raw.get("remote", False)),
        "employment_type":  raw.get("employment_type", ""),
        "department":       ((raw.get("departments") or [{}])[0]).get("name", ""),
        "description":      raw.get("content") or raw.get("descriptionHtml") or "",
        # Additional fields: salary, country_iso, etc. — extend as needed
    }


def jobs_to_parquet_bytes(jobs: list[dict]) -> bytes:
    """Serialize list of job dicts to Parquet bytes via PyArrow."""
    table = pa.Table.from_pylist(jobs)
    buf = io.BytesIO()
    pq.write_table(table, buf, compression="snappy")
    return buf.getvalue()


def upload_to_s3(data: bytes, bucket: str, key: str) -> None:
    """Upload bytes to S3, using multipart for large payloads."""
    s3 = boto3.client("s3")
    if len(data) >= MPU_THRESH:
        log.info("Uploading %d MiB via multipart → s3://%s/%s", len(data) // (1024**2), bucket, key)
        mpu = s3.create_multipart_upload(Bucket=bucket, Key=key)
        parts = []
        part_num = 1
        for i in range(0, len(data), MPU_THRESH):
            chunk = data[i : i + MPU_THRESH]
            resp = s3.upload_part(Body=chunk, Bucket=bucket, Key=key,
                                  PartNumber=part_num, UploadId=mpu["UploadId"])
            parts.append({"PartNumber": part_num, "ETag": resp["ETag"]})
            part_num += 1
        s3.complete_multipart_upload(Bucket=bucket, Key=key, UploadId=mpu["UploadId"],
                                     MultipartUpload={"Parts": parts})
    else:
        s3.put_object(Bucket=bucket, Key=key, Body=data)
    log.info("Upload complete → s3://%s/%s", bucket, key)


def main() -> None:
    today = datetime.date.today().isoformat()          # YYYY-MM-DD
    s3_key = f"{S3_PREFIX}/snapshot_date={today}/all.parquet"

    # --- Collect all jobs ---
    all_jobs: list[dict] = []
    # TODO: replace with your company list fetched from config/discovery
    companies = {
        "greenhouse": ["acme-corp", "example-startup"],
        "lever":      ["widget-co"],
    }
    for ats_type, company_list in companies.items():
        for company in company_list:
            try:
                raw_jobs = fetch_ats_jobs(ats_type, company)
                normalized = [normalize_job(j, ats_type, company, today) for j in raw_jobs]
                all_jobs.extend(normalized)
            except Exception as exc:
                log.warning("Skipping %s/%s: %s", ats_type, company, exc)

    log.info("Total jobs collected: %d", len(all_jobs))

    if not all_jobs:
        log.warning("No jobs collected — skipping upload")
        return

    parquet_bytes = jobs_to_parquet_bytes(all_jobs)
    upload_to_s3(parquet_bytes, S3_BUCKET, s3_key)
    log.info("Done. snapshot_date=%s, jobs=%d, size=%d KB",
             today, len(all_jobs), len(parquet_bytes) // 1024)


if __name__ == "__main__":
    main()
