#!/bin/bash

set -e

! [[ $MODE == "INSTANCE" ]] && MODE="KVM" # DEFAULT MODE

function configureInstance() {
    installPackages "nginx" "docker.io" 
    containerServers
    [ ! -f /etc/apt/sources.list.d/nginx.list &>/dev/null ] && nginxModuleDancing
    [ ! -f /etc/nginx/conf.d/dkt.conf &>/dev/null ] && sudopreInstallNginx
    ! snap list | grep certbot &>/dev/null && getCertification
    upNginx

    echo "OK"
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
        echo "Updating apt packages"
        sudo apt update &>/dev/null 
        for package in "${missing_packages[@]}"; do
            echo "Installing $package"
            sudo apt install -y "$package" &>/dev/null
        done
    fi

    echo "All packages installed"
}

function nginxModuleDancing() {
    echo "Dancing with nginx modules"

    sudo apt update
    sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
        | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" \
        | sudo tee /etc/apt/sources.list.d/nginx.list
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
        | sudo tee /etc/apt/preferences.d/99nginx
    sudo apt update
    sudo apt install -y nginx-module-image-filter

    echo "Nginx module installed"
}

function containerServers() {
    echo "Starting container servers"
    ! docker -v &>/dev/null && echo "Docker error" && exit 1

    ! sudo docker ps | grep red &>/dev/null && sudo docker run -d -p 8001:80 tsuyakashi/task4-red-server
    ! sudo docker ps | grep blue &>/dev/null && sudo docker run -d -p 8002:80 tsuyakashi/task4-blue-server
    ! sudo docker ps | grep pacman &>/dev/null && sudo docker run -d -p 8003:8000 tsuyakashi/mycool:pacman
    ! sudo docker ps | grep php &>/dev/null && sudo docker run -d -p 8008:80 tsuyakashi/task4-php-server

    echo "Containers started"
}

function preInstallNginx() {
    echo "Prepering nginx"
    ! dpkg -s nginx &>/dev/null && echo "Nginx package error" && exit 1

    sudo rm -f /etc/nginx/sites-enabled/default
    sudo rm -f /etc/nginx/conf.d/default.conf

    ! sudo grep "load_module modules/ngx_http_image_filter_module.so;" /etc/nginx/nginx.conf &&
        sudo sed -i '1i load_module modules/ngx_http_image_filter_module.so;' /etc/nginx/nginx.conf
    sudo tee /etc/nginx/conf.d/dkt.conf > /dev/null <<EOF
server {
    listen       80;
    listen       [::]:80;
    server_name  trainee.servebeer.com;
    return 301 https://$host$request_uri;
}
EOF
    sudo systemctl restart nginx

    echo "Nginx prepared"
}

function getCertification() {
    echo "Trying get certification"

    sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot
    sudo certbot certonly --nginx

    echo "Certification complete"
}

function upNginx() {
    echo "Setting up nginx"

    sudo tee /etc/nginx/conf.d/dkt.conf > /dev/null <<EOF
upstream php_server {
    server localhost:8008;
}

upstream secondserver {
    server localhost:8003;
}

upstream redblue_servers {
    server localhost:8001;
    server localhost:8002;
}

server {
    listen       80;
    listen       [::]:80;
    server_name  trainee.servebeer.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    http2 on;

    ssl_certificate /etc/letsencrypt/live/trainee.servebeer.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/trainee.servebeer.com/privkey.pem;

    root /opt/dkt/;
    index index.html;

    location /secondpage {
        root /opt/dkt/secondpage/;
        try_files /secondpage.html =404;
    }

    location /music {
        root /opt/dkt/;
        try_files /KSBmuzic-Otchim.mp3 =404;
    }

    location /info.php {
        proxy_pass http://php_server/info.php;
    }

    location /secondserver/ {
        proxy_pass http://secondserver/;
    }
    
    location = /secondserver {
        return 301 /secondserver/;
    }

    location /image1 {
        root /opt/dkt/;
        try_files /image1.jpg =404;
        image_filter off;
    }

    location /image2 {
        root /opt/dkt/;
        try_files /image2.png =404;
        image_filter rotate 180;
    }

    location /redblue {
        proxy_pass http://redblue_servers/;
        
        # Логирование для отслеживания балансировки
        access_log /var/log/nginx/redblue_access.log;
    }
}
EOF

    mkdir -p /opt/dkt/secondpage/
    mv ~/KSBmuzic-Otchim.mp3 /opt/dkt/
    mv ~/index.html /opt/dkt/index.html
    mv ~/secondpage.html /opt/dkt/secondpage/secondpage.html
    mv ~/*.jpg /opt/dkt/image1.jpg
    mv ~/*.png /opt/dkt/image2.png
    rm ~/red.html ~/blue.html

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

    if ! virsh list --all --name | grep -q "$VM_NAME"; then 
        echo "(!! sudo required !!)"
        sudo ./scripts/kvm-install.sh --full --dist ubuntu
    elif ! virsh list --name | grep -q "$VM_NAME"; then 
        echo "VM exists, but shutoff, starting" 
        virsh start "$VM_NAME" &>/dev/null
        INSTANCE_IP=$(virsh domifaddr $VM_NAME | awk '/ipv4/ { split($4, a, "/"); print a[1] }')  
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
    fi

    INSTANCE_IP=$(virsh domifaddr $VM_NAME | awk '/ipv4/ { split($4, a, "/"); print a[1] }')
    
    scp -i ./keys/rsa.key \
        -o StrictHostKeyChecking=accept-new \
        ./{init.sh,src/*} \
        ubuntu@$INSTANCE_IP:~/

    ssh -t -i ./keys/rsa.key \
        -o StrictHostKeyChecking=accept-new \
        ubuntu@$INSTANCE_IP \
        "MODE=\"INSTANCE\" sudo -E ./init.sh" 

fi

if [[ "$MODE" == "AWS" ]]; then
    echo "Running in AWS mode"
    source ./scripts/run-instance.sh


    if [[ "$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --output text)" == "" ]]; then
        runInstance
        echo "$INSTANCE_IP" | tee /tmp/task4_instance_ip.var 
    else 
        [[ ! -f /tmp/task4_instance_ip.var ]] && \
            echo "Error with parsing instance ip from tmp" && exit 1
        INSTANCE_IP=$(cat /tmp/task4_instance_ip.var)
    fi
    

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


    

    scp -i ./keys/$KEY_PAIR_NAME.pem \
        -o StrictHostKeyChecking=accept-new \
        ./{init.sh,src/*} \
        ubuntu@$INSTANCE_IP:~/
    
    ssh -t -i ./keys/$KEY_PAIR_NAME.pem \
        -o StrictHostKeyChecking=accept-new \
        ubuntu@$INSTANCE_IP \
        "MODE=\"INSTANCE\" sudo -E ./init.sh" 

    
fi

if [[ "$MODE" == "INSTANCE" ]]; then
    configureInstance
fi