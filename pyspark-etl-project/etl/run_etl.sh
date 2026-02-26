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

echo "Starting ETL job at $(date)..."
echo "Logs: $LOG_FILE"

# -----------------------------
# Install Python dependencies
# -----------------------------
echo "Installing Python dependencies..."
sudo apt update -y && sudo apt install -y python3-pip wget openjdk-11-jdk
pip3 install --upgrade pip

if [ -f "$REQUIREMENTS_FILE" ]; then
    pip3 install --upgrade -r "$REQUIREMENTS_FILE"
else
    echo "⚠️ requirements.txt not found. Skipping dependency installation."
fi

# -----------------------------
# Download compatible Hadoop & AWS JARs
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
export PYSPARK_SUBMIT_ARGS="--jars $SPARK_JARS_DIR/hadoop-aws-3.3.6.jar,$SPARK_JARS_DIR/hadoop-common-3.3.6.jar,$SPARK_JARS_DIR/aws-java-sdk-bundle-1.12.544.jar pyspark-shell"

# -----------------------------
# Run Python ETL
# -----------------------------
echo "Running ETL script..."
python3 "$ETL_SCRIPT" > >(tee -a "$LOG_FILE") 2>&1

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ ETL completed successfully"
else
    echo "❌ ETL failed. Check logs: $LOG_FILE"
    exit $EXIT_CODE
fi