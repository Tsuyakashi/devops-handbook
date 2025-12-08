#!/bin/bash

set -e

# Default config
AMI_ID="ami-004e960cde33f9146" # ubuntu 24.04
EC_COUNT=1
INSTANCE_TYPE="t2.micro"
KEY_PAIR_NAME="some-key-pair"
SECURITY_GROUP_NAME="CLI-security-group"

ROOT_PASSWORD="root123"

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

function userConfigure() {
! id user1 && sudo useradd -m -p $(openssl passwd -6 $ROOT_PASSWORD) user1
! id user2 && sudo useradd -m -p $(openssl passwd -6 $ROOT_PASSWORD) user2
! id user3 && sudo useradd -m -p $(openssl passwd -6 $ROOT_PASSWORD) user3
! id user4 && sudo useradd -m -p $(openssl passwd -6 $ROOT_PASSWORD) user4
! id user5 && sudo useradd -m -p $(openssl passwd -6 $ROOT_PASSWORD) user5

sudo mkdir -p /home/user1/.ssh
sudo cp /home/ubuntu/.ssh/authorized_keys /home/user1/.ssh/authorized_keys
sudo chown -R user1:user1 /home/user1/.ssh
sudo chmod 700 /home/user1/.ssh
sudo chmod 600 /home/user1/.ssh/authorized_keys

sudo tee /etc/ssh/sshd_config.d/60-cloudimg-settings.conf &>/dev/null <<EOF
PasswordAuthentication yes
PubkeyAuthentication yes
# user1 — только по ключу
Match User user1
    PasswordAuthentication no
    PubkeyAuthentication yes

# user2 — только по паролю
Match User user2
    PasswordAuthentication yes
    PubkeyAuthentication no
EOF

sudo systemctl restart ssh

sudo usermod -aG sudo user1
sudo tee -a /etc/sudoers.d/90-cloud-init-users &>/dev/null <<EOF
# User rules for user1
user1 ALL=(ALL:ALL) ALL
EOF

sudo touch /opt/myfile.txt

! setfacl --help &>/dev/null && sudo apt update && sudo apt install -y acl

sudo setfacl -m u:user1:rw- /opt/myfile.txt
sudo setfacl -m u:user2:r-- /opt/myfile.txt
sudo setfacl -m u:user3:-w- /opt/myfile.txt
sudo setfacl -m u:user4:r-x /opt/myfile.txt
sudo setfacl -m u:user5:--- /opt/myfile.txt

if [[ $(grep "^user3" /etc/passwd) == "user3:x:1003:1003::/home/user3:/bin/sh" ]]; then
    sudo chsh -s /bin/bash user3
else 
    sudo chsh -s /bin/sh user3
fi
}

AWS_FLAG=false
USER_CONFIGURE_FLAG=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --count)
            if [[ -z "$2" ]]; then
                echo "Error: --count requires num"
                exit 1
            fi
            EC_COUNT=$2
            shift 2
            ;;
        --aws)
            AWS_FLAG=true
            shift
            ;;
        --no-auto-user-configure)
            USER_CONFIGURE_FLAG=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done


if [[ "$AWS_FLAG" == "true" ]]; then
    ! aws --version &>/dev/null && echo "AWS CLI is not installed, full install not supported" && exit 1
    # ! -f ~/.aws/credentials && echo "AWS config do not exist" && exit 1

    for ((i=1; i<=EC_COUNT; i++)) do
        echo "Starting instance #$i"
        runInstance
        echo $INSTANCE_IP

        while ! nc -z $INSTANCE_IP 22; do
                sleep 5
                echo "Instance did not accesible yet"
        done

        if [[ "$USER_CONFIGURE_FLAG" == true ]]
            scp -i ./keys/$KEY_PAIR_NAME.pem \
                -o StrictHostKeyChecking=accept-new \
                ./init.sh \
                ubuntu@$INSTANCE_IP:~/

            ssh -t -i ./keys/$KEY_PAIR_NAME.pem \
                -o StrictHostKeyChecking=accept-new \
                ubuntu@$INSTANCE_IP \
                "sudo ./init.sh" 
    done
else 
    userConfigure
fi