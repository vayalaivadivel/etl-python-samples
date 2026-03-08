# PySpark ETL Project Architecture

## Overview of the Architecture


       ┌─────────────────────┐
       │    GitHub Repo      │
       │  (PySpark code,     │
       │  config.yaml,       │
       │  requirements.txt)  │
       └─────────┬──────────┘
                 │
      (CI/CD pipeline triggers)
                 │
                 ▼
     ┌───────────────────────────┐
     │   GitHub Actions Runner   │
     │  - Checks out repo        │
     │  - Installs dependencies  │
     │  - Submits EMR Serverless │
     │    job via AWS CLI        │
     └─────────┬─────────────────┘
               │
               ▼
  ┌──────────────────────────────┐
  │    AWS EMR Serverless        │
  │ - Executes PySpark job       │
  │ - Accesses:                  │
  │    * S3 bucket for CSV file  │
  │    * RDS MySQL               │
  │ - Uses IAM Role (emr_s3_rds) │
  └─────────┬────────────────────┘
            │
    ┌───────┴────────┐
    │                │




---

## Component Details

### A. GitHub Repo

Contains:

- `src/load_s3_to_rds.py` → PySpark ETL script.
- `conf/config.yaml` → Configuration (S3 bucket, RDS credentials, etc.).
- `requirements.txt` → Python packages needed.
- `run_etl.sh` → Shell script to execute the job (optional for local testing).

**CI/CD:**

- GitHub Actions workflow triggers on manual dispatch or push.
- Workflow checks out repo, installs dependencies (if needed), and submits EMR Serverless job.

---

### B. CI/CD (GitHub Actions)

**Workflow Steps:**

1. Checkout repository.
2. Install Python dependencies (optional, mostly for local validation).
3. Submit job to EMR Serverless using `aws emr-serverless start-job-run`.
4. Pass configuration file path (`config.yaml`) and `requirements.txt` as job parameters.
5. Job executes on EMR Serverless and writes results to RDS.

**Secrets in GitHub Actions:**

- `AWS_ACCESS_KEY_ID` & `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `EMR_APP_ID` → Output of Terraform EMR Serverless application
- `EMR_EXEC_ROLE_ARN` → IAM Role for EMR Serverless
- `TEMP_S3_BUCKET` → Optional temporary S3 bucket for staging

---

### C. AWS Infrastructure (Terraform)

#### 1. Networking

- VPC with two public subnets.
- Internet Gateway + Route Table for public access.
- Security groups for:
  - RDS (allow port 3306 from your IP)
  - EMR Serverless (allows access to RDS/S3)

#### 2. RDS MySQL

- Multi-AZ disabled (dev/test)
- Publicly accessible
- Security group allows your IP for testing
- Terraform outputs RDS endpoint

#### 3. EMR Serverless

- Spark application (EMR 7.3.0, supports Spark 3.5.1)
- Subnets + Security group attached
- IAM Role with limited access:
  - Fixed S3 bucket: `vadivel-data-engineer/my-company-list/*`
  - RDS connection: `rds-db:connect`

#### 4. S3 Bucket

- Stores:
  - Input CSV
  - Optional temp job files (EMR staging)
- EMR can read only the specific bucket/folder

#### 5. IAM Roles

- EMR Serverless execution role:
  - Attached policy allows S3 read (specific folder) and RDS access.
- Optionally, EC2 or other resources have their own IAM roles if needed.

---

### D. Data Flow

1. **CSV Upload**
   - Place your CSV file in S3:  
     `s3://vadivel-data-engineer/my-company-list/companies.csv`

2. **Trigger CI/CD**
   - GitHub Actions manually triggered or on push.
   - Workflow starts EMR Serverless job with your PySpark script and config.

3. **EMR Serverless Execution**
   - Spark reads CSV from S3.
   - Casts columns and performs transformations.
   - Writes results to RDS MySQL.

4. **Optional Temporary Bucket**
   - EMR Serverless can stage temporary files.
   - Bucket can be automatically deleted after the job.
