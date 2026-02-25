#!/bin/bash

set -e

echo "Initializing Packer..."
packer init python-pyspark-ami.pkr.hcl

echo "Validating template..."
packer validate python-pyspark-ami.pkr.hcl

echo "Building AMI..."
packer build python-pyspark-ami.pkr.hcl

echo "AMI build completed."