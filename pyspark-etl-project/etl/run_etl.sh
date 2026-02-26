#!/bin/bash
set -e

# -----------------------------
# Paths
# -----------------------------
PROJECT_DIR=~/pyspark-etl-project/etl
ETL_SCRIPT="$PROJECT_DIR/src/load_s3_to_rds.py"
LOG_DIR="$PROJECT_DIR/logs"
REQUIREMENTS_FILE="$PROJECT_DIR/requirements.txt"
SPARK_JARS_DIR="$PROJECT_DIR/spark-jars"

mkdir -p "$LOG_DIR" "$SPARK_JARS_DIR"

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
# Install system dependencies
# -----------------------------
echo "Installing system dependencies..."
sudo apt update -y
sudo apt install -y python3-pip openjdk-11-jdk wget

pip3 install --upgrade pip

if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "Installing Python dependencies..."
    pip3 install --upgrade -r "$REQUIREMENTS_FILE"
else
    echo "⚠️ requirements.txt not found. Skipping."
fi

# -----------------------------
# Download Hadoop & AWS JARs for s3a
# -----------------------------
echo "Downloading Hadoop and AWS JARs..."
JARS=(
  "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar"
  "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/3.3.6/hadoop-common-3.3.6.jar"
  "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.544/aws-java-sdk-bundle-1.12.544.jar"
)

for jar in "${JARS[@]}"; do
    wget -nc -P "$SPARK_JARS_DIR" "$jar"
done

# -----------------------------
# Set Spark submit args with Hadoop & AWS JARs
# -----------------------------
export PYSPARK_SUBMIT_ARGS="--jars \
$SPARK_JARS_DIR/hadoop-aws-3.3.6.jar,\
$SPARK_JARS_DIR/hadoop-common-3.3.6.jar,\
$SPARK_JARS_DIR/aws-java-sdk-bundle-1.12.544.jar \
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