#!/bin/bash
set -e

# ---------------------------
# Log file
# ---------------------------
LOG_FILE="/tmp/setup.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') | EC2 setup started" > $LOG_FILE

# Helper function to log with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> $LOG_FILE 2>&1
}

# ---------------------------
# Update system
# ---------------------------
log "Updating system packages..."
sudo yum clean all >> $LOG_FILE 2>&1
sudo yum update -y >> $LOG_FILE 2>&1

# ---------------------------
# Install Python 3
# ---------------------------
if ! python3 --version &>/dev/null; then
    log "Installing Python 3..."
    sudo yum install -y python3 python3-devel >> $LOG_FILE 2>&1
    sudo alternatives --install /usr/bin/python python /usr/bin/python3 1 >> $LOG_FILE 2>&1
    sudo alternatives --install /usr/bin/pip pip /usr/bin/pip3 1 >> $LOG_FILE 2>&1
fi

# Upgrade pip
log "Upgrading pip..."
pip install --upgrade pip >> $LOG_FILE 2>&1

# ---------------------------
# Install Java 17
# ---------------------------
if ! java -version &>/dev/null; then
    log "Installing Java 17 (Amazon Corretto)..."
    sudo amazon-linux-extras enable corretto17 -y >> $LOG_FILE 2>&1 || true
    sudo yum install -y java-17-amazon-corretto-devel >> $LOG_FILE 2>&1
fi

# ---------------------------
# Install PySpark library
# ---------------------------
log "Installing PySpark..."
pip install pyspark >> $LOG_FILE 2>&1

# ---------------------------
# Install MySQL client + Python connector
# ---------------------------
log "Installing MySQL client and PyMySQL..."
sudo yum install -y mysql >> $LOG_FILE 2>&1
pip install PyMySQL==1.1.1 >> $LOG_FILE 2>&1

# ---------------------------
# Install Spark CLI (spark-submit)
# ---------------------------
SPARK_VERSION="3.5.1"
HADOOP_VERSION="3"
SPARK_DIR="/opt/spark"

if [ ! -d "$SPARK_DIR" ]; then
    log "Installing Apache Spark CLI..."
    sudo mkdir -p $SPARK_DIR >> $LOG_FILE 2>&1
    sudo curl -L https://downloads.apache.org/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz \
        | sudo tar -xz -C $SPARK_DIR --strip-components=1 >> $LOG_FILE 2>&1
fi

# Add Spark to PATH
if ! grep -q "SPARK_HOME" ~/.bashrc; then
    log "Adding Spark to PATH..."
    echo "export SPARK_HOME=$SPARK_DIR" >> ~/.bashrc
    echo "export PATH=\$SPARK_HOME/bin:\$PATH" >> ~/.bashrc
fi
source ~/.bashrc

# ---------------------------
# Verify installations
# ---------------------------
log "Verifying installations..."
log "✅ Python version: $(python --version 2>&1)"
log "✅ Java version: $(java -version 2>&1 | head -n 1)"
log "✅ PySpark version: $(python -c 'import pyspark; print(pyspark.__version__)' 2>&1)"
log "✅ Spark-submit version: $(spark-submit --version 2>&1 | head -n 1)"
log "✅ MySQL client version: $(mysql --version 2>&1)"

log "✅ EC2 setup completed successfully"
log "Full installation log available at $LOG_FILE"

log "Rebooting system to apply environment changes..."
sudo reboot