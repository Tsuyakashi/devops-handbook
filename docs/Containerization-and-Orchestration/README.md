<a id="containerization-orchestration"></a>

# Containerization & Orchestration

> 🔗 Практическая лаборатория: [`poly-ci`](https://gitlab.com/Tsuyakashi/poly-ci) (Docker, self-hosted Registry, multi-stage builds) и корень этого репозитория — [`Vagrantfile`](../../Vagrantfile) + [`ansible/site.yml`](../../ansible/site.yml) + [`apps/applications`](../../apps/applications) (kubeadm HA, ArgoCD, Ingress, Storage)

### Contents

- **[Docker Engine](#docker)**: архитектура движка (containerd/runc), Dockerfile (оптимизация слоёв, multi-stage), Compose, тома и сеть.
- **[Kubernetes Core](#kubernetes)**: Control Plane vs Worker Nodes, Helm, примитивы Pod / Deployment / Service / ConfigMap / Secret.
- **[Ingress & Traffic Control](#ingress)**: Nginx Ingress Controller, правила маршрутизации, TLS-терминация.
- **[Storage & Extensions](#storage-ext)**: Persistent Volumes (PV/PVC), StorageClasses, Custom Resource Definitions (CRD).

---

<a id="docker"></a>

## Docker Engine

### 1. Архитектура движка: от команды до запущенного процесса

Docker — это не монолит, а набор взаимодействующих компонентов, построенных вокруг стандарта **OCI (Open Container Initiative)**. Разбираться в этой цепочке критично для дебага, когда `docker run` внезапно не работает, а `ctr` или `runc` — работают.

```text
docker CLI  →  dockerd (Docker Daemon, REST API)  →  containerd  →  runc  →  Linux Kernel (namespaces, cgroups)
```

* **Docker CLI** — тонкий клиент. Просто сериализует твою команду в HTTP-запрос к Unix-сокету `/var/run/docker.sock`.
* **dockerd (Docker Daemon):** Отвечает за высокоуровневые сущности — сборку образов, управление сетями (`docker network`), томами (`docker volume`) и API. Сам процессы контейнеров не запускает.
* **containerd:** Вынесенный в отдельный проект (сейчас — часть CNCF) движок управления жизненным циклом контейнеров: скачивание образов из Registry, распаковка слоёв, передача управления в `runc`. Именно `containerd` использует Kubernetes как CRI (Container Runtime Interface), полностью **минуя dockerd** — это ключевой момент, почему современные кластеры K8s не требуют Docker вообще.
* **runc:** Низкоуровневая утилита-обёртка над примитивами ядра Linux. Именно `runc` вызывает системные вызовы для создания **namespaces** (изоляция PID, network, mount, UTS, IPC) и настраивает **cgroups** (лимиты CPU/RAM/IO). После старта процесса `runc` завершается — сам контейнер это просто изолированный процесс в дереве процессов хоста (`ps aux` на хосте покажет PID контейнера).

> **DevOps-инсайт:** Контейнер — это не VM. Нет отдельного ядра, гипервизора или виртуального железа. Это обычный Linux-процесс, которому через namespaces "показали" урезанный мир (свой `/`, свой `localhost`, свой список процессов), а через cgroups — урезали ресурсы. Именно поэтому старт контейнера занимает миллисекунды, а старт VM — секунды/минуты.

---

### 2. Dockerfile: оптимизация слоёв и multi-stage builds

Каждая инструкция в Dockerfile (`RUN`, `COPY`, `ADD`) создаёт **новый read-only слой** поверх предыдущего (union filesystem, обычно `overlay2`). Финальный образ — это стек слоёв + тонкий read-write слой контейнера сверху.

#### Кэширование слоёв (Layer Caching)

Docker кэширует каждый слой по хэшу инструкции и её контекста. Если слой не изменился — он берётся из кэша, а не пересобирается. **Порядок инструкций решает всё:**

```dockerfile
# ПЛОХО: любое изменение кода инвалидирует кэш зависимостей
FROM node:20-alpine
WORKDIR /app
COPY . .                  # <-- копируем ВСЁ, включая исходники
RUN npm ci                # <-- этот слой пересобирается при каждом изменении любого файла
CMD ["node", "server.js"]
```

```dockerfile
# ХОРОШО: зависимости кэшируются отдельно от кода приложения
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json ./   # <-- копируем только манифест зависимостей
RUN npm ci                                # <-- пересоберётся ТОЛЬКО если поменялся lock-файл
COPY . .                                  # <-- код приложения — самый "летучий" слой, кладём последним
CMD ["node", "server.js"]
```

> **Правило:** Стабильное (зависимости, системные пакеты) — в начало Dockerfile. Изменяемое (исходный код) — в конец. Тот же принцип, что и в prompt caching для LLM (см. [AI-Assisted Engineering](../AI-Assisted-Engineering/README.md#prompt-caching)) — стабильный префикс переиспользуется, изменяемый суффикс пересчитывается.

#### Multi-stage builds

Главная проблема наивного Dockerfile — в финальный образ попадают компиляторы, dev-зависимости и исходники, которые нужны только на этапе сборки. **Multi-stage build** разделяет процесс на изолированные стадии и в финальный образ копирует только артефакт.

```dockerfile
# --- Stage 1: Builder ---
FROM golang:1.22 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/server ./cmd/server

# --- Stage 2: Runtime ---
FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/server /usr/local/bin/server
USER 1000:1000
ENTRYPOINT ["/usr/local/bin/server"]
```

* **Что происходит:** Стадия `builder` весит сотни МБ (весь тулчейн Go), но финальный образ содержит **только бинарник** — итоговый вес падает с ~900MB до ~15-20MB.
* **DevOps-применение:** Меньший образ = быстрее `docker pull` на нодах K8s при масштабировании, меньше поверхность атаки (нет shell, компиляторов, пакетных менеджеров в финальном образе), быстрее CI/CD пайплайн на этапе Container Scanning.

#### `.dockerignore`

Аналог `.gitignore` для контекста сборки. Без него `docker build` заливает демону **всё** содержимое директории (включая `node_modules/`, `.git/`, локальные `.env`), что раздувает build context и может протащить секреты в кэш слоёв.

```gitignore
.git/
node_modules/
.env
*.log
.terraform/
```

---

### 3. Docker Compose: оркестрация на одной машине

**Compose** решает задачу локального запуска связки из нескольких контейнеров (приложение + БД + кэш) одной командой, описывая топологию декларативно в YAML.

```yaml
services:
  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgres://user:pass@db:5432/app
    depends_on:
      db:
        condition: service_healthy   # ждём не просто старта контейнера, а прохождения healthcheck

  db:
    image: postgres:16-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  pgdata:
```

* **`depends_on` + `condition: service_healthy`** — классическая ловушка: `depends_on` без условия гарантирует только порядок **старта контейнера**, а не готовности сервиса внутри него (Postgres может ещё 2-3 секунды инициализироваться после старта процесса). Без `healthcheck` бэкенд полезет коннектиться к БД, которая физически ещё не принимает соединения.
* **Сетевая изоляция:** Compose автоматически создаёт отдельную bridge-сеть для проекта. Сервисы видят друг друга по **имени сервиса как hostname** (`db:5432` резолвится через встроенный Docker DNS) — никакой ручной настройки `/etc/hosts` не требуется.
* **DevOps-грань применимости:** Compose — инструмент для **разработки и локальных лаб**, не для продакшена. Нет автоматического failover, нет horizontal scaling нескольких хостов, нет rolling updates. Для прода — Kubernetes (см. ниже) или как минимум Docker Swarm.

---

### 4. Volumes & Networking

#### Тома: Volumes vs Bind Mounts vs tmpfs

| Критерий | Named Volume | Bind Mount | tmpfs |
| :--- | :--- | :--- | :--- |
| **Где хранится** | Управляется Docker, физически в `/var/lib/docker/volumes/` | Любой путь на хосте, который ты явно указал | В RAM хоста, не на диске |
| **Персистентность** | Переживает удаление контейнера (`docker rm`) | Переживает (это же файлы хоста) | Уничтожается при остановке контейнера |
| **Типичное применение** | Данные БД (Postgres, MySQL) в проде и разработке | Монтирование исходного кода при разработке (hot-reload), `/var/run/docker.sock` для DooD | Секреты, временные файлы, которые не должны попасть на диск |
| **Портируемость** | Легко бэкапить/переносить через `docker volume` команды | Жёстко привязан к конкретному пути хоста | N/A |

```bash
# Named volume — Docker сам решает, где физически хранить данные
docker run -v pgdata:/var/lib/postgresql/data postgres:16

# Bind mount — монтируем конкретную папку хоста внутрь контейнера
docker run -v $(pwd)/src:/app/src node:20

# tmpfs — данные никогда не касаются диска
docker run --tmpfs /app/cache:rw,size=64m myapp
```

#### Сетевые драйверы Docker

* **bridge (по умолчанию):** Создаётся виртуальный интерфейс `docker0`, каждый контейнер получает свою пару `veth`. Контейнеры в одной bridge-сети видят друг друга напрямую (см. подробный разбор L2-моста в [Networking & Web Servers](../Networking-and-Web-Servers/README.md#network-infra)).
* **host:** Контейнер использует **напрямую сетевой стек хоста**, без изоляции и NAT. Максимальная производительность сети (нет оверхеда на трансляцию портов), но контейнер занимает порты хоста напрямую и теряет сетевую изоляцию — редкое применение (специфичные agent-контейнеры мониторинга, которым нужен полный доступ к сетевым интерфейсам хоста).
* **overlay:** Виртуальная сеть, растянутая **между несколькими физическими хостами** (используется в Swarm-режиме и концептуально похожа на CNI-плагины Kubernetes типа Flannel/Calico). Инкапсулирует трафик контейнеров в VXLAN-туннели, чтобы контейнеры на разных нодах могли общаться друг с другом, как будто они в одной L2-сети.
* **none:** Полная сетевая изоляция — у контейнера нет вообще никакого сетевого интерфейса кроме loopback. Применяется для batch-задач, которым сеть не нужна вообще (максимальная безопасность за счёт минимизации поверхности атаки).

---

<a id="kubernetes"></a>

## Kubernetes Core

### 1. Архитектура: Control Plane vs Worker Nodes

Kubernetes раскладывается на две принципиально разные группы компонентов: **мозг кластера (Control Plane)**, который принимает решения, и **рабочие руки (Worker Nodes)**, которые физически запускают контейнеры.

```text
                     ┌─────────────────────── CONTROL PLANE ───────────────────────┐
                     │                                                              │
  kubectl apply  →   │  API Server  ←→  etcd  ←→  Scheduler  ←→  Controller Mgr   │
                     │                                                              │
                     └──────────────────────────────┬───────────────────────────────┘
                                                      │ (наблюдение / команды)
                     ┌────────────────────────────────┴───────────────────────────────┐
                     │                        WORKER NODES                            │
                     │                                                                 │
                     │   kubelet  ←→  Container Runtime (containerd)  +  kube-proxy   │
                     │      ↓                                                          │
                     │   [ Pod ]  [ Pod ]  [ Pod ]                                      │
                     └─────────────────────────────────────────────────────────────────┘
```

#### Компоненты Control Plane

* **API Server (`kube-apiserver`):** Единственная точка входа в кластер. Все — `kubectl`, контроллеры, kubelet на нодах — общаются с кластером **только** через REST/gRPC-запросы к API Server. Отвечает за аутентификацию, авторизацию (RBAC) и валидацию объектов перед записью в etcd.
* **etcd:** Распределённое key-value хранилище (consensus через Raft). **Единственный источник правды** о состоянии всего кластера — каждый Pod, Service, Secret физически лежит здесь как запись. Потеря etcd без бэкапа = полная потеря состояния кластера (не самих контейнеров, но всей конфигурации, кто и что должен быть запущен).
* **Scheduler (`kube-scheduler`):** Смотрит на новые Pod'ы без назначенной ноды (`nodeName` пустой) и решает, **на какую worker-ноду** его поставить. Учитывает доступные ресурсы (CPU/RAM requests), affinity/anti-affinity правила, taints/tolerations, топологию (зоны доступности).
* **Controller Manager (`kube-controller-manager`):** Набор бесконечных циклов сверки (**Reconciliation Loop**), каждый из которых следит за своим типом ресурса. Например, `Deployment Controller` видит: "в спеке заявлено 3 реплики, а живо только 2" → создаёт недостающий Pod. Это тот же принцип непрерывной реконсиляции, что и у ArgoCD (см. [CI/CD & GitOps](../CI-CD-and-GitOps/README.md#gitops-argo)), только уровнем ниже — не Git vs кластер, а спека объекта vs реальные Pod'ы.

#### Компоненты Worker Node

* **kubelet:** Агент, запущенный на каждой worker-ноде. Получает от API Server список Pod'ов, которые должны быть запущены **именно на этой ноде**, и следит, чтобы контейнеры внутри них реально были живы (по сути, локальный "супервизор" для Control Plane).
* **Container Runtime:** Собственно containerd (или CRI-O), который по команде kubelet скачивает образы и запускает контейнеры (см. цепочку `containerd → runc` из [Docker Engine](#docker) выше — на уровне рантайма Kubernetes использует ровно тот же стек).
* **kube-proxy:** Отвечает за сетевые правила на ноде, чтобы трафик к абстракции `Service` (стабильный виртуальный IP) корректно распределялся между реальными Pod'ами — реализуется через правила `iptables`/`ipvs` на каждой ноде.

> **Собес-кейс:** Почему в кластере обычно **нечётное** число master-нод (1, 3, 5)? etcd использует Raft-консенсус, которому для принятия решения нужно **большинство (quorum)**. При 3 нодах кластер переживает потерю 1 ноды (2 из 3 — большинство). При 4 нодах ты платишь за лишнюю ноду, но переживаешь всё ту же потерю только 1 узла (нужно 3 из 4) — чётное число не даёт прироста отказоустойчивости, только лишний расход ресурсов. Именно так устроена HA-топология в [`Vagrantfile`](../../Vagrantfile) этого репозитория — 3 master-ноды с keepalived VIP.

---

### 2. Helm: пакетный менеджер Kubernetes

Разворачивать сложное приложение (например, `kube-prometheus-stack` — десятки CRD, Deployment'ов, ConfigMap'ов, RBAC-правил) через отдельные `kubectl apply -f` файлы — не масштабируется. **Helm** решает эту проблему по аналогии с `apt`/`npm`, но для Kubernetes-манифестов.

#### Ключевые абстракции

* **Chart:** Пакет с шаблонами Kubernetes-манифестов (Helm использует Go templates) + метаданные (`Chart.yaml`) + дефолтные значения (`values.yaml`).
* **Release:** Конкретный **установленный экземпляр** чарта в кластере с определённым именем. Один и тот же чарт можно установить несколько раз с разными именами и разными values (например, `staging` и `production` releases одного чарта).
* **Values:** Механизм параметризации. Вместо хардкода в шаблонах чарта, значения (домены, реплики, лимиты ресурсов) передаются снаружи и подставляются в шаблон.

```text
my-chart/
├── Chart.yaml          # Метаданные: имя, версия чарта, версия приложения
├── values.yaml         # Дефолтные значения параметров
└── templates/
    ├── deployment.yaml # Шаблон с плейсхолдерами {{ .Values.replicaCount }}
    ├── service.yaml
    └── _helpers.tpl    # Общие переиспользуемые фрагменты шаблонов
```

#### Практический пример: переопределение values в ArgoCD Application

Именно этот механизм используется в [`apps/applications/monitoring.yaml`](../../apps/applications/monitoring.yaml) этого репозитория — ArgoCD дёргает Helm под капотом, передавая инлайновые `values` вместо дефолтных значений чарта `kube-prometheus-stack`:

```yaml
spec:
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: "58.7.2"
    helm:
      values: |
        prometheus:
          prometheusSpec:
            retention: 7d          # переопределили дефолтный retention чарта
```

#### Команды CLI

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install my-release prometheus-community/kube-prometheus-stack -f values.yaml
helm upgrade my-release prometheus-community/kube-prometheus-stack -f values.yaml   # применить изменения values
helm rollback my-release 1                                                          # откат к ревизии №1
helm uninstall my-release
```

> **DevOps-инсайт:** `helm upgrade` хранит историю ревизий релиза, что даёт мгновенный `helm rollback` без необходимости вручную реконструировать предыдущий набор манифестов — Helm сам помнит, какие values и какая версия чарта были применены на каждом шаге.

---

### 3. Базовые примитивы Kubernetes

#### Pod

**Минимальная единица деплоя** в Kubernetes. Важно: Pod — это **не контейнер**, это обёртка вокруг одного или нескольких контейнеров, которые обязательно шарят один network namespace (один IP на Pod, контейнеры внутри общаются через `localhost`) и опционально — общие тома.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  containers:
    - name: nginx
      image: nginx:1.25
      ports:
        - containerPort: 80
```

* **Sidecar-паттерн:** Частый кейс мультиконтейнерного Pod'а — основной контейнер приложения + вспомогательный контейнер рядом (например, Filebeat/Vector, который читает логи основного контейнера через общий volume — паттерн, описанный в [Monitoring & Observability](../Monitoring-and-Observability/README.md#logging)).
* **На практике Pod'ы почти никогда не создают напрямую** — их жизненным циклом управляют контроллеры более высокого уровня (Deployment, StatefulSet, DaemonSet), которые пересоздают Pod при падении.

#### Deployment

Контроллер, который управляет **stateless** нагрузками через промежуточную абстракцию **ReplicaSet**.

```text
Deployment  →  управляет  →  ReplicaSet  →  управляет  →  Pod, Pod, Pod...
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:                     # шаблон, по которому создаются Pod'ы
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
```

* **Зачем промежуточный ReplicaSet:** При обновлении образа (`kubectl set image`) Deployment создаёт **новый** ReplicaSet с новой версией и постепенно скейлит его вверх, одновременно скейля старый ReplicaSet вниз — это и есть механизм **Rolling Update**, детально разобранный в [CI/CD & GitOps](../CI-CD-and-GitOps/README.md#deployment-strategies) (параметры `maxSurge`/`maxUnavailable`). Старый ReplicaSet не удаляется, а масштабируется до 0 — это даёт мгновенный откат (`kubectl rollout undo`) без пересборки манифестов.

#### Service

Проблема, которую решает Service: у Pod'ов **эфемерные** IP-адреса — при пересоздании Pod получает новый IP. Приложению нужен **стабильный** адрес, за которым прячется меняющийся набор реальных Pod'ов.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web            # Service находит Pod'ы по label selector, а не по имени
  ports:
    - port: 80           # порт, на который стучится клиент Service
      targetPort: 8080    # реальный порт внутри контейнера
  type: ClusterIP
```

| Тип Service | Доступность | Типовое применение |
| :--- | :--- | :--- |
| **ClusterIP** (дефолт) | Только внутри кластера | Внутренняя коммуникация между микросервисами |
| **NodePort** | Открывает порт на **каждой** ноде кластера (диапазон 30000-32767) | Быстрый доступ снаружи без Ingress, часто в лабах/staging |
| **LoadBalancer** | Провайдер облака (AWS/GCP/Azure) выделяет внешний Load Balancer | Прод-точка входа в облачном кластере (EKS/GKE/AKS) |
| **ExternalName** | Просто CNAME-запись на внешний DNS, без прокси трафика внутри кластера | Обращение к внешней БД/API как к "внутреннему" Service по имени |

> **DevOps-инсайт:** Service находит целевые Pod'ы **динамически** через `selector` по лейблам, а не через список статичных IP. Контроллер `Endpoints`/`EndpointSlice` в реальном времени пересчитывает список актуальных Pod-IP при каждом изменении набора Pod'ов — точно так же, как Prometheus через Kubernetes Service Discovery динамически находит таргеты для scrape (см. [Monitoring & Observability](../Monitoring-and-Observability/README.md#monitoring)).

#### ConfigMap и Secret

Оба объекта решают одну задачу — **отделить конфигурацию от образа контейнера** (тот же образ должен без пересборки работать и в staging, и в проде с разными настройками), но для разных типов данных.

| Критерий | ConfigMap | Secret |
| :--- | :--- | :--- |
| **Тип данных** | Некритичная конфигурация: URL, флаги, конфиг-файлы | Чувствительные данные: пароли, токены, TLS-сертификаты |
| **Хранение в etcd** | Открытым текстом | По умолчанию только **base64** (это **кодирование, не шифрование** — критично не путать) | 
| **Реальная защита** | Не требуется | Только с включённым **Encryption at Rest** на уровне etcd или внешним решением (Vault, Sealed Secrets, SOPS) |

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "info"
  API_TIMEOUT: "30s"
---
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=   # это base64("password123"), НЕ шифрование
```

Оба монтируются в Pod либо как переменные окружения, либо как файлы через volume:

```yaml
spec:
  containers:
    - name: app
      envFrom:
        - configMapRef:
            name: app-config
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
```

> **Антипаттерн из практики:** В [`apps/applications/monitoring.yaml`](../../apps/applications/monitoring.yaml) этого репозитория пароль Grafana (`adminPassword: "admin"`) прописан прямо в values чарта открытым текстом — рабочий вариант для локальной Vagrant-лабы, но прямой антипаттерн для прода. Правильный путь — генерировать `Secret` заранее (например, через `kubernetes.core.k8s` в Ansible, как GitHub-токен для ArgoCD в [`ansible/site.yml`](../../ansible/site.yml)) и ссылаться на него через `existingSecret` в values чарта, а не хардкодить значение.

---

<a id="ingress"></a>

## Ingress & Traffic Control

### 1. Зачем нужен Ingress, если есть Service

`Service` типа `LoadBalancer` работает на **L4** (TCP/UDP) — он не смотрит внутрь HTTP-запроса. Если в кластере 20 микросервисов, и каждому давать свой `LoadBalancer`, это означает 20 внешних облачных балансировщиков (и 20 счетов за них). **Ingress** — это L7-абстракция: единая точка входа, которая маршрутизирует HTTP(S)-трафик **внутри** кластера на нужный Service, опираясь на домен и путь запроса — концептуально это тот же **Reverse Proxy**, что и Nginx перед бэкендом (см. [Networking & Web Servers](../Networking-and-Web-Servers/README.md#web-servers)), только реализованный как декларативный объект Kubernetes.

```text
Интернет → LoadBalancer Service (единственный, L4) → Ingress Controller (Pod с Nginx внутри) → маршрутизация по Host/Path (L7) → нужный Service → Pod
```

### 2. Ingress Controller vs Ingress-ресурс

Важное разделение понятий, которое путает многих новичков:

* **Ingress-ресурс** — это просто YAML-объект с **правилами маршрутизации** (декларация "что куда вести"). Сам по себе он ничего не делает.
* **Ingress Controller** — это реальный работающий Pod (обычно с Nginx, Traefik или HAProxy внутри), который **читает** Ingress-ресурсы через Kubernetes API и на их основе генерирует реальный конфиг маршрутизации. Без установленного контроллера Ingress-ресурсы просто лежат в etcd мёртвым грузом.

**Nginx Ingress Controller** (используемый в связке ArgoCD + retro-games этого репозитория, см. [`ansible/site.yml`](../../ansible/site.yml), шаг 8) — самая распространённая реализация: под капотом это обычный Nginx, конфиг которого автоматически перегенерируется и перезагружается контроллером при любом изменении Ingress-объектов в кластере.

### 3. Правила маршрутизации

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
    - host: app.local                       # Host-based routing
      http:
        paths:
          - path: /pacman(/|$)(.*)          # Path-based routing (с regex)
            pathType: ImplementationSpecific
            backend:
              service:
                name: pacman
                port:
                  number: 8002
          - path: /doom(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: doom
                port:
                  number: 8004
```

Именно эта схема применена в [`apps/retro-games/ingress.yaml`](../../apps/retro-games/ingress.yaml) — один `Host: app.local`, три разных пути (`/pacman`, `/doom`, `/bomberman`), каждый ведёт на свой `Service`. Аннотация `rewrite-target: /$2` необходима, потому что backend-приложения (например, статика игры) сами не знают, что их поставили за префиксом `/pacman` — Nginx **отрезает** этот префикс перед проксированием, используя захваченную regex-группу `$2`.

| Тип маршрутизации | Пример | Применение |
| :--- | :--- | :--- |
| **Host-based** | `app.local` vs `api.local` на одном IP | Мультитенантность, разные поддомены на один кластер |
| **Path-based** | `/api/*` → backend, `/` → frontend | Один домен, разные сервисы за разными путями (см. `retro-games`) |
| **pathType: Exact / Prefix / ImplementationSpecific** | — | `Exact` — точное совпадение пути, `Prefix` — совпадение по префиксу (самый частый выбор), `ImplementationSpecific` — поведение зависит от контроллера (нужен для regex-путей, как выше) |

### 4. TLS-терминация на уровне Ingress

Ingress Controller может брать на себя TLS-терминацию так же, как обычный Nginx (см. полный разбор TLS handshake в [Networking & Web Servers](../Networking-and-Web-Servers/README.md#security-vpn)) — расшифровывая HTTPS снаружи и общаясь с backend-подами по простому HTTP внутри приватной сети кластера.

```yaml
spec:
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls-secret     # Secret типа kubernetes.io/tls с cert + key
  rules:
    - host: app.example.com
      # ...
```

* Сертификат и приватный ключ хранятся как `Secret` типа `kubernetes.io/tls`.
* На практике сертификаты почти никогда не кладут руками — их автоматически выпускает и ротирует **cert-manager** (отдельный контроллер, интегрирующийся с Let's Encrypt через ACME-протокол), генерируя нужный `Secret` автоматически по аннотации на Ingress-ресурсе.

#### Особый случай: SSL Passthrough

Иногда TLS **не должен** терминироваться на Ingress — например, когда сам backend-сервис (как ArgoCD API Server в [`apps/applications/argocd.yaml`](../../apps/applications/argocd.yaml)) обязан сам управлять своим TLS-сертификатом для gRPC-соединений. Для этого случая существует аннотация:

```yaml
annotations:
  nginx.ingress.kubernetes.io/ssl-passthrough: "true"
  nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
```

Ingress в этом режиме работает уже не на L7, а фактически как **L4-проксирование зашифрованного потока** — смотрит только на SNI-заголовок TLS ClientHello, чтобы понять, куда направить соединение, но не расшифровывает сам трафик.

---

<a id="storage-ext"></a>

## Storage & Extensions

### 1. Проблема, которую решает персистентное хранилище

По умолчанию файловая система контейнера — **эфемерна**: при пересоздании Pod'а (рестарт, обновление, переезд на другую ноду) все данные внутри контейнера теряются. Для stateless-приложений это нормально, но для баз данных, очередей сообщений и любого сервиса, которому нужно "помнить" данные между рестартами — недопустимо.

### 2. Persistent Volumes (PV) и Persistent Volume Claims (PVC)

Kubernetes разделяет эту задачу на два разных объекта, следуя принципу разделения ответственности между инфраструктурой и приложением.

```text
[ Реальный диск / NFS / EBS ]  →  PersistentVolume (PV)  ←  binding  ←  PersistentVolumeClaim (PVC)  ←  используется в  ←  Pod
     (администратор/StorageClass)      (ресурс кластера)                 (запрос от приложения)
```

* **PersistentVolume (PV):** Объект уровня **кластера**, описывающий реальный физический (или облачный) кусок хранилища — конкретный диск, NFS-шару, AWS EBS volume. Обычно PV **не создают руками** — их динамически генерирует `StorageClass` (см. ниже).
* **PersistentVolumeClaim (PVC):** "Заявка" от **приложения** — Pod не запрашивает конкретный диск, а декларирует **требование** ("нужно 10Gi, ReadWriteOnce"). Kubernetes сам находит подходящий PV и связывает (**bind**) его с этим PVC.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce        # смонтирован для чтения-записи только ОДНОЙ нодой одновременно
  storageClassName: local-path
  resources:
    requests:
      storage: 10Gi
```

```yaml
spec:
  containers:
    - name: postgres
      volumeMounts:
        - mountPath: /var/lib/postgresql/data
          name: data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: postgres-pvc
```

#### Access Modes

| Режим | Расшифровка | Пример применения |
| :--- | :--- | :--- |
| **ReadWriteOnce (RWO)** | Монтируется на чтение-запись только одной нодой | Базы данных (Postgres, MySQL) — самый частый случай |
| **ReadOnlyMany (ROX)** | Монтируется на чтение множеством нод одновременно | Общие статичные данные, дистрибутивы, датасеты |
| **ReadWriteMany (RWX)** | Монтируется на чтение-запись множеством нод одновременно | Общие файловые шары (требует NFS/CephFS — обычный блочный диск этого не умеет физически) |

#### Reclaim Policy

Что происходит с физическими данными PV после удаления PVC, который его использовал:

* **Retain** — данные **сохраняются**, PV переходит в статус `Released` и требует ручной очистки администратором. Безопасный дефолт для критичных данных.
* **Delete** — физическое хранилище (например, AWS EBS volume) **уничтожается автоматически** вместе с PVC. Удобно для эфемерных сред, опасно для прода без дополнительных бэкапов.

### 3. StorageClass: динамическое провижининг хранилища

Ручное создание PV администратором под каждый новый PVC не масштабируется. **StorageClass** — это шаблон, который автоматически генерирует PV **по запросу**, в момент создания PVC (**Dynamic Provisioning**).

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com        # какой драйвер физически создаёт диск
parameters:
  type: gp3
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer   # диск создаётся ТОЛЬКО когда Pod реально запланирован на ноду
```

* **provisioner** — конкретный **CSI-драйвер** (Container Storage Interface), который умеет говорить с реальным хранилищем: `ebs.csi.aws.com` для AWS EBS, `pd.csi.storage.gke.io` для GCP, и т.д. Это тот же принцип плагинной архитектуры, что у Terraform-провайдеров (см. [IaC & Configuration](../IaC-and-Configuration/README.md#terraform)) — сам Kubernetes не знает деталей API конкретного хранилища, эту работу выполняет драйвер.
* **volumeBindingMode: WaitForFirstConsumer** — критичная деталь для мультизональных кластеров: если создать диск **сразу** при создании PVC, он может физически оказаться в другой Availability Zone, чем нода, куда Scheduler потом решит поставить Pod — и Pod навечно застрянет в `Pending`. Отложенное создание диска "до первого потребителя" гарантирует, что диск создаётся уже в правильной зоне, рядом с нодой, на которую реально запланирован Pod.

#### local-path-provisioner: практический пример из этого репозитория

В однонодовых/лабораторных кластерах (как в [`ansible/site.yml`](../../ansible/site.yml), шаг 7 этого репозитория) облачных CSI-драйверов нет — вместо этого используется **local-path-provisioner**, который просто создаёт директорию на локальном диске конкретной ноды и презентует её как PV.

```bash
kubectl patch storageclass local-path \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

> **DevOps-нюанс (из практики этого репозитория):** `local-path-provisioner` — это не CRD и не встроенный контроллер, а **отдельное приложение**, которое нужно задеплоить как обычный набор манифестов **до того**, как в кластер прилетит первый PVC (иначе PVC будет вечно висеть в `Pending`, не находя провижинера). Именно поэтому в `ansible/site.yml` его ставят через прямой `kubectl apply` на этапе Ansible-провижининга, а не отдают ArgoCD как одно из "App of Apps" приложений — он является **инфраструктурной предпосылкой** для остальных Applications (ArgoCD/Prometheus/Loki), которым эти PVC нужны для собственных PVC сразу при первом деплое.

### 4. Custom Resource Definitions (CRD)

Базовые примитивы Kubernetes (Pod, Service, Deployment) — фиксированный набор "из коробки". **CRD** — это механизм **расширения самого API Kubernetes** новыми типами объектов, которые ведут себя так же нативно, как встроенные (валидируются, версионируются, доступны через `kubectl get`).

```text
CRD (Custom Resource Definition)  →  описывает НОВЫЙ тип объекта, например "Application"
        ↓
Custom Resource  →  конкретный экземпляр этого типа (YAML с kind: Application)
        ↓
Operator / Controller  →  отдельный процесс, который читает Custom Resource и приводит
                            реальное состояние кластера в соответствие с ним
```

**Самый явный пример из этого репозитория** — объект `Application`, который использует ArgoCD:

```yaml
apiVersion: argoproj.io/v1alpha1   # НЕ встроенный API Kubernetes — это CRD, зарегистрированный ArgoCD
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  # ...
```

`kind: Application` **не существует** в чистом Kubernetes — этот тип объекта появляется в кластере только после того, как Helm-чарт ArgoCD установит соответствующий CRD. После этого сам **ArgoCD Application Controller** (см. подробный разбор архитектуры в [CI/CD & GitOps](../CI-CD-and-GitOps/README.md#gitops-argo)) работает как классический **Operator**: непрерывно читает все объекты `Application` в кластере и приводит реальное состояние (Live State) в соответствие с тем, что описано в их спеке (Target State из Git).

> **Общий паттерн Operator:** CRD + контроллер, который его обслуживает — это стандартная архитектура для любого нетривиального расширения Kubernetes: `kube-prometheus-stack` регистрирует CRD `ServiceMonitor`/`PodMonitor` (см. [Monitoring & Observability](../Monitoring-and-Observability/README.md#monitoring)), ArgoCD регистрирует `Application`, cert-manager регистрирует `Certificate`/`ClusterIssuer`. Во всех случаях логика одна: **декларируешь желаемое** через YAML нового типа, **Operator в фоне непрерывно реализует его** — тот же принцип Reconciliation Loop, что лежит в основе всего GitOps.
