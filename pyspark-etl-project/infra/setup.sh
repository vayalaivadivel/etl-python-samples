#!/bin/bash
set -e

# -----------------------------
# Config
# -----------------------------
SPARK_VERSION="3.5.1"
HADOOP_VERSION="3"
SPARK_HOME="/opt/spark"
LOG_DIR="/home/ubuntu/pyspark-etl-project/etl/logs"
ETL_DIR="/home/ubuntu/pyspark-etl-project/etl"

# -----------------------------
# 1️⃣ Update system & install dependencies
# -----------------------------
apt update -y
apt install -y python3-pip wget curl openjdk-17-jdk git unzip

# Set JAVA_HOME for this session
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# -----------------------------
# 2️⃣ Install Spark
# -----------------------------
if [ ! -d "$SPARK_HOME" ]; then
    echo "Installing Apache Spark..."
    SPARK_TGZ="/tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"
    wget -q https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -O $SPARK_TGZ
    tar -xzf $SPARK_TGZ -C /opt
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} $SPARK_HOME
fi

export SPARK_HOME=$SPARK_HOME
export PATH=$SPARK_HOME/bin:$PATH

# -----------------------------
# 3️⃣ Persist environment variables in .bashrc
# -----------------------------
echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /home/ubuntu/.bashrc
echo "export SPARK_HOME=$SPARK_HOME" >> /home/ubuntu/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$SPARK_HOME/bin:\$PATH" >> /home/ubuntu/.bashrc

# -----------------------------
# 4️⃣ Create ETL & logs folder
# -----------------------------
mkdir -p $ETL_DIR
mkdir -p $LOG_DIR

# -----------------------------
# 5️⃣ Install Python packages for ETL
# -----------------------------
pip3 install --upgrade pip
pip3 install pyspark boto3 pandas  # add any other ETL dependencies you need

echo "✅ EC2 bootstrap complete: Java, Spark, Python, pip packages, logs folder ready, environment variables set."