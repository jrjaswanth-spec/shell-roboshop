#!/bin/bash
set -e

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0bf7b888c01816e0d"
INSTANCE_TYPE="t3.micro"

ZONE_ID="Z0240123A9FCWL2SEDEO"
DOMAIN_NAME="jrdaws.life"

for instance in "$@"
do
  echo "======================================"
  echo "Creating EC2 instance for: $instance"
  echo "======================================"

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

  if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
    echo "ERROR: Failed to create EC2 instance for $instance"
    exit 1
  fi

  echo "Instance ID: $INSTANCE_ID"
  echo "Waiting for $instance instance to be running..."
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

  if [ "$instance" != "frontend" ]; then
    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PrivateIpAddress' \
      --output text)
    RECORD_NAME="$instance.$DOMAIN_NAME"
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)
    RECORD_NAME="$DOMAIN_NAME"
  fi

  if [ -z "$IP" ] || [ "$IP" == "None" ]; then
    echo "ERROR: IP not ready for $instance"
    exit 1
  fi

  echo "$instance IP: $IP"
  echo "Creating Route53 record: $RECORD_NAME -> $IP"

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Comment\": \"Automated DNS for $instance\",
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$RECORD_NAME\",
          \"Type\": \"A\",
          \"TTL\": 60,
          \"ResourceRecords\": [{ \"Value\": \"$IP\" }]
        }
      }]
    }"

  echo "DNS record created/updated for $RECORD_NAME"
done

echo "======================================"
echo "All components completed successfully"
echo "======================================"
