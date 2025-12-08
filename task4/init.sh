#!/bin/bash

set -e

! [[ $MODE == "INSTANCE" ]] && MODE="KVM" # DEFAULT MODE

function configureInstance() {
    installPackages "nginx" "docker.io"
    redblueServers
    upNginx
}

function installPackages() {
    echo "Checking packages"

    local packages=("$@")
    local missing_packages=()

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        sudo apt update &>/dev/null 
        for package in "${missing_packages[@]}"; do
            sudo apt install -y "$package" &>/dev/null
        done
    fi

    echo "All packages installed"
}

function redblueServers() {
    echo "Starting redblue servers"
    ! docker -v &>/dev/null && echo "Docker error" && exit 1

    ! sudo docker ps | grep red &>/dev/null && sudo docker run -d -p 8001:80 tsuyakashi/task4-red-server
    ! sudo docker ps | grep blue &>/dev/null && sudo docker run -d -p 8002:80 tsuyakashi/task4-blue-server

    echo "Containers started"
}

function upNginx() {
    echo "Standing up nginx"
    ! dpkg -s nginx &>/dev/null && echo "Nginx package error" && exit 1

    sudo rm -f /etc/nginx/sites-enabled/default

    sudo tee /etc/nginx/conf.d/dkt.conf > /dev/null <<EOF
upstream redblue_servers {
    server localhost:8001;
    server localhost:8002;
}

server {
    listen       80;
    listen       [::]:80;
    server_name  ${HOSTNAME};
    root /opt/dkt/;
    index index.html;

    location /redblue {
        proxy_pass http://redblue_servers/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Логирование для отслеживания балансировки
        access_log /var/log/nginx/redblue_access.log;
    }
} 
EOF

    mkdir -p /opt/dkt
    mv ~/index.html /opt/dkt/index.html

    sudo nginx -t
    sudo systemctl restart nginx
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            if [[ -z "$2" ]]; then
                echo "Error: --mode requires a mode selection"
                echo "Supported: KVM (sudo required) & AWS"
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


if [[ "$MODE" == "KVM" ]]; then
    echo "Running in KVM mode"

    VM_NAME="Ubuntu-Noble"

    ! virsh list --all --name | grep -q "$VM_NAME" && echo "(!! sudo required !!)" && sudo ./kvm-install.sh --full --dist ubuntu
    VM_IP=$(virsh domifaddr $VM_NAME | awk '/ipv4/ { split($4, a, "/"); print a[1] }')
    
    scp -i ./keys/rsa.key \
        -o StrictHostKeyChecking=accept-new \
        ./{init.sh,src/index.html} \
        ubuntu@$VM_IP:~/

    ssh -t -i ./keys/rsa.key \
        -o StrictHostKeyChecking=accept-new \
        ubuntu@$VM_IP \
        "MODE="INSTANCE" sudo -E ./init.sh" 

fi

if [[ "$MODE" == "AWS" ]]; then
    echo "NOT supported yet"
    exit 1
fi

if [[ "$MODE" == "INSTANCE" ]]; then
    configureInstance
fi