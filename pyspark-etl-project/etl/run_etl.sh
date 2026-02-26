#!/bin/bash
set -e

# -----------------------------
# Paths
# -----------------------------
PROJECT_DIR=~/pyspark-etl-project/etl
ETL_SCRIPT="$PROJECT_DIR/src/load_s3_to_rds.py"
LOG_DIR="$PROJECT_DIR/logs"
REQUIREMENTS_FILE="$PROJECT_DIR/requirements.txt"
JARS_DIR="$PROJECT_DIR/jars"

mkdir -p "$LOG_DIR" "$JARS_DIR"

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
sudo apt install -y python3-pip openjdk-11-jdk wget
pip3 install --upgrade pip

if [ -f "$REQUIREMENTS_FILE" ]; then
    pip3 install --upgrade -r "$REQUIREMENTS_FILE"
else
    echo "⚠️ requirements.txt not found. Skipping dependency installation."
fi

# -----------------------------
# Download Spark/Hadoop AWS JARs if not exist
# -----------------------------
HADOOP_AWS_JAR="$JARS_DIR/hadoop-aws-3.3.6.jar"
AWS_SDK_JAR="$JARS_DIR/aws-java-sdk-bundle-1.12.500.jar"

if [ ! -f "$HADOOP_AWS_JAR" ]; then
    wget -O "$HADOOP_AWS_JAR" "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar"
fi

if [ ! -f "$AWS_SDK_JAR" ]; then
    wget -O "$AWS_SDK_JAR" "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.500/aws-java-sdk-bundle-1.12.500.jar"
fi

# -----------------------------
# Run Python ETL with Spark
# -----------------------------
echo "Running ETL script with Spark..."
spark-submit \
  --jars "$HADOOP_AWS_JAR,$AWS_SDK_JAR" \
  "$ETL_SCRIPT" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ ETL completed successfully"
else
    echo "❌ ETL failed. Check logs: $LOG_FILE"
    exit $EXIT_CODE
fi