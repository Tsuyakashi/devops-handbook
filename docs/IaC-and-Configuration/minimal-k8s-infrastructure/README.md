# Minimal GitOps Infrastructure (Vagrant + Libvirt + K8s)

Данный каталог содержит IaC-конфигурацию для локального развертывания полноценного Kubernetes-кластера (Control Plane + Worker) на базе **Vagrant (провайдер Libvirt/KVM)** и **Ansible**, полностью готового к внедрению GitOps-подхода (ArgoCD / Flux).

Вся инфраструктура изолирована внутри виртуальных машин, разворачивается одной командой и не требует открытых портов наружу.

---

## Архитектура стенда

* **ОС:** Ubuntu 24.04 LTS (Bento/Noble64)
* **Стек:** `kubeadm` + `kubelet` + `kubectl` (v1.30.x)
* **Сеть кластера (CNI):** Flannel
* **Узлы:**
  * `k8s-master` (2 vCPU, 2GB RAM, 192.168.56.10) — управление кластером.
  * `k8s-worker-1` (1 vCPU, 1.5GB RAM, 192.168.56.11) — выполнение нагрузок.

---

## Быстрый старт

### 1. Предварительные требования

Перед запуском убедись, что в хост-системе (Ubuntu) установлены KVM/Libvirt, Ansible и плагин `vagrant-libvirt`. Из-за региональных ограничений плагин ставится в обход дефолтных репозиториев HashiCorp:

```
vagrant plugin install vagrant-libvirt --plugin-clean-sources --plugin-source https://rubygems.org
```

### 2. Поднятие и автоматический Provisioning

Сборка кластера «с нуля», включая инициализацию Control Plane сетевым плагином и подключение воркеров, выполняется одной командой из корня директории:

```
vagrant up
```

> **Заметка на полях:** Скачивание боксов автоматически перенаправлено на работающее в РФ зеркало от Elab (`https://vagrant.elab.pro`) через `ENV['VAGRANT_SERVER_URL']` прямо внутри `Vagrantfile`.

### 3. Проверка статуса кластера

Подключись к мастер-ноде по SSH и проверь готовность узлов:

```
vagrant ssh master
kubectl get nodes
```

Эталонный вывод готового кластера:
```
NAME           STATUS   ROLES           AGE   VERSION
k8s-master     Ready    control-plane   90s   v1.30.14
k8s-worker-1   Ready    <none>          67s   v1.30.14
```

---

## Структура конфигурации (IaC)

* `Vagrantfile` — Декларативное описание виртуальных машин, ресурсов (CPU/RAM) и сетевых интерфейсов. Интегрировано в системный пул KVM `images`.
* `provisioning/` *(или `scripts/`)* — Ansible-плейбуки или Shell-скрипты автоматизации:
  * Подготовка ОС (выключение swap, настройка sysctl, модулей ядра `br_netfilter`).
  * Установка контейнерного рантайма (`containerd`).
  * Установка компонентов Kubernetes.
  * Автоматическая генерация join-токена на мастере и подключение воркеров.

---

## Жизненный цикл стенда (Шпаргалка)

| Команда | Действие |
| :--- | :--- |
| `vagrant up` | Запустить кластер (и настроить при первом запуске). |
| `vagrant halt` | Корректно погасить ВМ (сохраняет ресурсы ноута в кафе/пути). |
| `vagrant ssh master` | Доступ к терминалу Control Plane для управления через `kubectl`. |
| `vagrant reload --provision` | Перезагрузить ноды и принудительно прогнать скрипты настройки. |
| `vagrant destroy -f` | Полностью удалить кластер и очистить диски в Libvirt. |

---

## План перехода к GitOps (Next Steps)

Кластер полностью готов к Pull-based деплою без SSH-ключей наружу. Для демонстрации концепта:

1. **Установка агента:** Разверни ArgoCD внутри кластера:
   ```
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
2. **Связывание с репозиторием:** Настрой ArgoCD Application на отслеживание манифестов в твоем GitHub. Агент сам начнет затягивать изменения по исходящему трафику, обеспечивая *Eventual Consistency*, даже если ноутбук часто закрывается.