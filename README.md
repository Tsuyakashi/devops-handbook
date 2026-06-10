# DEVOPS HANDBOOK

Collection of cheatsheets

- **[Foundation & OS](cheetsheets/OS-and-Foundation/README.md#foundation-os)**:
    - **[Linux Kernel & Distros](cheetsheets/OS-and-Foundation/README.md#linux)**: [Ubuntu](cheetsheets/OS-and-Foundation/README.md#ubuntu), [RHEL / AlmaLinux](cheetsheets/OS-and-Foundation/README.md#rhel) (vs old CentOS).
    - **[Scripting & Automation](cheetsheets/OS-and-Foundation/README.md#bash)**: Bash basics, text processing utilities ([grep](cheetsheets/OS-and-Foundation/README.md#grep), [sed](cheetsheets/OS-and-Foundation/README.md#sed), [awk](cheetsheets/OS-and-Foundation/README.md#awk)).
    - **[Virtualization](cheetsheets/OS-and-Foundation/README.md#virtualization)**: KVM, QEMU, Vagrant environment provisioning.
    - **[System Management](cheetsheets/OS-and-Foundation/README.md#system-management)**: systemd, cron, sudo, journald logging, logrotate.
    - **[Process & Resource Management](cheetsheets/OS-and-Foundation/README.md#processes-resources)**: Process states, resource limits, performance monitoring.
    - **[Disk Subsystem & LVM](cheetsheets/OS-and-Foundation/README.md#storage-lvm)**: LVM (PV, VG, LV), partitioning, filesystems management.

- **[Networking & Web Servers](cheetsheets/Networking-and-Web-Servers/README.md)**:
    - **[Network Protocols](cheetsheets/Networking-and-Web-Servers/README.md#osi)**: OSI model & TCP/IP stack (L1-L7, encapsulation), TCP vs UDP (connection states, flags).
    - **[Network Infrastructure](cheetsheets/Networking-and-Web-Servers/README.md#network-infra)**: Routing, NAT types, Bridge networking, DHCP DORA process.
    - **[Security & Encryption](cheetsheets/Networking-and-Web-Servers/README.md#security-vpn)**: SSH Best Practices, TLS/SSL handshake mechanics, WireGuard vs OpenVPN.
    - **[Web Architecture](cheetsheets/Networking-and-Web-Servers/README.md#http-web)**: HTTP/HTTPS (request/response structure, 2xx-5xx status codes, critical headers).
    - **[Web Servers](cheetsheets/Networking-and-Web-Servers/README.md#web-servers)**: Nginx vs Apache (architectural differences, Reverse Proxy mode, load balancing algorithms).
    - **[Network Troubleshooting](cheetsheets/Networking-and-Web-Servers/README.md#troubleshooting)**: Practical Troubleshooting Box (`ping`, `curl`, `traceroute`, `tcpdump`, `ss`, `nc`, `dig`).

- **[Cloud Providers (AWS, Azure, GCP)](cheetsheets/AWS-and-Cloud/README.md)**:
    - **[AWS Core Experience](cheetsheets/AWS-and-Cloud/README.md#aws)**: VPC (Subnets, IGW, NAT Gateway, Security Groups), EC2, IAM (Roles, Policies, Instance Profiles), S3 (Storage Classes, Lifecycle), EKS, RDS, CloudWatch.
    - **[Google Cloud Platform](cheetsheets/AWS-and-Cloud/README.md#gcp)**: VPC Network, Compute Engine, GKE (Google Kubernetes Engine), Cloud Storage, IAM & Service Accounts.
    - **[Microsoft Azure](cheetsheets/AWS-and-Cloud/README.md#azure)**: Virtual Networks (VNet), Virtual Machines, AKS (Azure Kubernetes Service), Blob Storage, Azure AD / Entra ID.
    - **[Cloud Concepts](cheetsheets/AWS-and-Cloud/README.md#cloud-concepts)**: Multi-cloud architecture, Cost Optimization (FinOps), Shared Responsibility Model.

- **[Version Control, CI/CD & GitOps](cheetsheets/CI-CD-and-GitOps/README.md)**:
    - **[Advanced Git](cheetsheets/CI-CD-and-GitOps/README.md#git-advanced)**: Git Flow vs Trunk-Based Development (Feature Flags), Merge vs Rebase (The Golden Rule), Squash commits, Merge Conflicts resolution.
    - **[CI/CD Architecture](cheetsheets/CI-CD-and-GitOps/README.md#cicd-architecture)**: Pipeline stages (Build, Test, DevSecOps/SAST), Artifacts management vs Caching strategies, Secrets management & OIDC (Passwordless cloud access).
    - **[Deployment Strategies](cheetsheets/CI-CD-and-GitOps/README.md#deployment-strategies)**: Blue-Green deployments, Canary releases (Blast Radius control), Rolling Updates (maxSurge, maxUnavailable), Recreate.
    - **[GitOps & Declarative CD](cheetsheets/CI-CD-and-GitOps/README.md#gitops-argo)**: Core Principles, Pull vs Push delivery model, ArgoCD Architecture (Application Controller, OutOfSync status), Sync Policies (Prune, Self Heal) & Webhooks optimization.

- **[Infrastructure as Code & Configuration](cheetsheets/IaC-and-Configuration/README.md)**:
    - **[Configuration Management](cheetsheets/IaC-and-Configuration/README.md#ansible)**: Ansible (Playbooks execution, Roles structure, Ansible Galaxy modules).
    - **[Infrastructure Provisioning](cheetsheets/IaC-and-Configuration/README.md#terraform)**: Terraform / OpenTofu (State management, Providers configuration, reusable Modules).

- **[Containerization & Orchestration](cheetsheets/Containerization-and-Orchestration/README.md)**:
    - **[Docker Engine](cheetsheets/Containerization-and-Orchestration/README.md#docker)**: Engine architecture, Dockerfile (layer optimization, multi-stage builds), Compose multi-container setups, Volumes & Networking.
    - **[Kubernetes Core](cheetsheets/Containerization-and-Orchestration/README.md#kubernetes)**: Control Plane vs Worker Nodes architecture, Helm package manager, basic primitives (Pod, Deployment, Service, ConfigMap, Secret).
    - **[Ingress & Traffic Control](cheetsheets/Containerization-and-Orchestration/README.md#ingress)**: Nginx Ingress Controller, routing rules, TLS termination.
    - **[Storage & Extensions](cheetsheets/Containerization-and-Orchestration/README.md#storage-ext)**: Persistent Volumes (PV/PVC), StorageClasses, Custom Resource Definitions (CRD).

- **[Monitoring & Observability](cheetsheets/Monitoring-and-Observability/README.md)**:
    - **[Metrics & Dashboards](cheetsheets/Monitoring-and-Observability/README.md#monitoring)**: Prometheus & Grafana (Metric types, PromQL queries, dashboards design, Alertmanager configuration).
    - **[Log Management](cheetsheets/Monitoring-and-Observability/README.md#logging)**: Logstash routing, Vector, Fluentbit forwarding, OpenSearch cluster, Grafana Loki (Kubernetes native priority vs ELK stack).
    - **[SRE Methodology](cheetsheets/Monitoring-and-Observability/README.md#sre)**: SLA, SLO, SLI definitions, Root Cause Analysis (RCA) workflows.

- **[Databases & Message Brokers](cheetsheets/Databases/README.md)**:
    - **[Relational Databases](cheetsheets/Databases/README.md#rdbms)**: PostgreSQL & MySQL/MariaDB (base queries optimization, backups strategies, master-slave replication).
    - **[NoSQL Storage](cheetsheets/Databases/README.md#nosql)**: MongoDB document engine, Redis (in-memory caching & session storage).
    - **[Message Brokers](cheetsheets/Databases/README.md#brokers)**: RabbitMQ AMQP routing, Apache Kafka distributed event streaming (Data Pipelines).
    - **[Identity & Access](cheetsheets/Databases/README.md#identity)**: Keycloak (SSO concept, OAuth2 / OIDC protocols flow).

- **[Python & MLOps Specialization](cheetsheets/Python-and-MLOps/README.md)**:
    - **[Automation with Python](cheetsheets/Python-and-MLOps/README.md#python)**: Core syntax, API requests handling, system automation (`os`, `sys`, `boto3` libraries).
    - **[MLOps Core Serving](cheetsheets/Python-and-MLOps/README.md#mlops)**: FastAPI (building base high-performance endpoints for machine learning models).
    - **[Containerization for ML](cheetsheets/Python-and-MLOps/README.md#docker-ml)**: Packing Python ML apps, CUDA environment setups, GPU isolation inside containers, vLLM serving, GPU resource distribution in Kubernetes clusters.

- **[AI-Assisted Engineering (AI-Native DevOps)](cheetsheets/AI-Assisted-Engineering/README.md)**:
    - **[CLI Agents](cheetsheets/AI-Assisted-Engineering/README.md#cli-agents)**: Claude Code, Cline, Copilot CLI (execution architecture, systemic limitations, local tool calls context).
    - **[LLM API & Routing](cheetsheets/AI-Assisted-Engineering/README.md#llm-api)**: OpenRouter aggregation integration, API key rotation, request token & cost balancing strategies.
    - **[Context Optimization](cheetsheets/AI-Assisted-Engineering/README.md#prompt-caching)**: Context caching mechanisms on provider side, project workspace structuring, input token reduction via ignore configurations (`.claudeignore`).
    - **[Prompt Engineering for IaC](cheetsheets/AI-Assisted-Engineering/README.md#prompt-iac)**: Specialized System Prompts for hallucination-free Kubernetes manifests generation, idempotent Ansible playbooks, and valid HCL Terraform code code generation.