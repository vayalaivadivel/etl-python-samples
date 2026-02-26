#!/bin/bash
# -------------------------------------
# EC2 User-Data Setup Script for PySpark ETL
# -------------------------------------
exec > >(tee /tmp/setup.log) 2>&1
set -x

echo "$(date '+%Y-%m-%d %H:%M:%S') | EC2 user-data setup started"

# ---------------------------
# Update system packages
# ---------------------------
yum clean all
yum update -y

# ---------------------------
# Install Python 3
# ---------------------------
if ! python3 --version &>/dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Installing Python 3..."
    yum install -y python3 python3-devel
    alternatives --install /usr/bin/python python /usr/bin/python3 1
    alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
fi

# Upgrade pip
echo "$(date '+%Y-%m-%d %H:%M:%S') | Upgrading pip..."
pip install --upgrade pip

# ---------------------------
# Install Java 17
# ---------------------------
if ! java -version &>/dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Installing Java 17 (Amazon Corretto)..."
    amazon-linux-extras enable corretto17 -y || true
    yum install -y java-17-amazon-corretto-devel
fi

# ---------------------------
# Install PySpark
# ---------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Installing PySpark..."
pip install pyspark

# ---------------------------
# Install MySQL client + PyMySQL
# ---------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Installing MySQL client and PyMySQL..."
yum install -y mysql
pip install PyMySQL==1.1.1

# ---------------------------
# Install Apache Spark CLI
# ---------------------------
SPARK_VERSION="3.5.1"
HADOOP_VERSION="3"
SPARK_DIR="/opt/spark"

if [ ! -d "$SPARK_DIR" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Installing Apache Spark CLI..."
    mkdir -p $SPARK_DIR
    curl -L https://downloads.apache.org/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz \
        | tar -xz -C $SPARK_DIR --strip-components=1
fi

# ---------------------------
# Set system-wide environment variables
# ---------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Setting system-wide environment variables..."
cat <<EOF > /etc/profile.d/spark.sh
export SPARK_HOME=$SPARK_DIR
export PATH=\$SPARK_HOME/bin:/usr/local/bin:/usr/bin:\$PATH
EOF
chmod +x /etc/profile.d/spark.sh

# ---------------------------
# Verify installations
# ---------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Verifying installations..."
echo "Python: $(python --version 2>&1)"
echo "Java: $(java -version 2>&1 | head -n 1)"
echo "PySpark: $(python -c 'import pyspark; print(pyspark.__version__)' 2>&1)"
echo "Spark-submit: $(spark-submit --version 2>&1 | head -n 1)"
echo "MySQL client: $(mysql --version 2>&1)"

echo "$(date '+%Y-%m-%d %H:%M:%S') | EC2 setup completed successfully"
echo "Full log available at /tmp/setup.log"

# ---------------------------
# Reboot to apply environment changes
# ---------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') | Rebooting system to apply environment changes..."
reboot