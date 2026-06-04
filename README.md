# DEVOPS TRAINEE

Collection of cheesheets

Future sctructure:
```
.
├── OS-and-Foundation/
│   ├── linux-cheatsheet.md
│   ├── scripts/               # Ваши bash-скрипты автоматизации
│   └── Vagrant/               # Vagrantfile для быстрого поднятия тестовых ВМ
├── IaC-and-Ansible/
│   ├── ansible/               # Рабочие playbooks и roles
│   └── terraform/             # .tf файлы для поднятия тестовой инфраструктуры
├── Containers-and-K8s/
│   ├── docker-apps/           # Папки с Dockerfile для ваших мини-аппок
│   └── k8s-manifests/         # Голые манифесты и ваши Helm-чарты
├── CI-CD-GitOps/
│   ├── .gitlab-ci.yml         # Примеры пайплайнов
│   └── argocd-apps/           # Манифесты приложений для ArgoCD
├── Python-and-MLOps/
│   ├── app/                   # Ваше FastAPI мини-приложение (с boto3)
│   ├── Dockerfile.ml          # Dockerfile с CUDA
│   └── scripts/               # Скрипты автоматизации на Python
└── README.md                  # Ваш корневой план (тот, что вы написали выше)
```

## Base focus
- [Foundation & OS](OS-and-Foundation/linux-cheatsheet.md#foundation-os):
    - Linux: [Ubuntu](OS-and-Foundation/linux-cheatsheet.md#ubuntu); [RHEL / AlmaLinux](OS-and-Foundation/linux-cheatsheet.md#rhel) (vs old CentOS)
    - bash ([grep](OS-and-Foundation/linux-cheatsheet.md#grep), [sed](OS-and-Foundation/linux-cheatsheet.md#sed), [awk](OS-and-Foundation/linux-cheatsheet.md#awk))
    - [virtualization](OS-and-Foundation/linux-cheatsheet.md#virtualization) (kvm, qemu) + vagrant
    - [system management](OS-and-Foundation/linux-cheatsheet.md#system-management) (systemd, cron, sudo, journald, logrotate)
        - [Process and resource management](OS-and-Foundation/linux-cheatsheet.md#processes-resources)
        - [Disk subsystem and LVM](OS-and-Foundation/linux-cheatsheet.md#storage-lvm)

- Networking & Web Servers:
    - Protocols: OSI model (L1-L7), TCP/IP, UDP, DNS (A, CNAME, MX, TXT records), DHCP
    - Routing & Security: NAT, Bridge, SSH, TLS/SSL handshake, VPN (WireGuard/OpenVPN)
    - Web: HTTP/HTTPS (response codes, headers)
    - Web Servers: Nginx (Reverse Proxy, Balancer), Apache
    - basic network troubleshooting: ping, curl, traceroute, tcpdump, netstat/ss, nslookup, dig (for interview)

    - LAMP/LNMP-stack (outdated with containers)

- Version Control, CI/CD, GitOps
    - Git: Git Flow, Branching, Merge, Rebase, cherry-pick, conflict resolution
    - CI/CD Platforms: GitLab CI / Jenkins - Jenkins Shared Libraries & Declarative Pipline
    - GitOps: ArgoCD (Pull-model concept) automate sync k8s manifest git repo and cluster
    - Deployment Strategies: Rolling update, Blue-Green, Canary



- Infrasructure as Code & Configuration (IaC)
    - Configuration: Ansible (Playbooks, Roles, Ansible Galaxy).
    - Infrastructure Provisioning: Terraform / OpenTofu

- Containerization & Orchestration
    - Docker: Engine, Dockerfile (layer optimization, multi-stage), Compose, Volumes
    - Kubernetes:
        - Architecture (Control Plane,  worker nodes)
        - HELM
        - basic primitives: Pod, Deployment, Service (ClusterIP, NodePort, LoadBalancer), ConfigMap, Secret
        - Ingress: Nginx ingress Controller
        - Persistent Volumes & Custom CRD

- Monitoring & Observability
    - Monitoring: Prometheus & Grafana (Metric Records, dashboards, alertmanager)
    - Logging: LogStash (priority) / Vector / Fluentbit + OpenSearch / Loki (Loki in priority with k8s, than ELK-stack)
    - SRE basics: SLA, SLO, SLI, Root Cause Analysis

- Databases
    - MySQL (& MariaDB), PostgreSQL (base requests, backups, replication - master-slave)
    - NoSQL, MongoDB
    - Redis (cache)
    - Message Brokers: RabbitMQ -> Kafka (Data Pipeline)
    - Identity: Keycloak (SSO-concept, OAuth2 / OIDC protocols)


- Python & MLOps Spec (Specific)
    - Python: Basic syntaxis, API-requests, automatization (os, sys, boto3 libs)
    - MLOps Core: FastAPI (base endpoints for models)
    - Docker for ML: packing python-apps, CUDA, GPU in Container 
    - vLLM, distribution GPU in k8s 
