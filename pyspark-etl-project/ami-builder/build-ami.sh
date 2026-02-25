#!/bin/bash
set -e
export AWS_PAGER="" 

# --- CONFIGURATION ---
VPC_ID="vpc-0b6151bb9b43b3c35"
SUBNET_ID="subnet-0cb1611a792ee89d9"
REGION="us-east-1"

# --- CLEANUP ---
cleanup() {
    echo ">>> [CLEANUP] Removing temporary public route..."
    RT_ID=$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$SUBNET_ID" --query 'RouteTables[0].RouteTableId' --output text --region $REGION)
    aws ec2 delete-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --region $REGION 2>/dev/null || true
}
trap cleanup EXIT

echo ">>> Step 1: Locating Infrastructure..."
RT_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[0].RouteTableId' --output text --region $REGION)
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text --region $REGION)

echo ">>> Step 2: Ensuring Public Route via IGW..."
aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" --region $REGION 2>/dev/null || echo "Route exists."

echo ">>> Step 3: Deleting ALL VPC Endpoints (Cleaning DNS)..."
# We delete these because they are blocking the instance from seeing the real internet
ALL_EPS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --query "VpcEndpoints[].VpcEndpointId" --output text --region $REGION)
if [ -n "$ALL_EPS" ] && [ "$ALL_EPS" != "None" ]; then
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $ALL_EPS --region $REGION
    echo "Waiting 60s for DNS stabilization..."
    sleep 60
fi

echo ">>> Step 4: Running Packer Build (Connecting via Public IP)..."
packer init .
packer build python-pyspark-ami.pkr.hcl