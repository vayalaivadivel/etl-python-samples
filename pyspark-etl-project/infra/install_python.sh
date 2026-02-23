#!/bin/bash
# Update OS and install Python3, pip, Java, git
sudo apt update -y
sudo apt install -y python3 python3-pip default-jdk git

# Install Python packages for PySpark + MySQL + AWS
pip3 install pyspark mysql-connector-python boto3 pandas