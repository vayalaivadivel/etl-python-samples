#!/bin/bash
set -euo pipefail

echo "===== STARTING PYSPARK ETL ====="

PROJECT_DIR="$HOME/pyspark-etl-project/etl"
cd "$PROJECT_DIR" || {
  echo "Project directory not found!"
  exit 1
}

# Create logs + jars folders
mkdir -p logs jars

# MySQL JDBC jar
JAR_PATH="jars/mysql-connector-j-9.4.0.jar"

if [ ! -f "$JAR_PATH" ]; then
    echo "Downloading MySQL 9.4.0 JDBC driver..."
    wget -q -O "$JAR_PATH" \
      https://repo1.maven.org/maven2/mysql/mysql-connector-j/9.4.0/mysql-connector-j-9.4.0.jar
    echo "Download complete."
fi

# Timestamp log
TIMESTAMP=$(date +%F_%H%M%S)
LOG_FILE="logs/etl_${TIMESTAMP}.log"

echo "Running spark-submit..."
spark-submit \
    --jars "$JAR_PATH" \
    src/load_s3_to_rds.py \
    > "$LOG_FILE" 2>&1

echo "===== ETL FINISHED SUCCESSFULLY ====="
echo "Log file: $PROJECT_DIR/$LOG_FILE"