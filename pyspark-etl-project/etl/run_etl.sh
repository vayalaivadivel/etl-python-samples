#!/bin/bash
set -e

# -----------------------------
# Paths
# -----------------------------
PROJECT_DIR=~/pyspark-etl-project/etl
ETL_SCRIPT="$PROJECT_DIR/src/load_s3_to_rds.py"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"

# -----------------------------
# Timestamped log
# -----------------------------
TIMESTAMP=$(date +%F_%H%M%S)
LOG_FILE="$LOG_DIR/etl_$TIMESTAMP.log"

echo "Starting ETL job at $(date)..."
echo "Logs: $LOG_FILE"

# -----------------------------
# Run Python ETL
# -----------------------------
python3 "$ETL_SCRIPT" > "$LOG_FILE" 2>&1

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ ETL completed successfully"
else
    echo "❌ ETL failed. Check logs: $LOG_FILE"
    exit $EXIT_CODE
fi