# DEVOPS TRAINEE

Collection of cheesheets

## OS-and-Networks

Шпаргалка: **[linux-cheatsheet.md](OS-and-Networks/linux-cheatsheet.md)**

| Раздел | Ссылка |
|--------|--------|
| Foundation & OS | [foundation-os](OS-and-Networks/linux-cheatsheet.md#foundation-os) |
| Bash scripting | [bash-scripting](OS-and-Networks/linux-cheatsheet.md#bash-scripting) |
| grep | [grep](OS-and-Networks/linux-cheatsheet.md#grep) |
| sed | [sed](OS-and-Networks/linux-cheatsheet.md#sed) |
| awk | [awk](OS-and-Networks/linux-cheatsheet.md#awk) |
| Ubuntu | [ubuntu](OS-and-Networks/linux-cheatsheet.md#ubuntu) |
| Desktop | [desktop](OS-and-Networks/linux-cheatsheet.md#desktop) |
| Server vs Desktop | [server-vs-desktop](OS-and-Networks/linux-cheatsheet.md#server-vs-desktop) |
| WSL | [wsl](OS-and-Networks/linux-cheatsheet.md#wsl) |
| Server | [server](OS-and-Networks/linux-cheatsheet.md#server) |
| Cloud | [cloud](OS-and-Networks/linux-cheatsheet.md#cloud) |
| Ubuntu Core | [ubuntu-core](OS-and-Networks/linux-cheatsheet.md#ubuntu-core) |
| Flavors | [ubuntu-flavors](OS-and-Networks/linux-cheatsheet.md#ubuntu-flavors) |
| apt и Snap | [apt-snap](OS-and-Networks/linux-cheatsheet.md#apt-snap) |

Future sctructure:
```
.
├── OS-and-Networks/
│   ├── linux-cheatsheet.md
│   ├── scripts/               # Ваши bash-скрипты автоматизации
│   └── vagrant-kvm-lab/       # Vagrantfile для быстрого поднятия тестовых ВМ
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
- Foundation & OS ([шпаргалка](OS-and-Networks/linux-cheatsheet.md#foundation-os)):
    - Linux: Ubuntu ([обзор](OS-and-Networks/linux-cheatsheet.md#ubuntu) — [Desktop](OS-and-Networks/linux-cheatsheet.md#desktop), [Server](OS-and-Networks/linux-cheatsheet.md#server), [Cloud](OS-and-Networks/linux-cheatsheet.md#cloud), [WSL](OS-and-Networks/linux-cheatsheet.md#wsl), [Core](OS-and-Networks/linux-cheatsheet.md#ubuntu-core), [apt/Snap](OS-and-Networks/linux-cheatsheet.md#apt-snap)); RHEL/AlmaLinux (vs old CentOS)
    - bash ([обзор](OS-and-Networks/linux-cheatsheet.md#bash-scripting), [grep](OS-and-Networks/linux-cheatsheet.md#grep), [sed](OS-and-Networks/linux-cheatsheet.md#sed), [awk](OS-and-Networks/linux-cheatsheet.md#awk))
    - virtulization (kvm, qemu) + vagrant
    - system management: systemd - services, cron, sudo/chmod/chown, systemd-journald, logrotate

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


