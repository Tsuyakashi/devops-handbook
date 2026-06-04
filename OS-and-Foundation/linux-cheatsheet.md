<a id="foundation-os"></a>

# Foundation & OS:

- Linux: 
    - [Ubuntu](#ubuntu) ([Desktop](#desktop), [Server](#server), [Cloud](#cloud), [WSL](#wsl), [Core](#ubuntu-core), [Flavors](#ubuntu-flavors), [apt/Snap](#apt-snap)); 
    - [RHEL / AlmaLinux / Rocky](#rhel) ([RHSM](#rhel-subscription), [клоны](#rhel-clones), [Amazon Linux](#amazon-linux), [dnf](#dnf-rhel), [firewalld](#firewall-rhel), [SELinux](#selinux), [сравнение с Ubuntu](#rhel-vs-ubuntu))
- bash ([обзор](#bash-scripting), [grep](#grep), [sed](#sed), [awk](#awk))
- virtualization ([обзор](#virtualization)): [KVM/QEMU](#kvm-qemu), [Vagrant](#vagrant)
- [System management](#system-management): [права](#permissions), [systemd](#systemd), [journald](#journald), [cron](#cron), [logrotate](#logrotate)

<a id="ubuntu"></a>

# Ubuntu

В контексте AWS уже есть опыт взаимодействия с Ubuntu. Ubuntu де-факто является стандартом в серверной части. Также удобен в использовании как десктопная OS (по моему мнению, потому что достаточно популярна в сообществе и, вследствие этого, хорошо приспособлена для пользователя).

## Основные разделения по дистрибутивам Ubuntu

Актуальные версии и ядро не фиксировать «навсегда» в заметках — сверяться с [Ubuntu Releases](https://wiki.ubuntu.com/Releases) и на живой системе: `uname -r`. В документации Canonical ядро указывают как конкретный пакет `linux-image` из стека релиза (например, 6.x у 24.04), а не как «Linux 7.0» абстрактно.

<a id="desktop"></a>

### Desktop

- Назначение: рабочая станция с GUI (GNOME и др.), офис, браузер, IDE.
- Отличие от Server: графическая сессия, consumer-приложения, часто **Snap Store** и **NetworkManager**; не минимальный headless-набор под сервисы в DC/облаке.

<a id="server-vs-desktop"></a>

### Server vs Desktop

| | **Server** | **Desktop** |
|---|------------|-------------|
| GUI | обычно нет | есть |
| Пакеты по умолчанию | сервисы, CLI, cloud-инструменты | DE, мультимедиа, офис |
| Типичное использование | VPS, AWS EC2, CI, контейнер-хост | ноутбук, рабочая станция |

<a id="wsl"></a>

### WSL

- **Зачем:** Linux-окружение на Windows без отдельной VM (разработка, bash, apt).
- **Плюсы:** интеграция с Windows, быстрый старт, общая файловая система (`/mnt/c/...`).
- **Минусы:** PowerShell как «главная» оболочка Windows vs привычный Linux-терминал; для **вложенной виртуализации** (Docker/KVM внутри WSL) — WSL2 и отдельные настройки (см. [KVM/QEMU](#kvm-qemu)); **WSL1** без полноценного Linux-ядра (устаревший режим, нет нормального systemd); **WSL2** — реальное ядро в lightweight VM, systemd и сервисы ближе к «настоящему» Linux.

<a id="server"></a>

### Server

Пример на 2026 год: LTS **26.04** (выпуск LTS — апрель чётных годов). Ядро — из официального стека релиза, проверять `uname -r` и release notes, не хардкодить версию в шпаргалке.

- **LTS** — Long Term Support: **5 лет** стандартной поддержки; до **10 лет** для инфраструктуры с **Ubuntu Pro** (важно для долгоживущих серверов в проде).
- **netplan** — declarative-конфиг сети в YAML (`/etc/netplan/*.yaml`). На Server обычно рендерит **systemd-networkd**; на Desktop часто **NetworkManager**. После правок: `sudo netplan try` (откат, если не подтвердить), затем `sudo netplan apply`.
- **curtin** — установщик «под капотом» автоматических и облачных установок (Subiquity/autoinstall, образы для AWS/Azure/GCP, MAAS). Разметка дисков, монтирование, базовая настройка до первого boot; на уже работающей VM почти не используется.
- **cloud-init** — первая настройка при старте (SSH-ключи, hostname, user-data, пакеты из метаданных). Есть в **серверных и облачных** образах (EC2, Azure, GCP), не только в отдельном SKU «Cloud».
- **ufw** — типичный фаервол на Ubuntu Server (`sudo ufw allow 22/tcp`, `sudo ufw enable`, `sudo ufw status`). На RHEL/Alma — [firewalld](#firewall-rhel).

<a id="cloud"></a>

### Cloud

Оптимизированные образы под AWS, Azure, Google Cloud (по сути Server + тюнинг под гипервизор/облако).

- **cloud-init** — в **облачных и серверных** образах: bootstrap из метаданных инстанса при первом и последующих boot (сеть, пользователи, user-data).
- **netplan** — та же схема, что на Server; сеть часто поднимается из метаданных/cloud-init (DHCP, статика из user-data).
- **curtin** — при **сборке** официальных cloud-образов и autoinstall, не при каждом обычном reboot VM.

<a id="ubuntu-core"></a>

### Ubuntu Core

Максимально урезанная, immutable ОС для IoT, робототехники и edge; пакеты и система — через **Snap**. На обычном **Ubuntu Server LTS** в AWS Snap **не обязателен** (многие ставят только `.deb` через apt). **Core** — отдельный продукт, не путать с AMI «Ubuntu Server 24.04/26.04».

<a id="ubuntu-flavors"></a>

### Ubuntu Flavors (дистрибутивы-«вкусы»)

Официальные сборки **Ubuntu Desktop** с другими DE вместо GNOME: Kubuntu (KDE), Xubuntu (XFCE), Lubuntu (LXQt) и др. От Server не заменяют — это варианты десктопа.

<a id="apt-snap"></a>

### Пакеты: apt и Snap

- **apt** — основной способ на Server/Desktop LTS: пакеты `.deb` из репозиториев Ubuntu/Debian (`apt update`, `apt install`). Так ставят nginx, docker.io (если из репо), большинство серверного софта в проде.
- **Snap** — изолированные пакеты от Canonical (автообновления, confinement). По умолчанию заметнее на **Desktop** (Firefox и др. в некоторых релизах); на **Server** часто не нужен, но отдельные snaps (например, `aws-cli`, `kubectl`) бывают удобны.
- **Где что:** системные демоны и классический DevOps-стек — обычно **apt**; десктоп-приложения и **Ubuntu Core** — ориентир на **Snap**. Не смешивать без необходимости одну и ту же роль (например, два способа установки одного сервиса) на одном хосте.

См. также: [RHEL / Alma / Rocky](#rhel), [Virtualization](#virtualization).

<a id="rhel"></a>

# Red Hat Enterprise Linux

Большое семейство дистрибутивов для Enterprise: стабильность, сертификации, долгий жизненный цикл. В отличие от [Ubuntu](#ubuntu), RHEL и типичные форки — почти всегда серверные headless-инсталляции.

<a id="rhel-subscription"></a>

## Подписка: subscription-manager и RHSM

**RHEL** распространяется по **подписке** (Red Hat Subscription Management, **RHSM**). Плата не «за ISO», а за право обновлений, патчей безопасности, поддержки и доступа к официальным репозиториям на зарегистрированных системах.

- `subscription-manager register` — привязка хоста к аккаунту Red Hat (часто через activation key в Ansible/Terraform/cloud-init).
- `subscription-manager attach --auto` — подключить подходящий subscription pool.
- `subscription-manager repos --list` / `--enable` — какие репозитории доступны (BaseOS, AppStream и др.).
- **AlmaLinux / Rocky** — бесплатные **ABI-совместимые форки** без RHSM: обновления из своих зеркал, без `subscription-manager`.

<a id="rhel-clones"></a>

## Основные дистрибутивы семейства (клоны и форки)

- **CentOS (устарело для «клон RHEL»):** классический CentOS Linux снят; **CentOS Stream** — rolling upstream перед RHEL, не замена стабильного «бинарного клона» для консервативного прода.
- **AlmaLinux / Rocky Linux:** актуальные замены классическому CentOS; цель — совместимость пакетов/поведения с RHEL без подписки Red Hat.

<a id="amazon-linux"></a>

## Amazon Linux (специфика AWS)

Оптимизированный дистрибутив Amazon для EC2.

- **Версии:** Amazon Linux 2 (AL2, legacy) и **Amazon Linux 2023** (AL2023).
- **Связь с RHEL:** rpm/dnf как в Red Hat-мире, но AL2023 **не** 1:1 клон конкретного RHEL N — линия ближе к Fedora/собственному стеку Amazon.
- **Применение:** AMI в AWS, агенты SSM, cloud-init, предсказуемая интеграция с IAM; удобен для Terraform/ASG.

<a id="dnf-rhel"></a>

## Пакетный менеджер: dnf (и yum)

Формат: **.rpm** (на Ubuntu — .deb через [apt](#apt-snap)).

- **Базовые команды:** `sudo dnf install nginx`, `sudo dnf update`, `sudo dnf remove пакет`.
- **Поиск и «какой пакет даёт файл»:**
  - `dnf search nginx` — поиск по имени/описанию в включённых репозиториях.
  - `dnf provides /usr/sbin/nginx` — какой RPM установит данный путь (аналог `apt-file search` / `dpkg -S`).
  - `rpm -qa | grep nginx` — список **уже установленных** пакетов (фильтр через grep).
- **EPEL** — Extra Packages for Enterprise Linux: софт вне базовых репо RHEL. Подключить EPEL, затем `dnf install …`.

<a id="rhel-network"></a>

## Сеть: NetworkManager vs Netplan

- **RHEL / Alma / Rocky:** дефолт — **NetworkManager** (`nmcli`, конфиги в `/etc/NetworkManager/`). Каталог `/etc/sysconfig/network-scripts/` на RHEL 8/9 — legacy, не опора для новых установок.
- **Ubuntu Server:** [netplan](#server) → чаще systemd-networkd; **netplan на RHEL не используется**.

<a id="firewall-rhel"></a>

## Файрвол: firewalld vs ufw

| | **Ubuntu Server** | **RHEL / Alma / Rocky** |
|---|-------------------|-------------------------|
| Демон/утилита | **ufw** (обёртка над iptables/nftables) | **firewalld** + `firewall-cmd` |
| Примеры | `sudo ufw allow 22/tcp`, `sudo ufw enable` | `sudo firewall-cmd --permanent --add-service=http`, `sudo firewall-cmd --reload` |
| Зоны | проще, меньше понятий | зоны (`public`, `internal`), сервисы в XML |

На [Ubuntu Server](#server) чаще встречается **ufw**; в AWS-образах Ubuntu порты иногда открыты security group, а ufw выключен — проверять `ufw status`.

<a id="selinux"></a>

## Безопасность: SELinux

Главное повседневное отличие от Ubuntu в проде.

- **Ubuntu:** **AppArmor** — профили для отдельных приложений; на Server обычно меньше «сюрпризов», чем enforcing SELinux на RHEL.
- **RHEL:** **SELinux** (mandatory access control) в режиме **enforcing** по умолчанию.

**Диагностика:**

- `getenforce` — `Enforcing` / `Permissive` / `Disabled` (временно мягче: `setenforce 0`, не замена настройке контекстов).
- `ausearch -m avc -ts recent` или `/var/log/audit/audit.log` — кто и что заблокировал (нужен пакет `audit`).
- Если `chmod`/`chown` верны, а Nginx не читает файлы в `/var/www/myapp` — часто неверный **тип контекста**:
  - `sudo chcon -R -t httpd_sys_content_t /var/www/myapp`
  - `sudo restorecon -Rv /var/www/myapp` — восстановить контексты по политике.
- Долгосрочно: `semanage fcontext`, `setsebool`, а не постоянный permissive.

<a id="rhel-vs-ubuntu"></a>

## RHEL vs Ubuntu

| Фича / Компонент | Ubuntu Server | RHEL / AlmaLinux / Amazon Linux |
| :--- | :--- | :--- |
| **Пакеты** | .deb ([apt](#apt-snap)) | .rpm ([dnf](#dnf-rhel)) |
| **Сеть** | [netplan](#server) | [NetworkManager](#rhel-network) |
| **Файрвол** | [ufw](#server) | [firewalld](#firewall-rhel) |
| **MAC** | AppArmor | [SELinux](#selinux) |
| **Доп. репо** | PPA | EPEL (+ RHSM только на RHEL) |
| **Жизненный цикл** | LTS раз в 2 года, **5 лет** (+ до **10** с [Ubuntu Pro](#server)) | **~10 лет** на мажор (RHEL 8, 9, …) при подписке |
| **Контейнеры** | Docker / containerd распространены | **Podman** в экосистеме Red Hat по умолчанию; Docker часто ставят отдельно |

См. также: [Virtualization](#virtualization).

<a id="bash-scripting"></a>

# Bash scripting

**Когда что использовать:** [grep](#grep) — найти строки по шаблону; [sed](#sed) — потоковое редактирование (замена, удаление, выбор строк); [awk](#awk) — столбцы, числа, агрегации по полям.

<a id="grep"></a>

## grep
```
grep [флаги] 'шаблон' [имя_файла]
```

Шаблон лучше в одинарных кавычках `'...'`, чтобы shell не интерпретировал `$`, `` ` ``, `*`. Без файла grep читает stdin: `dmesg | grep -i error`.

### Полезные флаги
- -i — игнорировать регистр символов.
- -v — инвертировать поиск (вывести строки, которые не содержат шаблон).
- -r или -R — рекурсивный поиск по подпапкам (на GNU/Linux эквивалентны; удобно для исходного кода).
- -n — вывести номер строки, где найден результат.
- -c — вывести только количество совпавших строк (не вхождений внутри строки).
- -l — вывести только имена файлов, где найдено совпадение.
- -w — искать совпадение только как целое слово (чтобы не находить части других слов).
- -E — расширенные регулярные выражения (`+`, `?`, `|`, группы `{}`).
- -F — буквальный поиск без regex (удобно для IP, путей, спецсимволов).
- -A N / -B N / -C N — показать N строк контекста после / до / вокруг совпадения (удобно в логах).

### Основы регулярных выражений
- ^ — начало строки (например, ^start найдет строки, начинающиеся на start).
- $ — конец строки (например, end$ найдет строки, заканчивающиеся на end).
- . — любой одиночный символ.
- .* — любая последовательность символов (`*` в обычном режиме — квантификатор предыдущего символа; с `-E` синтаксис проще).

<a id="sed"></a>

## sed

```
sed [флаги] 'команда' имя_файла
```

### Главные флаги

- -i — изменить файл напрямую (без бэкапа; без флага sed только выводит на экран). Безопаснее: `sed -i.bak '...' file` — останется `file.bak`.
- -E или -r — расширенные регулярные выражения (ERE; на GNU sed оба варианта).
- -n — подавить автоматический вывод всех строк (обязателен с `p`, иначе каждая строка печатается дважды).

1. Замена текста (Команда s)

    - `sed 's/apple/orange/' file.txt` — заменить первое совпадение apple на orange в каждой строке.
    - `sed 's/apple/orange/g'` — заменить все совпадения apple на orange (глобально).
    - `sed 's/apple/orange/2'` — заменить только второе совпадение в строке.
    - `sed 's/apple/orange/I'` — заменить без учета регистра (GNU sed).
    - `sed -i 's/old/new/g' file.txt` — перезаписать файл с заменой.
    - `sed 's|/usr/local|/opt|g' file.txt` — другой разделитель в `s`, если в шаблоне есть `/`.
    - `sed '1,10s/old/new/g' file.txt` — замена только в строках с 1 по 10.
    - `sed -e 's/a/b/' -e '/^$/d' file.txt` — несколько команд подряд.

2. Удаление строк (Команда d)

    - `sed '3d' file.txt` — удалить 3-ю строку.
    - `sed '1,5d' file.txt` — удалить строки с 1 по 5.
    - `sed '$d' file.txt` — удалить последнюю строку.
    - `sed '/pattern/d' file.txt` — удалить все строки, содержащие pattern.
    - `sed '/^$/d' file.txt` — удалить все пустые строки.

3. Печать строк (Команда p)

    - `sed -n '5p' file.txt` — напечатать только 5-ю строку.
    - `sed -n '2,10p' file.txt` — напечатать строки с 2 по 10.
    - `sed -n '/pattern/p' file.txt` — напечатать только строки с pattern (аналог grep).

<a id="awk"></a>

## awk

```
awk '[условие] {действие}' имя_файла
```

### Переменные полей (столбцов)

По умолчанию поля разделяются любой последовательностью пробельных символов (пробел, таб); несколько подряд не дают пустых полей. Это отличается от `awk -F' '`, где один пробел — разделитель и пустые поля возможны.

- $0 — вся строка целиком.
- $1, $2, $3 — первое, второе, третье поле (столбец) строки.
- $NF — последнее поле строки (удобно, когда число столбцов меняется).

### Встроенные переменные

- FS — разделитель полей на входе (по умолчанию — пробельные символы).
- OFS — разделитель полей на выходе (по умолчанию один пробел).
- NR — текущий номер строки (порядковый номер записи).
- NF — общее количество полей в текущей строке.

### Флаги и параметры

- -F — задать свой разделитель полей (например, `-F':'` для `/etc/passwd` или `-F','` для CSV).
- -v имя=значение — передать переменную в скрипт: `awk -v threshold=100 '$3 > threshold' file.txt`.

### Примеры частых операций

1. Вывод конкретных столбцов (Печать)
    - `awk '{print $2}' file.txt` — только второй столбец.
    - `awk '{print $1, $3}' file.txt` — вывести первый и третий столбцы.
    - `awk -F':' '{print $1, $NF}' /etc/passwd` — использовать : как разделитель, вывести имя пользователя и его оболочку (последнее поле).
    - `awk '{print NR, $0}' file.txt` — пронумеровать и вывести все строки.
    - `awk 'BEGIN {OFS=","} {print $1,$2}' file.txt` — вывод полей через запятую.

2. Фильтрация и условия (Поиск)
    - `awk '/pattern/ {print $2}' file.txt` — найти строки с pattern и вывести их второй столбец.
    - `awk '$3 > 100' file.txt` — строки, где третье поле больше 100 (числовое сравнение, если поле выглядит как число; иначе — лексикографическое).
    - `awk '($3+0) > 100' file.txt` — принудительно числовое сравнение.
    - `awk 'NF == 4' file.txt` — вывести только те строки, которые состоят ровно из 4 столбцов.
    - `awk 'NR>=2 && NR<=5' file.txt` — вывести строки с 2 по 5 (аналог sed -n '2,5p').

3. Блоки BEGIN и END (Подсчет и математика)
    - `BEGIN` выполняется до чтения текста, `END` — после обработки всех строк.
    - `awk '{sum += $1} END {print sum}' file.txt` — посчитать сумму всех чисел в первом столбце.
    - `awk 'END {print NR}' file.txt` — количество прочитанных записей (обычно как `wc -l`; может отличаться, если в файле нет завершающего перевода строки).

<a id="virtualization"></a>

# Virtualization (KVM, QEMU) + Vagrant

**Когда что использовать:** [KVM/QEMU](#kvm-qemu) — аппаратно ускоренные локальные VM; [Vagrant](#vagrant) — декларативные одноразовые окружения для разработки и лаб (не замена Terraform для облака).

<a id="kvm-qemu"></a>

## Виртуализация: KVM и QEMU

На Linux **KVM** (модуль ядра) и **QEMU** (процесс в user-space) работают вместе: при включённых **Intel VT-x / AMD-V** производительность близка к нативной. Это не «чистый» гипервизор Type-1 вроде ESXi, а **гибрид** — KVM в ядре + QEMU с моделями устройств.

- **KVM** — доступ к аппаратной виртуализации CPU/RAM; гостевой код выполняется на физическом процессоре.
- **QEMU** — модели дисков, сети, видео, USB, PCI. С KVM **не эмулирует CPU** (ускорение `kvm` / `-enable-kvm` в libvirt); без KVM — медленный программный fallback.

### Проверка поддержки виртуализации на хосте

Перед настройкой: VT-x/AMD-V в BIOS/UEFI. Для **вложенной виртуализации** (KVM внутри VM, Docker с KVM) — отдельно включить nested virtualization в BIOS и у гипервизора; в [WSL](#wsl) — только WSL2 и доп. настройки.

```bash
# Флаги CPU (вывод > 0 — есть vmx/svm)
grep -Ec '(vmx|svm)' /proc/cpuinfo

# Ubuntu/Debian (пакет cpu-checker)
kvm-ok

# Модуль KVM загружен?
lsmod | grep kvm
```

На **RHEL/Alma** достаточно `grep`/`lsmod`; `kvm-ok` — утилита Ubuntu.

### Установка стека (Ubuntu Server / Desktop)

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
sudo usermod -aG libvirt $USER   # перелогиниться
sudo systemctl enable --now libvirtd
```

### Управление через libvirt (команды virsh)

**libvirt** — API, демон `libvirtd`, обёртка над KVM/QEMU (и Xen). Вместо длинных `qemu-system-x86_64 ...` — домены, сети, тома.

Основная CLI — `virsh`:

- `virsh list --all` — все VM и статус.
- `virsh start <vm_name>` / `virsh shutdown <vm_name>` — старт / ACPI shutdown.
- `virsh destroy <vm_name>` — жёсткое выключение.
- `virsh undefine <vm_name>` — удалить XML домена (диски отдельно).
- `virsh domiflist <vm_name>` — интерфейсы VM.
- `virsh console <vm_name>` — serial/virtio console (выход: `Ctrl+]`.
- `sudo virsh net-list --all` — сети libvirt; по умолчанию **virbr0** (NAT для гостей).
- `virt-manager` — GUI (опционально).

<a id="vagrant"></a>

## Vagrant

Инструмент для **локальных** воспроизводимых VM (HashiCorp). Удобен для лаб и «на моей машине работало», не для прод-деплоя в EC2.

### Основные концепты

- **Vagrantfile** — декларация VM (Ruby-DSL): box, сеть, провайдер, provision.
- **Boxes** — шаблоны ОС (кэш локально). Образы для облака часто собирают **Packer** → box или AMI.
- **Providers** — бэкенд: VirtualBox по умолчанию в туториалах; на Linux лучше **libvirt** (`vagrant-libvirt`).
- **Provisioners** — shell/Ansible/Chef после первого `up`.

### Базовые команды CLI

В каталоге с `Vagrantfile`:

- `vagrant up` — создать/запустить, provision при первом запуске.
- `vagrant ssh` — SSH без пароля (встроенные ключи).
- `vagrant halt` — корректный shutdown.
- `vagrant reload` — перезагрузка; **не все** изменения `Vagrantfile` (box, провайдер, сеть) — нужны `vagrant destroy` + `vagrant up`.
- `vagrant destroy` — удалить VM и диски.
- `vagrant status` — состояние машин в проекте.

### Пример минимального Vagrantfile (libvirt + shell-provision)

Требуется: `vagrant plugin install vagrant-libvirt`.

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2404"

  config.vm.network "forwarded_port", guest: 80, host: 8080
  # Для нескольких VM: private_network — изолированная сеть между гостями

  config.vm.provider :libvirt do |lv|
    lv.cpus = 2
    lv.memory = 2048
  end

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y nginx
  SHELL
end
```

### Важные нюансы на Linux

1. **vagrant-libvirt** — VM на родном KVM без VirtualBox: `vagrant plugin install vagrant-libvirt`.
2. **Локалка vs облако:** Vagrant — эксперименты (несколько VM, private network, балансировщик). Прод в AWS — **Terraform**, образы — **Packer**, bootstrap — **cloud-init** (см. [Cloud](#cloud), [Server](#server)).
3. **Связка:** Packer строит box/AMI → Vagrant поднимает из box → Terraform масштабирует инфраструктуру в облаке.

См. также: [System management](#system-management).

<a id="system-management"></a>

# System Management

Управление доступом, службами, планировщиком и логами — база администрирования и траблшутинга на [Ubuntu](#ubuntu) и [RHEL](#rhel).

<a id="permissions"></a>

## Управление правами: sudo, chmod, chown

Права: **u**ser, **g**roup, **o**thers × **r**ead (4), **w**rite (2), e**x**ecute (1). На RHEL после `chown` для веб-каталогов иногда нужен ещё [SELinux](#selinux) (`restorecon`), даже при верных `chmod`.

### sudo и visudo

- **sudo** — выполнить команду от root.
- **/etc/sudoers** — только **`sudo visudo`**, не править файл напрямую.
- **/etc/sudoers.d/** — drop-in (Ansible). Пример: `deploy ALL=(ALL) NOPASSWD: /bin/systemctl restart myapp`

### chmod

- `chmod +x script.sh` / `chmod u+x script.sh` — исполнение.
- `chmod 755 dir` — каталог; `chmod 644 file` — конфиг.
- `chmod -R` — рекурсивно; осторожно с лишним `+x` на файлах.

### chown

- `chown nginx:nginx /var/www/html` — владелец и группа.
- `chown -R app:app /opt/app` — рекурсивно.

<a id="systemd"></a>

## Управление службами: systemd

**systemd** — PID 1: службы, mount, target, сокеты, таймеры. Юниты — `.service`, `.timer`, `.mount` и др.

- **/etc/systemd/system/** — кастомные unit и override (`systemctl edit`).
- **/usr/lib/systemd/system/** (раньше **/lib/systemd/system/**) — юниты из пакетов; не править вручную.

### systemctl

- `systemctl status nginx` — статус + хвост лога.
- `systemctl start` / `stop` / `restart nginx` — управление процессом.
- `systemctl reload nginx` — перечитать конфиг без полного рестарта (если unit поддерживает).
- `systemctl enable` / `disable nginx` — автозапуск при boot.
- `systemctl is-active nginx` / `is-enabled nginx` — для скриптов и проверок.
- `systemctl list-units --failed` — упавшие юниты после boot.
- `systemctl daemon-reload` — **обязательно** после изменения unit-файлов на диске.

<a id="journald"></a>

## Логирование: systemd-journald

**journald** — бинарный журнал ядра, systemd и сервисов. Лимиты диска: `/etc/systemd/journald.conf` (`SystemMaxUse`, `MaxRetentionSec`).

- `journalctl -u nginx` — логи unit.
- `journalctl -f` — follow (как `tail -f`).
- `journalctl -b` — текущая загрузка; `-b -1` — предыдущая.
- `journalctl -e` / `-xe` — конец лога / расширенный вывод при падении сервиса.
- `journalctl -p err..emerg` — только ошибки и выше.
- `journalctl --since "1 hour ago"` — окно по времени.
- `journalctl --disk-usage` / `--vacuum-time=7d` — место на диске и очистка.

Текстовые файлы в `/var/log/*.log` — отдельно через [logrotate](#logrotate).

<a id="cron"></a>

## Планировщик: cron и systemd timers

### cron

- `crontab -e` / `crontab -l` — таблица текущего пользователя.
- `sudo crontab -u deploy -e` — crontab другого пользователя.
- **/etc/crontab** — системные задачи (с полем пользователя).
- **/etc/cron.d/** — drop-in от пакетов.
- Указывать **полные пути**; при необходимости `PATH=` в crontab.

```text
# мин  час  день_мес  месяц  день_нед (0 и 7 = воскресенье)
0 3 * * * /opt/scripts/backup.sh
```

### Cron vs systemd timers

| | **cron** | **systemd timer** |
|---|----------|-------------------|
| Конфиг | crontab, `/etc/cron.d/` | `.timer` + `.service` |
| Логи | почта root / файл | [journald](#journald) |
| Плюсы | просто | `OnCalendar`, `Persistent=`, `systemctl list-timers` |

<a id="logrotate"></a>

## Ротация логов: logrotate

Ротация файлов в `/var/log/` (не путать с бинарным **journald**). Запуск по cron или systemd timer.

- **/etc/logrotate.conf** — глобальные правила.
- **/etc/logrotate.d/** — per-service (nginx, apt, syslog).

**Пример `/etc/logrotate.d/myapp`:**

```text
/var/log/myapp/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 app app
    postrotate
        systemctl reload myapp >/dev/null 2>&1 || true
    endscript
}
```

- **postrotate / endscript** — reload/HUP, чтобы демон переоткрыл лог.
- **copytruncate** — отдельная опция, если демон не умеет reopen (вместо `postrotate`, не вместе с ним).

**Проверка:** `sudo logrotate -d /etc/logrotate.d/myapp` (dry-run); `sudo logrotate -f …` — принудительно.
