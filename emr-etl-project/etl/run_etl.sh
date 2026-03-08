#!/bin/bash
set -e

# Activate virtual environment if you have one
# source venv/bin/activate

# Install Python dependencies
pip install -r etl/requirements.txt

# Run PySpark ETL
python etl/src/load_s3_to_rds.py