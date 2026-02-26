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

echo "Starting ETL job at $(date)..."
echo "Logs: $LOG_FILE"

# -----------------------------
# Install Python dependencies
# -----------------------------
echo "Installing Python dependencies..."
sudo apt update -y
sudo apt install -y python3-pip openjdk-11-jdk
pip3 install --upgrade pip

if [ -f "$REQUIREMENTS_FILE" ]; then
    pip3 install --upgrade -r "$REQUIREMENTS_FILE"
else
    echo "⚠️ requirements.txt not found. Skipping dependency installation."
fi

# -----------------------------
# Run ETL using spark-submit (CORRECT WAY)
# -----------------------------
echo "Running ETL script with Spark..."

spark-submit \
  --packages org.apache.hadoop:hadoop-aws:3.3.4,com.amazonaws:aws-java-sdk-bundle:1.12.262 \
  "$ETL_SCRIPT" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ ETL completed successfully"
else
    echo "❌ ETL failed. Check logs: $LOG_FILE"
    exit $EXIT_CODE
fi