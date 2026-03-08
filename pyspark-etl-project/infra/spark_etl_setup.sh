#!/bin/bash
set -e

LOG_FILE="/var/log/spark_etl_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Terraform-ready Spark + Python setup..."
echo "Logging to $LOG_FILE"

# -------------------------
# 1️⃣ Install system dependencies
# -------------------------
yum update -y
yum install -y python3 python3-pip java-11-amazon-corretto wget tar

# -------------------------
# 2️⃣ Upgrade pip safely (ignore RPM warning)
# -------------------------
python3 -m pip install --upgrade pip wheel || echo "⚠️ Pip upgrade warning ignored"

# -------------------------
# 3️⃣ Install required Python packages
# -------------------------
python3 -m pip install --upgrade pyspark PyYAML boto3 botocore mysql-connector-python || echo "⚠️ Package install warning ignored"

# -------------------------
# 4️⃣ Install Apache Spark system-wide
# -------------------------
cd /opt
if [ ! -d /opt/spark ]; then
    wget https://downloads.apache.org/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz
    tar -xzf spark-3.5.1-bin-hadoop3.tgz
    mv spark-3.5.1-bin-hadoop3 spark
fi

# -------------------------
# 5️⃣ Set environment variables globally
# -------------------------
cat <<EOF > /etc/profile.d/spark.sh
export SPARK_HOME=/opt/spark
export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin:~/.local/bin
export PYTHONPATH=\$PYTHONPATH:$(python3 -m site --user-site)
EOF

# Load for current shell
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin:~/.local/bin
export PYTHONPATH=$PYTHONPATH:$(python3 -m site --user-site)

# -------------------------
# 6️⃣ Verification
# -------------------------
echo "Verifying Python packages..."
python3 - <<PYTHON
try:
    import pyspark, yaml, boto3, botocore, mysql.connector
    print("✅ Python packages OK:", 
          "PySpark", pyspark.__version__,
          "PyYAML", yaml.__version__,
          "boto3", boto3.__version__,
          "botocore", botocore.__version__)
except Exception as e:
    print("❌ Python package verification failed:", e)
PYTHON

echo "Verifying Java..."
java -version >/dev/null 2>&1 && echo "✅ Java OK" || echo "❌ Java missing"

echo "Verifying Spark binaries..."
command -v pyspark >/dev/null && command -v spark-submit >/dev/null && echo "✅ pyspark & spark-submit OK" || echo "❌ Spark binaries missing"

echo "Checking Spark folder..."
[ -d /opt/spark ] && echo "✅ Spark directory OK at /opt/spark" || echo "❌ Spark directory missing"

echo "Terraform-ready Spark + Python setup completed!"