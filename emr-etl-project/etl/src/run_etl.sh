#!/usr/bin/env bash
set -e

echo "Starting PySpark ETL job on EMR Serverless..."

# The working directory inside EMR Serverless
WORK_DIR=$(pwd)
echo "Working directory: $WORK_DIR"

# Run the PySpark job
python3 load_s3_to_rds.py --config config.yaml