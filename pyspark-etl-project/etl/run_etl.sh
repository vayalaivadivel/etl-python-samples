#!/bin/bash
set -e

# -----------------------------
# Config
# -----------------------------
SPARK_VERSION="3.5.1"
HADOOP_VERSION="3"
SPARK_HOME="/opt/spark"
LOG_DIR="/home/ubuntu/pyspark-etl-project/etl/logs"
ETL_JAR="/home/ubuntu/pyspark-etl-project/etl/spark-job.jar"
MAIN_CLASS="your.main.Class"   # Replace with your ETL main class

# -----------------------------
# 1️⃣ Install Java 17 if missing
# -----------------------------
if ! java -version 2>&1 | grep '17'; then
    echo "Installing OpenJDK 17..."
    sudo apt update -y
    sudo apt install -y openjdk-17-jdk wget
fi

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# -----------------------------
# 2️⃣ Install Spark if missing
# -----------------------------
if [ ! -d "$SPARK_HOME" ]; then
    echo "Installing Apache Spark..."
    wget -q https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -P /tmp
    sudo tar -xzf /tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /opt
    sudo mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} $SPARK_HOME
fi

export SPARK_HOME=$SPARK_HOME
export PATH=$SPARK_HOME/bin:$PATH

# -----------------------------
# 3️⃣ Create logs folder
# -----------------------------
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/etl_$(date +%F_%H%M%S).log"

# -----------------------------
# 4️⃣ Submit Spark ETL job
# -----------------------------
echo "Submitting Spark job..."
spark-submit \
    --class $MAIN_CLASS \
    --master local[*] \
    $ETL_JAR \
    >> $LOG_FILE 2>&1

echo "✅ ETL completed successfully!"
echo "Logs: $LOG_FILE"