# ============================================================
# STAPPLY ENTERPRISE SDP PIPELINE — CENTRAL CONFIGURATION
# ============================================================
# Edit ONLY this file. Then run 01_deploy notebook.
# Everything else (pipeline, dashboard, tables) is auto-created.
#
# SECURITY NOTE: Do NOT hard-code credentials here.
#   S3_BUCKET    — set to your own bucket name
#   ALERT_EMAILS — set to your own notification email(s)
# ============================================================

# ── S3 Source ────────────────────────────────────────────────────────────────
# Where Fargate drops daily parquet snapshots.
# Format: s3://<bucket>/path/to/snapshots/
# Each day creates: snapshot_date=YYYY-MM-DD/all.parquet
S3_BUCKET = "<YOUR_S3_BUCKET>"                          # ← replace before deploy
S3_PATH   = f"s3://{S3_BUCKET}/raw/stapply/snapshots/"

# ── Unity Catalog ─────────────────────────────────────────────────────────────
# Pipeline will create all 9 tables in this catalog.schema.
CATALOG = "workspace"
SCHEMA  = "default"

# ── Pipeline Settings ─────────────────────────────────────────────────────────
PIPELINE_NAME      = "Stapply Enterprise SDP Pipeline"
SERVERLESS         = True       # True = no cluster config needed
PHOTON             = True       # Vectorized execution engine
DEVELOPMENT_MODE   = False      # Set False for production (enables retries + CDC)
CHANNEL            = "CURRENT"  # Runtime channel

# ── Notifications ─────────────────────────────────────────────────────────────
# Email addresses to notify on pipeline failures.
ALERT_EMAILS = ["<YOUR_EMAIL>"]                         # ← replace before deploy

# ── Dashboard ─────────────────────────────────────────────────────────────────
DASHBOARD_NAME = "Top ATS Platform Job Market"

# ── Deployment Path ───────────────────────────────────────────────────────────
# Where the deployment notebook creates the pipeline source.
DEPLOY_BASE_PATH = "/Shared/stapply-deployment"

# ============================================================
# DO NOT EDIT BELOW — Derived values
# ============================================================
SQL_TEMPLATES_PATH  = f"{DEPLOY_BASE_PATH}/transformations"
DASHBOARD_JSON_PATH = f"{DEPLOY_BASE_PATH}/dashboard/dashboard_config.json"
