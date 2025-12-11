#!/bin/bash

set -e

# DEFAULTS
TASK=5
if [[ "$MODE" != "INSTANCE" ]]; then
    MODE="KVM" 
fi

configureInstance () {
    checkPackages "nginx" "htop" "ttyd" "python3.12-venv"
    setupNginx
    setupLogDaemon
    setupLogAnalyzer

    echo OK
}

function checkPackages () {
    echo "Checking packages"

    local packages=("$@")
    local missing_packages=()

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        echo "Updating apt packages"
        sudo apt update &>/dev/null 
        for package in "${missing_packages[@]}"; do
            echo "Installing $package"
            sudo apt install -y "$package" &>/dev/null
        done
    fi

    echo "All packages installed"
}

function setupNginx() {
    echo "Setting up nginx"
    
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo rm -f /etc/nginx/conf.d/default.conf

    sudo tee /etc/nginx/conf.d/monitor.conf > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name localhost;

    location /htop/ {
        proxy_pass http://localhost:7681/;
        proxy_http_version 1.1;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # proxy_set_header Host \$host;
        # proxy_set_header X-Real-IP \$remote_addr;
        # proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # proxy_read_timeout 86400;
    }
}
EOF
    if ! sudo netstat -tulnp | grep -q 7681; then
        nohup ttyd -p 7681 htop > /dev/null 2>&1 &
        sleep 2
    fi

    sudo nginx -t
    sudo systemctl restart nginx
}

function setupLogDaemon() {
    echo "Setting up daemon"

    sudo mv ~/log_daemon.sh /usr/local/bin/log-daemon.sh
    sudo mv ~/log_daemon.service /etc/systemd/system/log-daemon.service

    sudo systemctl daemon-reload
    sudo systemctl enable log-daemon.service
    sudo systemctl restart log-daemon.service

    echo "Daemon set up"
}

function setupLogAnalyzer() {
    ! python3 --version >/dev/null &&  echo "Python3 not installed" && exit 1

    python3 -m venv venv
    source venv/bin/activate

    pip install -r requirements.txt >/dev/null

    python3 ~/llm-analyzer.py --logfile /tmp/nginx_logger_daemon/file1.log --promptfile ~/promt_file.txt --temperature 0.2
}

function awsInstance () {
    echo "Running in AWS mode"
    source ./scripts/aws-instance.sh


    if [[ "$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --output text)" == "" ]]; then
        runInstance
        echo "$INSTANCE_IP" | tee /tmp/task${TASK}_instance_ip.var 
    else 
        [[ ! -f /tmp/task${TASK}_instance_ip.var ]] && \
            echo "Error with parsing instance ip from tmp" && exit 1
        INSTANCE_IP=$(cat /tmp/task${TASK}_instance_ip.var)
    fi

    KEY_PAIR_NAME="$KEY_PAIR_NAME.pem"
    connectToInstance
}

function kvmInstance () {
    echo "Running in KVM mode"
    # sudo source ./scripts/kvm-instance.sh

    VM_NAME="Ubuntu-Noble"

    if ! virsh list --name --all | grep "$VM_NAME"; then 
        sudo ./scripts/kvm-instance.sh --full --dist ubuntu
    elif ! virsh list --name | grep "$VM_NAME"; then
        echo "VM exists, but shutoff, starting" 
        virsh start "$VM_NAME" &>/dev/null
        while [[ "$INSTANCE_IP" == "" ]]; do
            echo "Wating VM to get IP"
            INSTANCE_IP=$(virsh domifaddr $VM_NAME | awk '/ipv4/ { split($4, a, "/"); print a[1] }')
            sleep 5
        done
    fi
    
    INSTANCE_IP=$(virsh domifaddr $VM_NAME | awk '/ipv4/ { split($4, a, "/"); print a[1] }')  
    KEY_PAIR_NAME="rsa.key"
    connectToInstance
}

function connectToInstance() {
    echo "Waiting instance to be accessible"
    for i in {1..36}; do
        if ! nc -z "$INSTANCE_IP" 22; then
            [[ $i -eq 36 ]] && \
                echo "Instance does not become accessible in time" && \
                exit 1
            echo "Instance is still starting $(($i*5-5))/180"
            sleep 5
        else 
            echo "Instance accessible on host $INSTANCE_IP" && break
        fi
    done

   
    if [ -d ./src ]; then
        echo "Coping with scp"
        scp -r -i ./keys/$KEY_PAIR_NAME \
            -o StrictHostKeyChecking=accept-new \
            ./{init.sh,src/*} \
            ubuntu@$INSTANCE_IP:~/
    fi
    
    ENV_VAR="$(cat ./src/.env)"

    echo "Connecting to instance"
    ssh -t -i ./keys/$KEY_PAIR_NAME \
        -o StrictHostKeyChecking=accept-new \
        ubuntu@$INSTANCE_IP \
        "MODE=\"INSTANCE\" $ENV_VAR sudo -E ./init.sh" 
}


while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            if [[ -z "$2" ]]; then
                echo "Error: --mode requires a mode selection"
                echo "Supported modes: KVM & AWS"
                echo "KVM mode require sudo"
                exit 1
            fi
            MODE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

case "$MODE" in
    "AWS")
        awsInstance
        ;;
    "KVM")
        kvmInstance
        ;;
    "INSTANCE")
        # ! configureInstance && echo "configureInstance function not found" && exit
        configureInstance
        ;;
esac

