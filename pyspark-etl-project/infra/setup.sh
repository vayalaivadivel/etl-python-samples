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
apt install -y python3-pip wget curl openjdk-17-jdk git unzip tar

# -----------------------------
# 2️⃣ Install Spark (robust)
# -----------------------------
if [ ! -d "$SPARK_HOME" ]; then
    echo "Installing Apache Spark..."
    SPARK_TGZ="/tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"

    # Download with retries
    wget --tries=5 --timeout=30 -O $SPARK_TGZ https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

    # Extract and move
    sudo tar -xzf $SPARK_TGZ -C /opt
    sudo mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} $SPARK_HOME

    # Fix permissions
    sudo chown -R ubuntu:ubuntu $SPARK_HOME
    sudo chmod -R 755 $SPARK_HOME
fi

# -----------------------------
# 3️⃣ Persist environment variables in .bashrc
# -----------------------------
BASHRC="/home/ubuntu/.bashrc"
grep -qxF 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' $BASHRC || echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> $BASHRC
grep -qxF "export SPARK_HOME=$SPARK_HOME" $BASHRC || echo "export SPARK_HOME=$SPARK_HOME" >> $BASHRC
grep -qxF 'export PATH=$JAVA_HOME/bin:$SPARK_HOME/bin:$PATH' $BASHRC || echo 'export PATH=$JAVA_HOME/bin:$SPARK_HOME/bin:$PATH' >> $BASHRC

# -----------------------------
# 4️⃣ Export environment for current session
# -----------------------------
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export SPARK_HOME=$SPARK_HOME
export PATH=$JAVA_HOME/bin:$SPARK_HOME/bin:$PATH

# -----------------------------
# 5️⃣ Create ETL & logs folders
# -----------------------------
mkdir -p $ETL_DIR
mkdir -p $LOG_DIR
chown -R ubuntu:ubuntu $ETL_DIR $LOG_DIR

# -----------------------------
# 6️⃣ Install Python packages for ETL
# -----------------------------
pip3 install --upgrade pip
pip3 install pyspark boto3 pandas

echo "✅ EC2 bootstrap complete: Java, Spark, Python packages installed, logs folder ready, environment variables set."