# DEVOPS TRAINEE

Collection of cheatsheets

- **[Foundation & OS](OS-and-Foundation/README.md#foundation-os)**:
    - **Linux**: [Ubuntu](OS-and-Foundation/README.md#ubuntu); [RHEL / AlmaLinux](OS-and-Foundation/README.md#rhel) (vs old CentOS)
    - **bash** ([grep](OS-and-Foundation/README.md#grep), [sed](OS-and-Foundation/README.md#sed), [awk](OS-and-Foundation/README.md#awk))
    - **[virtualization](OS-and-Foundation/README.md#virtualization)** (kvm, qemu) + vagrant
    - **[system management](OS-and-Foundation/README.md#system-management)** (systemd, cron, sudo, journald, logrotate)
    - **[Process and resource management](OS-and-Foundation/README.md#processes-resources)**
    - **[Disk subsystem and LVM](OS-and-Foundation/README.md#storage-lvm)**

- **[Networking & Web Servers](Networking-and-Web-Servers/README.md)**:
    - **Protocols**: [OSI model & TCP/IP](Networking-and-Web-Servers/README.md#osi) (L1-L7, encapsulation), TCP vs UDP (connection states, flags)
    - **Network Infra**: [Routing & Infrastructure](Networking-and-Web-Servers/README.md#network-infra) (NAT, Bridge, DHCP DORA)
    - **Security & Encryption**: [Security & VPN](Networking-and-Web-Servers/README.md#security-vpn) (SSH Best Practices, TLS/SSL handshake, WireGuard vs OpenVPN)
    - **Web**: [HTTP/HTTPS](Networking-and-Web-Servers/README.md#http-web) (request/response structure, 2xx-5xx status codes, critical headers)
    - **Web Servers**: [Nginx & Apache](Networking-and-Web-Servers/README.md#web-servers) (architectural differences, Reverse Proxy, load balancing algorithms)
    - **Troubleshooting**: [Practical Troubleshooting Box](Networking-and-Web-Servers/README.md#troubleshooting) (CLI tools for interviews and production: `ping`, `curl`, `traceroute`, `tcpdump`, `ss`, `nc`, `dig`)

- **[Cloud Providers (AWS, Azure, GCP)](#cloud-providers)**:
    - **AWS (Core Experience)**: VPC (Subnets, IGW, NAT Gateway, Security Groups), EC2, IAM (Roles, Policies, Instance Profiles), S3 (Storage Classes, Policies), EKS (Elastic Kubernetes Service), RDS, CloudWatch.
    - **Google Cloud Platform (GCP)**: VPC Network, Compute Engine, GKE (Google Kubernetes Engine), Cloud Storage, IAM & Service Accounts.
    - **Microsoft Azure**: Virtual Networks (VNet), Virtual Machines, AKS (Azure Kubernetes Service), Blob Storage, Azure AD / Entra ID.
    - **Cloud Concepts**: Multi-cloud strategies, Cost Optimization (FinOps), Shared Responsibility Model.

- **Version Control, CI/CD, GitOps**
    - **Git**: Git Flow, Branching, Merge, Rebase, cherry-pick, conflict resolution
    - **CI/CD Platforms**: GitLab CI / Jenkins - Jenkins Shared Libraries & Declarative Pipline
    - **GitOps**: ArgoCD (Pull-model concept) automate sync k8s manifest git repo and cluster
    - **Deployment Strategies**: Rolling update, Blue-Green, Canary



- **Infrasructure as Code & Configuration (IaC)**
    - **Configuration**: Ansible (Playbooks, Roles, Ansible Galaxy).
    - **Infrastructure Provisioning**: Terraform / OpenTofu

- **Containerization & Orchestration**
    - **Docker**: Engine, Dockerfile (layer optimization, multi-stage), Compose, Volumes
    - **Kubernetes**:
        - Architecture (Control Plane,  worker nodes)
        - HELM
        - basic primitives: Pod, Deployment, Service (ClusterIP, NodePort, LoadBalancer), ConfigMap, Secret
        - Ingress: Nginx ingress Controller
        - Persistent Volumes & Custom CRD

- **Monitoring & Observability**
    - **Monitoring**: Prometheus & Grafana (Metric Records, dashboards, alertmanager)
    - **Logging**: LogStash (priority) / Vector / Fluentbit + OpenSearch / Loki (Loki in priority with k8s, than ELK-stack)
    - **SRE basics**: SLA, SLO, SLI, Root Cause Analysis

- **Databases**
    - MySQL (& MariaDB), PostgreSQL (base requests, backups, replication - master-slave)
    - NoSQL, MongoDB
    - Redis (cache)
    - **Message Brokers**: RabbitMQ -> Kafka (Data Pipeline)
    - **Identity**: Keycloak (SSO-concept, OAuth2 / OIDC protocols)


- **Python & MLOps Spec (Specific)**
    - **Python**: Basic syntaxis, API-requests, automatization (os, sys, boto3 libs)
    - **MLOps Core**: FastAPI (base endpoints for models)
    - **Docker for ML**: packing python-apps, CUDA, GPU in Container 
    - vLLM, distribution GPU in k8s 

- **AI-Assisted Engineering (AI-Native DevOps)**
    - **CLI Agents:** Claude Code, Cline, Copilot CLI (архитектура, ограничения, вызовы локальных инструментов)
    - **LLM API & Routing:** Интеграция с агрегаторами (OpenRouter), управление API-ключами, балансировка стоимости запросов
    - **Prompt Caching:** Механизмы кэширования контекста на стороне провайдеров, оптимизация структуры папок для уменьшения Input-токенов (`.claudeignore`)
    - **Prompt Engineering для IaC:** Создание системных промптов (System Prompts) для точной генерации манифестов Kubernetes без галлюцинаций, идемпотентных плейбуков Ansible и валидного HCL-кода для Terraform