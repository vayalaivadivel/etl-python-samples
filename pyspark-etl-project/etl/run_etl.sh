#!/bin/bash
set -e

# -----------------------------
# Config
# -----------------------------
SPARK_HOME="/opt/spark"
LOG_DIR="/home/ubuntu/pyspark-etl-project/etl/logs"
ETL_JAR="/home/ubuntu/pyspark-etl-project/etl/spark-job.jar"
MAIN_CLASS="your.main.Class"   # Replace with your ETL main class

# -----------------------------
# 1️⃣ Ensure environment variables are set
# -----------------------------
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export SPARK_HOME=$SPARK_HOME
export PATH=$JAVA_HOME/bin:$SPARK_HOME/bin:$PATH

# -----------------------------
# 2️⃣ Create logs folder if missing
# -----------------------------
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/etl_$(date +%F_%H%M%S).log"

# -----------------------------
# 3️⃣ Submit Spark ETL job
# -----------------------------
echo "Submitting Spark job..."
spark-submit \
    --class $MAIN_CLASS \
    --master local[*] \
    $ETL_JAR \
    >> $LOG_FILE 2>&1

echo "✅ ETL completed successfully!"
echo "Logs: $LOG_FILE"