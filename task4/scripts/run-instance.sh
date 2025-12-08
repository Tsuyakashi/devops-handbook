#!/bin/bash

function runInstance() {
    DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
        --filters Name=isDefault,Values=true \
        --query "Vpcs[0].VpcId" \
        --output text)
    [[ $DEFAULT_VPC_ID == "None" ]] && echo "Error returning default VPC id" && exit 1

    if ! aws ec2 create-security-group \
            --group-name $SECURITY_GROUP_NAME \
            --description "SG created from CLI" \
            --vpc-id $DEFAULT_VPC_ID &>/dev/null; then
        echo "Security group already exist"
        SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
            --filters Name=vpc-id,Values=$DEFAULT_VPC_ID Name=group-name,Values=$SECURITY_GROUP_NAME \
            --query "SecurityGroups[0].GroupId" \
            --output text)
    else
        echo "Security group does not exist, creating" # :D

        SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
            --filters Name=vpc-id,Values=$DEFAULT_VPC_ID Name=group-name,Values=$SECURITY_GROUP_NAME \
            --query "SecurityGroups[0].GroupId" \
            --output text)

        aws ec2 authorize-security-group-ingress \
            --group-id $SECURITY_GROUP_ID \
            --protocol tcp \
            --port 22 \
            --cidr 0.0.0.0/0

        aws ec2 authorize-security-group-ingress \
            --group-id $SECURITY_GROUP_ID \
            --protocol tcp \
            --port 80 \
            --cidr 0.0.0.0/0
    fi
    [[ $SECURITY_GROUP_ID == "None" ]] && echo "Error returning sg id" && exit 1

    SUBNET_ID=$(aws ec2 describe-subnets \
    --filters Name=vpc-id,Values=$DEFAULT_VPC_ID Name=default-for-az,Values=true \
    --query "Subnets[0].SubnetId" --output text) 
    [[ $SUBNET_ID == "None" ]] && echo "Error returning subnet id" && exit 1

    if [[ $(aws ec2 describe-key-pairs \
        --filters Name=key-name,Values=$KEY_PAIR_NAME \
        --query 'KeyPairs[].KeyName' \
        --output text) == $KEY_PAIR_NAME ]]; then

        echo "Key pair already exist"
    else
        echo "Key pair does not exist, creating..."
        mkdir -p keys
        aws ec2 create-key-pair \
            --key-name $KEY_PAIR_NAME \
            --query 'KeyMaterial' \
            --output text > ./keys/$KEY_PAIR_NAME.pem
        chmod 600 ./keys/$KEY_PAIR_NAME.pem 
    fi
    
    # Add multiply start with inbuild counter 
    echo "Running instance"
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --count 1 \
        --instance-type $INSTANCE_TYPE \
        --key-name $KEY_PAIR_NAME \
        --security-group-ids $SECURITY_GROUP_ID \
        --subnet-id $SUBNET_ID \
        --associate-public-ip-address \
        --query 'Instances[0].InstanceId' \
        --output text )
    [[ $INSTANCE_ID == "None" ]] && echo "Error returning instance id" && exit 1

    echo "Waiting instance run"
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    INSTANCE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)
}
