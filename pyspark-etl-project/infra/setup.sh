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