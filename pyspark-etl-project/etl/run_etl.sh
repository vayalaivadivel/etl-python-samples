#!/bin/bash
set -e

# -----------------------------
# Paths
# -----------------------------
PROJECT_DIR=~/pyspark-etl-project/etl
ETL_SCRIPT="$PROJECT_DIR/src/load_s3_to_rds.py"
LOG_DIR="$PROJECT_DIR/logs"
REQUIREMENTS_FILE="$PROJECT_DIR/requirements.txt"

mkdir -p "$LOG_DIR"

# -----------------------------
# Timestamped log
# -----------------------------
TIMESTAMP=$(date +%F_%H%M%S)
LOG_FILE="$LOG_DIR/etl_$TIMESTAMP.log"

echo "==========================================="
echo "Starting ETL job at $(date)"
echo "Log file: $LOG_FILE"
echo "==========================================="

# -----------------------------
# Install system dependencies (only if missing)
# -----------------------------
echo "Checking system dependencies..."

sudo apt update -y
sudo apt install -y python3-pip openjdk-11-jdk

pip3 install --upgrade pip

if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "Installing Python dependencies..."
    pip3 install --upgrade -r "$REQUIREMENTS_FILE"
else
    echo "⚠️ requirements.txt not found. Skipping."
fi

# -----------------------------
# Spark dependency packages (SAFE WAY)
# -----------------------------
export PYSPARK_SUBMIT_ARGS="--packages \
org.apache.hadoop:hadoop-aws:3.3.6,\
com.amazonaws:aws-java-sdk-bundle:1.12.544 \
pyspark-shell"

# -----------------------------
# Run ETL via spark-submit
# -----------------------------
echo "Submitting Spark job..."

spark-submit \
  --master local[*] \
  --conf spark.driver.memory=2g \
  --conf spark.executor.memory=2g \
  "$ETL_SCRIPT" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    echo "==========================================="
    echo "✅ ETL completed successfully"
    echo "==========================================="
else
    echo "==========================================="
    echo "❌ ETL failed. Check logs: $LOG_FILE"
    echo "==========================================="
    exit $EXIT_CODE
fi