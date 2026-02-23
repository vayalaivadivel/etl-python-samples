#!/bin/bash

# Navigate to ETL folder
cd ~/pyspark-etl-project/etl || exit 1

# Create logs folder if missing
mkdir -p logs

# Ensure MySQL JDBC jar exists (download if missing)
JAR_PATH="jars/mysql-connector-j-9.4.0.jar"
mkdir -p jars
if [ ! -f "$JAR_PATH" ]; then
    echo "Downloading MySQL 9.4.0 JDBC driver..."
    wget -O "$JAR_PATH" https://repo1.maven.org/maven2/mysql/mysql-connector-j/9.4.0/mysql-connector-j-9.4.0.jar
fi

# Run PySpark ETL
TIMESTAMP=$(date +%F_%H%M%S)
LOG_FILE="logs/etl_${TIMESTAMP}.log"

echo "Starting ETL at $(date)..."
spark-submit \
    --jars "$JAR_PATH" \
    src/load_s3_to_rds.py \
    > "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "ETL completed successfully. Logs: $LOG_FILE"
else
    echo "ETL failed. Check logs: $LOG_FILE"
    exit 1
fi