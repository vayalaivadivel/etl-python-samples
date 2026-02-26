#!/bin/bash
set -e

# ---------------------------
# Update system packages
# ---------------------------
sudo yum update -y

# ---------------------------
# Install Java 17 (Amazon Corretto)
# ---------------------------
sudo amazon-linux-extras enable corretto17 -y
sudo yum install -y java-17-amazon-corretto-devel

# ---------------------------
# Install Python 3 and pip
# ---------------------------
sudo yum install -y python3 python3-devel
sudo alternatives --install /usr/bin/python python /usr/bin/python3 1
sudo alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
pip install --upgrade pip

# ---------------------------
# Install PySpark Python library
# ---------------------------
pip install pyspark

# ---------------------------
# Install MySQL client / Python connector
# ---------------------------
sudo yum install -y mysql
pip install PyMySQL==1.1.1

# ---------------------------
# Install Apache Spark CLI (spark-submit)
# ---------------------------
SPARK_VERSION="3.5.1"
HADOOP_VERSION="3"
SPARK_DIR="/opt/spark"

# Download Spark binary with Hadoop support
sudo mkdir -p $SPARK_DIR
sudo curl -L https://downloads.apache.org/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz \
    | sudo tar -xz -C $SPARK_DIR --strip-components=1

# Add Spark to PATH
echo "export SPARK_HOME=$SPARK_DIR" >> ~/.bashrc
echo "export PATH=\$SPARK_HOME/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc

# Verify installations
echo "✅ Python version: $(python --version)"
echo "✅ Java version: $(java -version)"
echo "✅ PySpark version: $(python -c 'import pyspark; print(pyspark.__version__)')"
echo "✅ Spark-submit version: $(spark-submit --version)"
echo "✅ MySQL client version: $(mysql --version)"

echo "✅ EC2 setup completed successfully."