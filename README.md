ETL File installation verification steps

cat /var/log/spark_etl_setup.log

(
python3 - <<PYTHON
try:
    import pyspark, yaml, boto3, botocore, mysql.connector
    print("✅ Python packages OK:", 
          "PySpark", pyspark.__version__,
          "PyYAML", yaml.__version__,
          "boto3", boto3.__version__,
          "botocore", botocore.__version__,
          "MySQL Connector", mysql.connector.__version__)
except Exception as e:
    print("❌ Python packages missing or failed:", e)
PYTHON

java -version >/dev/null 2>&1 && echo "✅ Java OK" || echo "❌ Java missing"
command -v pyspark >/dev/null 2>&1 && command -v spark-submit >/dev/null 2>&1 && echo "✅ pyspark & spark-submit OK" || echo "❌ Spark binaries missing"
[ -d /opt/spark ] && echo "✅ Spark directory OK at /opt/spark" || echo "❌ Spark directory missing"
)
