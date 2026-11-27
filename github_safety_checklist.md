# GitHub-Publication Safety Checklist

**Target Folder:** `portfolio_site/`  
**Rule:** Do not publish or push anything outside `portfolio_site/` (`Portfolio/AWS_setup.txt`, `ops/recent_runs.json`, and raw archives must remain private).

---

## Pre-Publication Checklist

- [x] **No Secrets or Credentials:** Zero Databricks PATs (`dapi...`), AWS access keys (`AKIA...`/`ASIA...`), or private keys exist in `portfolio_site/`.
- [x] **No AWS Account IDs / ARNs / Infrastructure IDs:** Excluded `Portfolio/AWS_setup.txt` and opaque-redacted the 12-digit AWS Account IDs in `assets/images/ECR.png` and `assets/images/IAM.png`.
- [x] **No S3 Bucket Names or Concrete Storage URIs:** Anonymized S3 paths in all Markdown/HTML text (`s3://<S3_BUCKET>/raw/stapply/snapshots/`) and opaque-redacted S3 URIs in `CloudWatch logs.png`, `Fargate source code.png`, `SDP Pipeline.png`, and `SDP pipeline (1).png`.
- [x] **No Emails or Workspace Hostnames/IDs:** Stripped corporate/personal emails and Databricks workspace URLs/IDs from all `portfolio_site/` text; opaque-redacted email fragments in `Job DAG.png` and numeric Run IDs in `Run_log.png` and `SDP pipeline (2).png`.
- [x] **Duplicate Screenshot Excluded:** `Dash (2).png` omitted from `portfolio_site/assets/images/` (`Bronze table.png` retained).
- [x] **Original Workspace Untouched:** Zero files in `Portfolio/`, `Archive/`, `Stapply-Export-Dev/`, or root `.zip`/`.dbc` archives were modified.
- [ ] **User Final Review:** Review `portfolio_site/index.html` and sanitized images locally before creating any public GitHub repository.
